require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'

NAME = "fiveruns_tuneup_core"
AUTHOR = "FiveRuns Development Team"
EMAIL = "dev@fiveruns.com"
HOMEPAGE = "http://tuneup.fiveruns.com/"
SUMMARY = "Core utilities for FiveRuns TuneUp panels"
GEM_VERSION = "0.5.3"

spec = Gem::Specification.new do |s|
  s.rubyforge_project = 'fiveruns'
  s.name = NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = %w(README.rdoc CHANGELOG)
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.add_dependency('json_pure')
  s.require_path = 'lib'
  s.files = %w(README.rdoc Rakefile CHANGELOG) + FileList["{lib,test}/**/*"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

Rake::TestTask.new do |t|
  t.verbose = true
  t.test_files = FileList['test/*_test.rb']
end

task :default => :test

sudo = RUBY_PLATFORM[/win/] ? '' : 'sudo '

desc "Install as a gem"
task :install => [:package] do
  sh %{#{sudo}gem install pkg/#{NAME}-#{GEM_VERSION} --no-update-sources}
end

namespace :jruby do

  desc "Run :package and install the resulting .gem with jruby"
  task :install => :package do
    sh %{#{sudo}jruby -S gem install #{install_home} pkg/#{NAME}-#{GEM_VERSION}.gem --no-rdoc --no-ri}
  end
  
end

