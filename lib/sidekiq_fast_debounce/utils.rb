# frozen_string_literal: true

module SidekiqFastDebounce
  # Utility methods for dealing with debounce options
  class Utils
    class << self
      # Get the options for debounced Sidekiq job
      # @param job [Hash] hash that represents a Sidekiq job
      # @return [String] key to use for this job
      def debounce_key(job)
        namespace = job[:debounce_namespace] || job['debounce_namespace']
        namespace ||= job['class'].to_s

        "debounce::#{namespace}::#{base_key(job)}"
      end

      # Get the options for debounced Sidekiq job
      # @param job [Hash] hash that represents a Sidekiq job
      # @return [String] key to use for this job
      def base_key(job)
        key = job[:debounce_key] || job['debounce_key']
        return key unless key.nil?

        if job['args'].empty?
          'DEBOUNCE_NO_ARGS'
        elsif job['args'].length == 1
          job['args'].first
        else
          Digest::MD5.hexdigest(job['args'].to_json)
        end
      end
    end
  end
end
