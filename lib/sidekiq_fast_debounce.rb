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
      at = Time.now.to_f + delay.to_f
      set('debounce' => delay.to_f).perform_at(at, *args)
    end
  end

  # Add perform_debounce to Sidekiq::Worker::Setter to enable set(..).perform_debounce(...)
  # @see https://github.com/mperham/sidekiq/blob/master/lib/sidekiq/worker.rb
  module Setter
    def perform_debounce(delay, *args)
      # @klass and @opts are an instance variables on Sidekiq::Worker::Setter
      item = {
        'class' => @klass,
        'args' => args,
        'at' => Time.now.to_f + delay.to_f,
        'debounce' => delay.to_f
      }

      @klass.client_push(@opts.merge(item))
    end
  end
end

::Sidekiq::Worker::ClassMethods.prepend(SidekiqFastDebounce::ClassMethods)
::Sidekiq::Worker::Setter.prepend(SidekiqFastDebounce::Setter)
