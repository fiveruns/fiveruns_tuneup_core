module Fiveruns
  module Tuneup
    
    class Run

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
      
      def self.slug_of(filename)
        url_directory, file = filename.split(File::SEPARATOR)[-2, 2]
        File.join(url_directory, File.basename(file, '.json.gz'))
      end
      
      def self.all(format = :slug)
        files = Dir[File.join(directory, '*', '*.json.gz')]
        format == :slug ? files.map { |file| slug_of(file) } : files
      end
      
      def self.all_for(url, format = :slug)
        run_directory = Digest::SHA1.hexdigest(url.to_s)
        files = Dir[File.join(directory, run_directory, '*.json.gz')]
        format == :slug ? files.map { |file| slug_of(file) } : files
      end
      
      def self.last(format = :slug)
        all(format).sort_by { |f| File.basename(f) }.last
      end
      
      def self.service_uri
        @service_uri = URI.parse(ENV['TUNEUP_COLLECTOR'] || 'https://tuneup-collector.fiveruns.com')
      end
            
      def self.share(slug)
        if api_key?
          file = Dir[File.join(directory, "%s.json.gz" % slug)].first
          if file
            run = load(File.open(file, 'rb') { |f| f.read })
            http = Net::HTTP.new(service_uri.host, service_uri.port)
            http.use_ssl = true if service_uri.scheme == 'https'
            body = "api_key=#{api_key}&run=#{CGI.escape(run.to_json)}"
            begin
              resp = http.post('/runs.json', body, "Content-Type" => 'application/x-www-form-urlencoded')
              case resp.code.to_i
              when 201
                return JSON.load(resp.body)['run_id']
              else
                # TODO: return error info
                return false
              end
            rescue Exception => e
              # TODO: return error info
              return false
            end
          else
            raise ArgumentError, "Invalid run: #{slug}"
          end
        else
          raise ArgumentError, "No API Key set"
        end
      end
      
      def self.api_key?
        @api_key
      end
      
      def self.load(compressed)
        file = JSON.load(Zlib::Inflate.inflate(compressed))
        step = Fiveruns::Tuneup::Step.load(file['data'])
        new(file['url'], step, file['environment'], Time.at(file['collected_at']))
      end
      
      attr_reader :url, :data, :environment, :collected_at
      def initialize(url, data, environment = self.class.environment, collected_at = Time.now)
        @url = url
        @data = data
        @environment = environment
        @collected_at = collected_at
        validate!
      end
      
      def validate!
        unless environment.is_a?(Hash)
          raise ArgumentError, "Invalid environment information (must be a Hash): #{environment.inspect}"
        end
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
          :url => url,
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