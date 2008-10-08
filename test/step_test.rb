require 'test/unit'

require 'rubygems'
require 'shoulda'

require File.dirname(__FILE__) << "/../lib/fiveruns_tuneup_core"

class StepTest < Test::Unit::TestCase
  
  context "loading from JSON" do
    setup do
      @json = read_json(:a)
      @root = Fiveruns::Tuneup::Step.load(@json)
    end
    should "create a RootStep" do
      assert_kind_of Fiveruns::Tuneup::RootStep, @root
      assert_equal JSON.load(@json)['children'].size, @root.children.size
    end
    should "have normal children" do
      @root.children.each do |child|
        assert_normal_node(child)
        assert_valid_extras(child)
      end
    end
  end
  
  def assert_normal_node(node)
    assert node.is_a?(Fiveruns::Tuneup::Step)
    node.children.each do |child|
      assert_normal_node(child)
    end
  end
  
  def assert_valid_extras(node)
    node.extras.each do |key, extra|
      assert_kind_of String, key
      assert_kind_of Fiveruns::Tuneup::Step::Extra, extra
    end
  end
  
  def read_json(name)
    File.read(File.dirname(__FILE__) << "/fixtures/#{name}.json")
  end
    
  
end