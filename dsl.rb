### Kick off the DSL
def test(name, &block)
  test = Test.new(&block)
  test.run
end



### Represents the actual test (series of "checks")
class Test
  def initialize(&block)
    @before_each_hooks = []
    @before_all_hooks = []
    
    @after_each_hooks = []
    @after_all_hooks = []
    
    @examples = []
    @variables = {}
    
    self.instance_eval(&block)
  end
  
  def let(var_name, &block)
    @variables[var_name.to_sym] = block
  end
  
  # Assume we're trying to get a let() variable
  def method_missing(method_name, *args, &block)
    @variables[method_name.to_sym].call
  end
  
  def run
    run_hooks :before, :all
    
    @examples.each do |example|
      run_hooks :before, :each
      
      example.test_block.call  
      
      run_hooks :after, :each
    end
    
    run_hooks :after, :all
  end
  
  def run_hooks(run_when, run_on)
    instance_variable_get("@#{run_when}_#{run_on}_hooks".to_sym).each do |hook|
      hook.call
    end
  end
  
  def add_hook(run_when, run_on, block)
    instance_variable_get("@#{run_when}_#{run_on}_hooks".to_sym) << block
  end
  
  def before(run_on = :each, &block)
    add_hook :before, (run_on == :all) ? :all : :each, block
  end
  
  def after(run_on = :each, &block)
    add_hook :after, (run_on == :all) ? :all : :each, block
  end
  
  def ensure_that(test_name, &block)
    @examples << Example.new(test_name, &block)
  end
end

# Yep, stole the name from RSpec
class Example
  attr_accessor :name, :test_block
  
  def initialize(name, &block)
    @name, @test_block = name, block
  end
end


### OK, let's try this out  (just run "ruby dsl.rb")
test "Event" do
  let(:block_name) { "Obama!" }
  
  before :all do
    puts "In a before ALL block! we have: #{block_name}"
  end
  
  before :each do
    puts "In a before each block now!"
  end
  
  ensure_that "something does something else" do
    puts "We're in the test now"
  end
  
  ensure_that "something does NOT do something else" do
    puts "We're in the second test now"
  end
  
  after :all do
    puts "In an after ALL block!"
  end
end

