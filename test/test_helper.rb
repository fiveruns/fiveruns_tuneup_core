require 'test/unit'

require 'rubygems'
require 'shoulda'

require File.dirname(__FILE__) << "/../lib/fiveruns_tuneup_core"

class Test::Unit::TestCase
  
  private
  
  def read_json(name)
    File.read(File.dirname(__FILE__) << "/fixtures/#{name}.json")
  end
  
end