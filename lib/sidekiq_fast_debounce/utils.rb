# frozen_string_literal: true

module SidekiqFastDebounce
  # Utility methods for dealing with debounce options
  class Utils
    class << self
      # Get the options for debounced Sidekiq job
      # @param job [Hash] hash that represents a Sidekiq job
      # @return [String] key to use for this job
      def debounce_key(job)
        raise ArgumentError, 'No way to determine debounce key' if job['args'].empty?

        return job['args'].first if job['args'].length == 1

        Digest::MD5.hexdigest(job['args'].to_json)
      end
    end
  end
end
