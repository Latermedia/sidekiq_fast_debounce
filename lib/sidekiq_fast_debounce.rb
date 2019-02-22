# frozen_string_literal: true

require 'sidekiq'

require_relative './sidekiq_fast_debounce/version'
require_relative './sidekiq_fast_debounce/config'
require_relative './sidekiq_fast_debounce/middleware/client'
require_relative './sidekiq_fast_debounce/middleware/server'

module SidekiqFastDebounce
  class Error < StandardError; end

  class << self
    def included(base)
      base.extend(ClassMethods)
    end

    def config
      return @config if defined? @config

      @config = SidekiqFastDebounce::Config.new
    end

    def configure
      yield config
    end

    def reset_config
      @config = SidekiqFastDebounce::Config.new
    end

    def add_middleware
      add_client_middleware
      add_server_middleware
    end

    def add_client_middleware!(config)
      config.client_middleware do |chain|
        chain.add Middleware::Sidekiq::Client::FastDebounce
      end
    end

    def add_client_middleware
      ::Sidekiq.configure_client do |config|
        add_client_middleware!(config)
      end
    end

    def add_server_middleware!(config)
      config.server_middleware do |chain|
        chain.add Middleware::Sidekiq::Server::FastDebounce
      end
    end

    def add_server_middleware
      ::Sidekiq.configure_server do |config|
        add_client_middleware!(config)
        add_server_middleware!(config)
      end

      # help with testing setup
      if ::Sidekiq.const_defined?('Testing') && ::Sidekiq::Testing.enabled?
        add_server_middleware!(Sidekiq::Testing)
      end
    end
  end

  module ClassMethods
    def perform_debounce(delay, *args)
      item = {
        'class' => self,
        'args' => args,
        'at' => Time.now.to_f + delay.to_f,
        'debounce' => delay.to_f
      }

      client_push(item)
    end
  end
end
