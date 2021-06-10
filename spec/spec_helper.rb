# frozen_string_literal: true

require 'bundler/setup'
require 'fakeredis'
require 'sidekiq_fast_debounce'

require 'sidekiq/testing'

SidekiqFastDebounce.add_middleware

def sidekiq_job(klass, args)
  {
    'class' => klass,
    'jid' => SecureRandom.hex(12),
    'args' => args,
    'created_at' => Time.now.to_i,
    'enqueued_at' => Time.now.to_i
  }
end

class SfdWorker
  include Sidekiq::Worker

  def self.trigger(arg1); end

  def perform(arg1)
    self.class.trigger(arg1)
  end
end

class SfdWorker2
  include Sidekiq::Worker

  def self.trigger(arg1, arg2); end

  def perform(arg1, arg2)
    self.class.trigger(arg1, arg2)
  end
end

class SfdWorker3
  include Sidekiq::Worker

  def self.trigger(arg1); end

  def perform(arg1)
    self.class.trigger(arg1)
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Sidekiq::Worker.clear_all
    Sidekiq::Queues.clear_all

    Redis::Connection::Memory.reset_all_databases
    Redis::Connection::Memory.reset_all_channels
  end
end
