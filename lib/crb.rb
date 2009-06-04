
require 'cucumber'
require 'cucumber/formatter/unicode'
require 'irb'

class CRB < Cucumber::Cli::Main
  extend IRB
end
CRB.step_mother = self

class CRB
  class << self
    attr_accessor :irb

    def world
      unless @world
        @world = CRB.step_mother
        def @world.to_s
          "World"
        end
      end
      @world
    end

    def start(args)
      IRB.setup(__FILE__)
      IRB.conf[:CONTEXT_MODE] = 0
      ws  = WorkSpace.new(world)
      CRB.irb = Irb.new(ws)
      IRB.module_eval do
        @CONF[:MAIN_CONTEXT] = CRB.irb.context
      end

      step_mother.World do
        world
      end

      execute(args)
      step_mother.send(:new_world!)

      alias_adverbs
      enable_session

      trap("SIGINT") do
        irb.signal_handle
      end

      around_hooks do
        catch(:IRB_EXIT) do
          irb.eval_input
        end
      end
    end

    def around_hooks(&block)
      step_mother.hooks[:before].each do |hook|
        hook.execute(world)
      end

      block.call

      step_mother.hooks[:after].each do |hook|
        hook.execute(world)
      end
    end

    def alias_adverbs
      world.instance_eval do
        hash = Cucumber.keyword_hash
        keywords = %w{given when then and but}.map{|keyword| hash[keyword].split('|')}.flatten
        keywords.each do |name|
          instance_eval "alias :'#{name}' :__cucumber_invoke"
        end
      end
    end

    def enable_session(mode = nil)
      require 'webrat'
      require 'webrat/core/matchers'

      world.instance_eval do
        extend ::Webrat::Methods 
        extend ::Webrat::Matchers

        if mode || !Webrat.configure.mode
          Webrat.configure.mode = (mode || :mechanize)
          if Webrat.configure.mode == :mechanize
            webrat_session.mechanize.user_agent_alias = 'Windows Mozilla'
          end
        end

        %w{response post}.each do |m|
          unless respond_to?(m, true)
            instance_eval <<-EOF
              def #{m}(*args, &blk)
                webrat.#{m}(*args, &blk)
              end
            EOF
          end
        end

      end
    end
  end

  def execute!(step_mother)
    configuration.load_language
    step_mother.options = configuration.options

    require_files
    enable_diffing

    features = load_plain_text_features

    visitor = configuration.build_formatter_broadcaster(step_mother)
    step_mother.visitor = visitor # Needed to support World#announce
  end

  module ExecuteProc
    def execute(world)
      world.instance_eval(&@proc)
    end
  end

end

CRB.step_mother = self

Cucumber::StepMother::Hook.class_eval do
  include CRB::ExecuteProc
end

