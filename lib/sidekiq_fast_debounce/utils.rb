# frozen_string_literal: true

module SidekiqFastDebounce
  # Utility methods for dealing with debounce options
  class Utils
    class << self
      # Turn a string into a class
      # @param klass [String, Class]
      # @return [Class]
      def const(klass)
        if klass.is_a?(Class)
          klass
        elsif klass.is_a?(String)
          klass.split('::').reduce(Module, :const_get)
        else
          raise ArgumentError, "klass should be String or Class, it is `#{klass.class}`"
        end
      end

      # Extract the give key, with indifferent access, from args. Deletes it from args.
      # @param key [Symbol] key to extract
      # @param args [Hash] last arg from Sidekiq, if
      # @return [Hash]
      def extract_opt!(key, args)
        opt = {}

        key_s = key.to_s
        key_sym = key.to_sym

        if args.key?(key_s)
          opt[:value] = args.delete(key_s)
        elsif args.key?(key_sym)
          opt[:value] = args.delete(key_sym)
        end

        opt
      end

      # Get the options for debounced Sidekiq job
      # @param job [Hash] hash that represents a Sidekiq job
      # @return [Hash] debounce specific options
      def debounce_opts(job)
        args = job['args']
        num_args = args.length

        opts = {}

        if args.last.is_a?(Hash)
          arg_opts = args.last

          found_debounce_opt = false

          key_opts = extract_opt!(:debounce_key, arg_opts)
          if key_opts.key?(:value)
            found_debounce_opt = true
            opts[:debounce_key] = key_opts[:value]
          end

          namespace_opts = extract_opt!(:debounce_namespace, arg_opts)
          if namespace_opts.key?(:value)
            found_debounce_opt = true
            opts[:debounce_namespace] = namespace_opts[:value]
          end

          if found_debounce_opt
            if arg_opts.empty?
              args.pop
            else
              args[num_args - 1] = arg_opts
            end
          end
        end

        opts
      end

      # Get the options for debounced Sidekiq job
      # @param klass [Class] Sidekiq worker class
      # @param job [Hash] hash that represents a Sidekiq job
      # @param deb_opts [Hash] debounce specific options
      # @return [String] namespace to use for this job's debounce key
      def debounce_namespace(klass, _job, deb_opts = {})
        return deb_opts[:debounce_namespace] if deb_opts.key?(:debounce_namespace)

        klass.to_s
      end

      # Get the options for debounced Sidekiq job
      # @param klass [Class] Sidekiq worker class
      # @param job [Hash] hash that represents a Sidekiq job
      # @param deb_opts [Hash] debounce specific options
      # @return [String] key to use for this job
      def debounce_key(_klass, job, deb_opts = {})
        return deb_opts[:debounce_key] if deb_opts.key?(:debounce_key)
        raise ArgumentError, 'No way to determine debounce key' if job['args'].empty?

        if job['args'].length == 1
          job['args'].first
        else
          Digest::MD5.hexdigest(job['args'].to_json)
        end
      end
    end
  end
end
