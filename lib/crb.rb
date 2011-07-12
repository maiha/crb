require 'cucumber'
require 'cucumber/formatter/unicode'
require 'cucumber/runtime'
require 'cucumber/rb_support/rb_dsl'
require 'irb'

module CRB
  module World
    include Cucumber::RbSupport::RbDsl

    attr_accessor :support
    attr_accessor :rb

    def to_s
      "CRB:%s" % (steps.size rescue '???')
    end

    def steps
      support.step_definitions
    end

    def hooks
      rb.send(:hooks)
    end

    def before
      fire_hook(:before)
    end

    def after
      fire_hook(:after)
    end

    private
      def Given(name, &block)
        if block
          step = super(name, &block)
          "%s is defined" % (step.regexp_source rescue 'A new step')
        else
          @crb_before_executed ||= (before; true)
          support.step_match(name).invoke(nil)
        end
      rescue Cucumber::Undefined => e
        puts e.to_s
        e
      end

      def fire_hook(key)
        count = 0
        hooks[key].each do |hook|
          block = hook.instance_variable_get('@proc')
          if block
            instance_eval(&block)
            count += 1
          else
            # cuke is newer than 1.0
          end
        end
        "%d %s hooks executed" % [count, key]
      end
  end

  class Console < Cucumber::Cli::Main
    include IRB

    def support
      @support ||= Cucumber::Runtime::SupportCode.new(configuration)
    end

    def rb
      @rb ||= support.load_programming_language('rb')
    end

    def world
      @world ||= (
        stub = Struct.new(:language).new # stub scenario
        rb.begin_rb_scenario(stub)
        world = rb.current_world
        world.extend(CRB::World)
        world.support = support
        world.rb = rb
        world.instance_eval do
          Gherkin::I18n.code_keywords.each do |adverb|
            next if adverb.to_s == "Given"
            alias :"#{adverb}" :Given
          end
        end
        world
      )
    end

    def load_step_definitions
      files = configuration.support_to_load + configuration.step_defs_to_load
      support.load_files!(files)
    end

    def execute!
      load_step_definitions
      IRB.setup(__FILE__)
      IRB.conf[:CONTEXT_MODE] = 0
      irb = Irb.new(WorkSpace.new(world))
      IRB.module_eval do
        @CONF[:MAIN_CONTEXT] = irb.context
      end

      trap("SIGINT") {
        world.before 
        irb.signal_handle
      }
      catch(:IRB_EXIT) do
        irb.eval_input
      end
    end
  end
end


