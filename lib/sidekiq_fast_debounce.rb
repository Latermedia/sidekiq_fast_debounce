# frozen_string_literal: true

require 'sidekiq'

require_relative './sidekiq_fast_debounce/version'
require_relative './sidekiq_fast_debounce/config'
require_relative './sidekiq_fast_debounce/middleware/client'
require_relative './sidekiq_fast_debounce/middleware/server'

# Provides API for configuring and using SidekiqFastDebounce
module SidekiqFastDebounce
  class Error < StandardError; end

  class << self
    def included(base)
      base.extend(ClassMethods)
    end

    # Current SidekiqFastDebounce configuration
    # @return [SidekiqFastDebounce::Config]
    def config
      return @config if defined? @config

      @config = SidekiqFastDebounce::Config.new
    end

    # Block style configuration
    def configure
      yield config
    end

    # Reset current SidekiqFastDebounce configuration
    # @return [SidekiqFastDebounce::Config]
    def reset_config
      @config = SidekiqFastDebounce::Config.new
    end

    # Register the client and server middleware
    def add_middleware
      add_client_middleware
      add_server_middleware
    end

    # @private
    def add_client_middleware!(config)
      config.client_middleware do |chain|
        chain.add Middleware::Sidekiq::Client::FastDebounce
      end
    end

    # Register the client middleware
    def add_client_middleware
      ::Sidekiq.configure_client do |config|
        add_client_middleware!(config)
      end
    end

    # @private
    def add_server_middleware!(config)
      config.server_middleware do |chain|
        chain.add Middleware::Sidekiq::Server::FastDebounce
      end
    end

    # Register the server middleware
    def add_server_middleware
      ::Sidekiq.configure_server do |config|
        add_client_middleware!(config)
        add_server_middleware!(config)
      end

      # help with testing setup
      add_server_middleware!(Sidekiq::Testing) if ::Sidekiq.const_defined?('Testing') && ::Sidekiq::Testing.enabled?
    end
  end

  # Add perform_debounce to Sidekiq workers
  module ClassMethods
    # Debounce this jobs
    # @param delay [#to_f] how many seconds to delay to wait for other jobs
    # @param args [*Array]
    # @return [String] Sidekiq job id
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
