require File.dirname(__FILE__) << "/test_helper"

class RunTest < Test::Unit::TestCase

  context "Persistence" do

    setup do
      @directory = File.expand_path(File.dirname(__FILE__) << "/tmp")
      FileUtils.rm_rf @directory rescue nil
      FileUtils.mkdir_p @directory
      Fiveruns::Tuneup::Run.directory = @directory
      @json = read_json :a
      @root = Fiveruns::Tuneup::Step.load(@json)
    end

    def teardown
      FileUtils.rm_rf @directory rescue nil
    end
    
    context "using Run#save" do
      setup do
        setup_run
      end
      should "write to filesystem" do
        assert_nothing_raised do
          @run.save
        end
        assert_equal 1, Dir[File.join(@directory, '*')].size
      end
    end
    
    context "loading" do
      setup do
        setup_run.save        
      end
      should "create Run instances" do
        assert_equal 1, Fiveruns::Tuneup::Run.all_for(@run.url).size
        Fiveruns::Tuneup::Run.all_for(@run.url, :filename).each do |file|
          data = File.open(file, 'rb') { |f| f.read }
          assert_kind_of Fiveruns::Tuneup::Run, Fiveruns::Tuneup::Run.load(data)
        end
      end
    end

  end
  
  private
  
  def setup_run
    @timestamp = 1223597107.58871
    @run = Fiveruns::Tuneup::Run.new(
      'http://localhost:3000',
      @root,
      Fiveruns::Tuneup::Run.environment,
      Time.at(@timestamp)
    )
  end

end