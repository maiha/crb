require 'cucumber'
require 'cucumber/formatter/unicode'
require 'cucumber/runtime'
require 'cucumber/rb_support/rb_dsl'
require 'irb'

module CRB
  class Runtime < Cucumber::Runtime
    def run!
      load_step_definitions
      fire_after_configuration_hook
    end

    def step_definitions
      @support_code.step_definitions
    end
  end

  module World
    include Cucumber::RbSupport::RbDsl

    attr_accessor :runtime
    attr_accessor :rb

    def to_s
      "CRB:%s" % (steps.size rescue '???')
    end

    def steps
      runtime.step_definitions
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
          runtime.step_match(name).invoke(nil)
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

    def runtime
      @runtime ||= CRB::Runtime.new(configuration)
    end

    def rb
      @rb ||= runtime.load_programming_language('rb')
    end

    def world
      @world ||= (
        rb.send(:create_world)
        world = rb.current_world
        world.extend(CRB::World)
        world.runtime = runtime
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

    def execute!
      IRB.setup(__FILE__)
      IRB.conf[:CONTEXT_MODE] = 0
      irb = Irb.new(WorkSpace.new(world))
      runtime.run!
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


