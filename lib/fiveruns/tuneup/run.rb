require 'zlib'
require 'digest/sha1'
require 'fileutils'
require 'httparty'

module Fiveruns
  module Tuneup
    
    class Run
      include HTTParty
      base_uri ENV['TUNEUP_COLLECTOR'] || 'https://tuneup-collector.fiveruns.com'
      format :json
      
      class << self
        attr_accessor :directory
        attr_accessor :api_key
      end
      
      def self.environment
        @environment ||= {
          # :framework needs to be set, as well as <framework>_version
          :framework => nil, 
          :ruby_version => RUBY_VERSION,
          :ruby_platform => RUBY_PLATFORM
        }
      end
      
      def self.files_for(url)
        run_directory = Digest::SHA1.hexdigest(url.to_s)
        Dir[File.join(directory, run_directory, '*.json.gz')]
      end
      
      def self.share(slug)
        if api_key?
          file = Dir[File.join(directory, "%s.json.gz" % slug)].first
          if file
            run = load(File.open(file, 'rb') { |f| f.read })
            result = post '/runs.json', :body => {:api_key => api_key, :run => run.to_json}
            result['run_id']
          else
            raise ArgumentError, "Invalid run: #{slug}"
          end
        else
          raise ArgumentError, "No API Key set"
        end
      end
      
      def api_key?
        @api_key
      end
      
      def self.load(compressed)
        file = JSON.load(Zlib::Inflate.inflate(compressed))
        new(file['url'], file['data'], file['environment'], Time.at(file['collected_at']))
      end
      
      attr_reader :url, :data, :environment, :collected_at
      def initialize(url, data, environment = self.class.environment, collected_at = Time.now)
        @url = url
        @data = data
        @environment = environment,
        @collected_at = collected_at
      end
      
      def save
        compressed = Zlib::Deflate.deflate(to_json)
        create_directory
        File.open(full_path, 'wb') { |f| f.write compressed }
      end
      
      def full_path
        File.join(self.class.directory, path)
      end
      
      def slug
        @slug ||= "%s/%d-%d" % [
          Digest::SHA1.hexdigest(url),
          (collected_at.to_f * 1000),
          (data.time * 1000)
        ]
      end
      
      def path
        "%s.json.gz" % slug
      end
      
      def to_json
        {
          :id => slug,
          :environment => environment,
          :collected_at => collected_at.to_f,
          :data => data
        }.to_json
      end
      
      private
      
      def create_directory
        FileUtils.mkdir_p File.dirname(full_path)
      end
      
    end
    
  end
end