
require 'cucumber'
require 'cucumber/formatter/unicode'
require 'irb'

class CRB < Cucumber::Cli::Main
  extend IRB
  extend Cucumber::World

  class << self
    def world
      step_mother.current_world
    end

    def start(args)
      IRB.setup(__FILE__)
      ws  = WorkSpace.new(binding)
      irb = Irb.new(ws)
      IRB.module_eval do
        @CONF[:MAIN_CONTEXT] = irb.context
      end

      execute(args)
      step_mother.send(:new_world!)

      alias_adverbs
      enable_session

      trap("SIGINT") do
        irb.signal_handle
      end
    
      catch(:IRB_EXIT) do
        irb.eval_input
      end
    end

    def enable_session(mode = nil)
      require 'webrat'
      require 'webrat/core/matchers'

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
            def self.#{m}(*args, &blk)
              webrat.#{m}(*args, &blk)
            end
          EOF
        end
      end
    end

    def alias_adverbs
      hash = Cucumber.keyword_hash
      keywords = %w{given when then and but}.map{|keyword| hash[keyword].split('|')}.flatten
      keywords.each do |name|
        instance_eval <<-EOF
          def CRB.#{name}(*args, &blk)
            world.#{name}(*args, &blk)
          end
        EOF
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
end

CRB.step_mother = self
