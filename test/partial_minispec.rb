## This is code stolen from the definition file for Minitest::Spec. We really
# like everything about Minitest::Spec except for the expectations part, so we
# are stealing it and using it here. Shamelessly. 
#
# This code may go out of date in future versions of Ruby, so we should keep an
# eye on that. But that's better than reinventing the wheel.

module Kernel # :nodoc:
  ##
  # Describe a series of expectations for a given target +desc+.
  #
  # TODO: find good tutorial url.
  #
  # Defines a test class subclassing from either MiniTest::Spec or
  # from the surrounding describe's class. The surrounding class may
  # subclass MiniTest::Spec manually in order to easily share code:
  #
  #     class MySpec < MiniTest::Spec
  #       # ... shared code ...
  #     end
  #
  #     class TestStuff < MySpec
  #       it "does stuff" do
  #         # shared code available here
  #       end
  #       describe "inner stuff" do
  #         it "still does stuff" do
  #           # ...and here
  #         end
  #       end
  #     end

  def describe desc, additional_desc = nil, &block # :doc:
    stack = MiniTest::Spec.describe_stack
    name  = [stack.last, desc, additional_desc].compact.join("::")
    sclas = stack.last || if Class === self && self < MiniTest::Spec then
                            self
                          else
                            MiniTest::Spec.spec_type desc
                          end

    cls = sclas.create name, desc

    stack.push cls
    cls.class_eval(&block)
    stack.pop
    cls
  end
  private :describe
end

##
# MiniTest::Spec -- The faster, better, less-magical spec framework!
#
# For a list of expectations, see MiniTest::Expectations.

class MiniTest::Spec < MiniTest::Unit::TestCase
  ##
  # Contains pairs of matchers and Spec classes to be used to
  # calculate the superclass of a top-level describe. This allows for
  # automatically customizable spec types.
  #
  # See: register_spec_type and spec_type

  TYPES = [[//, MiniTest::Spec]]

  ##
  # Register a new type of spec that matches the spec's description.
  # This method can take either a Regexp and a spec class or a spec
  # class and a block that takes the description and returns true if
  # it matches.
  #
  # Eg:
  #
  #     register_spec_type(/Controller$/, MiniTest::Spec::Rails)
  #
  # or:
  #
  #     register_spec_type(MiniTest::Spec::RailsModel) do |desc|
  #       desc.superclass == ActiveRecord::Base
  #     end

  def self.register_spec_type(*args, &block)
    if block then
      matcher, klass = block, args.first
    else
      matcher, klass = *args
    end
    TYPES.unshift [matcher, klass]
  end

  ##
  # Figure out the spec class to use based on a spec's description. Eg:
  #
  #     spec_type("BlahController") # => MiniTest::Spec::Rails

  def self.spec_type desc
    TYPES.find { |matcher, klass|
      if matcher.respond_to? :call then
        matcher.call desc
      else
        matcher === desc.to_s
      end
    }.last
  end

  @@describe_stack = []
  def self.describe_stack # :nodoc:
    @@describe_stack
  end

  ##
  # Returns the children of this spec.

  def self.children
    @children ||= []
  end

  def self.nuke_test_methods! # :nodoc:
    self.public_instance_methods.grep(/^test_/).each do |name|
      self.send :undef_method, name
    end
  end

  ##
  # Define a 'before' action. Inherits the way normal methods should.
  #
  # NOTE: +type+ is ignored and is only there to make porting easier.
  #
  # Equivalent to MiniTest::Unit::TestCase#setup.

  def self.before type = :each, &block
    raise "unsupported before type: #{type}" unless type == :each

    add_setup_hook {|tc| tc.instance_eval(&block) }
  end

  ##
  # Define an 'after' action. Inherits the way normal methods should.
  #
  # NOTE: +type+ is ignored and is only there to make porting easier.
  #
  # Equivalent to MiniTest::Unit::TestCase#teardown.

  def self.after type = :each, &block
    raise "unsupported after type: #{type}" unless type == :each

    add_teardown_hook {|tc| tc.instance_eval(&block) }
  end

  ##
  # Define an expectation with name +desc+. Name gets morphed to a
  # proper test method name. For some freakish reason, people who
  # write specs don't like class inheritence, so this goes way out of
  # its way to make sure that expectations aren't inherited.
  #
  # This is also aliased to #specify and doesn't require a +desc+ arg.
  #
  # Hint: If you _do_ want inheritence, use minitest/unit. You can mix
  # and match between assertions and expectations as much as you want.

  def self.it desc = "anonymous", &block
    block ||= proc { skip "(no tests defined)" }

    @specs ||= 0
    @specs += 1

    name = "test_%04d_%s" % [ @specs, desc.gsub(/\W+/, '_').downcase ]

    define_method name, &block

    self.children.each do |mod|
      mod.send :undef_method, name if mod.public_method_defined? name
    end
  end

  ##
  # Essentially, define an accessor for +name+ with +block+.
  #
  # Why use let instead of def? I honestly don't know.

  def self.let name, &block
    define_method name do
      @_memoized ||= {}
      @_memoized.fetch(name) { |k| @_memoized[k] = instance_eval(&block) }
    end
  end

  ##
  # Another lazy man's accessor generator. Made even more lazy by
  # setting the name for you to +subject+.

  def self.subject &block
    let :subject, &block
  end

  def self.create name, desc # :nodoc:
    cls = Class.new(self) do
      @name = name
      @desc = desc

      nuke_test_methods!
    end

    children << cls

    cls
  end

  def self.to_s # :nodoc:
    defined?(@name) ? @name : super
  end

  # :stopdoc:
  def after_setup
    run_setup_hooks
  end

  def before_teardown
    run_teardown_hooks
  end

  class << self
    attr_reader :desc
    alias :specify :it
    alias :name :to_s
  end
  # :startdoc:
end
