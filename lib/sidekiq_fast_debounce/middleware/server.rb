# frozen_string_literal: true

require 'sidekiq'

module Middleware
  module Sidekiq
    module Server
      class FastDebounce
        # @param [Object] worker the worker instance
        # @param [Hash] job the full job payload
        #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
        # @param [String] queue the name of the queue the job was pulled from
        # @yield the next middleware in the chain or worker `perform` method
        # @return [Void]
        def call(_worker, job, _queue)
          debounce_key = job['debounce_key']

          unless debounce_key.nil?
            debounce_jid =
              ::Sidekiq.redis do |conn|
                conn.get(debounce_key)
              end

            # allow retries of the debounced job
            # a retry will get skipped if a new job with the same debounce
            # key has been enqueued
            check_debounce = !(job.key?('retry_count') && debounce_jid.blank?)

            return nil if check_debounce && job['jid'] != debounce_jid

            ::Sidekiq.redis do |conn|
              conn.del(debounce_key)
            end
          end

          yield

          true
        end
      end
    end
  end
end
