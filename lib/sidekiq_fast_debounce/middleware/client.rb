# frozen_string_literal: true

require 'sidekiq'
require_relative '../config'
require_relative '../utils'

module Middleware
  module Sidekiq
    module Client
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
        def call(worker_class, job, _queue, _redis_pool)
          # a `debounce` key signals this is a debounced job
          if job.key?('debounce')
            delay = job.delete('debounce')
            jid = job['jid']

            # extract any debounce options from the job args
            deb_opts = SidekiqFastDebounce::Utils.debounce_opts(job)

            worker_klass = SidekiqFastDebounce::Utils.const(worker_class)

            namespace = SidekiqFastDebounce::Utils.debounce_namespace(worker_klass, job, deb_opts)
            base_key = SidekiqFastDebounce::Utils.debounce_key(worker_klass, job, deb_opts)

            job['debounce_key'] = "debounce::#{namespace}::#{base_key}"

            ttl = delay + SidekiqFastDebounce.config.grace_ttl

            ::Sidekiq.redis do |conn|
              conn.setex(job['debounce_key'], ttl.to_i, jid)
            end
          end

          yield
        end
      end
    end
  end
end
