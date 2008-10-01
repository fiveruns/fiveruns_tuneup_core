require 'rubygems'
require 'echoe'

Echoe.new 'fiveruns_tuneup_core' do |p|
  p.version = '0.0.1'
  p.author = "FiveRuns Development Team"
  p.email  = 'dev@fiveruns.com'
  p.project = 'fiveruns'
  p.summary = "Common objects for the FiveRuns TuneUp service"
  p.url = "http://tuneup.fiveruns.com"
  p.include_rakefile = true
  p.runtime_dependencies = %w(json)
  p.development_dependencies = %w(FakeWeb Shoulda)
  p.rcov_options = '--exclude gems --exclude version.rb --sort coverage --text-summary --html -o coverage'
end

task :coverage do
  system "open coverage/index.html" if PLATFORM['darwin']
end
