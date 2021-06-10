# frozen_string_literal: true

require 'sidekiq'
require_relative '../config'
require_relative '../utils'

module Middleware
  module Sidekiq
    module Client
      # Sidekiq client middle to handle setting the debounce key for a debounced job
      class FastDebounce
        # @param [String, Class] worker_class the string or class of the worker class being enqueued
        # @param [Hash] job the full job payload
        #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
        # @param [String] queue the name of the queue the job was pulled from
        # @param [ConnectionPool] redis_pool the redis pool
        # @return [Hash, FalseClass, nil] if false or nil is returned,
        #   the job is not to be enqueued into redis, otherwise the block's
        #   return value is returned
        # @yield the next middleware in the chain or the enqueuing of the job
        def call(_worker_class, job, _queue, _redis_pool)
          # a `debounce` key signals this is a debounced job
          if job.key?('debounce')
            delay = job.delete('debounce')
            jid = job['jid']

            job['debounce_key'] = SidekiqFastDebounce::Utils.debounce_key(job)

            ttl = job[:debounce_ttl] || job['debounce_ttl']
            ttl ||= SidekiqFastDebounce.config.grace_ttl

            expires_in = delay + ttl.to_i

            ::Sidekiq.redis do |conn|
              conn.setex(job['debounce_key'], expires_in, jid)
            end
          end

          yield
        end
      end
    end
  end
end
