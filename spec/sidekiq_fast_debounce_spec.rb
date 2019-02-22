# frozen_string_literal: true

RSpec.describe SidekiqFastDebounce do
  it 'has a version number' do
    expect(SidekiqFastDebounce::VERSION).not_to be nil
  end

  describe 'registering middleware' do
    def client_middleware
      ::Sidekiq.client_middleware.entries.collect(&:klass)
    end

    def server_middleware
      ::Sidekiq.server_middleware.entries.collect(&:klass)
    end

    def unload_middleware
      ::Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          chain.remove Middleware::Sidekiq::Client::FastDebounce
        end
      end

      ::Sidekiq.configure_server do |config|
        config.client_middleware do |chain|
          chain.remove Middleware::Sidekiq::Client::FastDebounce
        end
        config.server_middleware do |chain|
          chain.remove Middleware::Sidekiq::Server::FastDebounce
        end
      end
    end

    before(:each) do
      unload_middleware
    end

    after(:each) do
      SidekiqFastDebounce.add_middleware
    end

    it 'adds server middleware - hack' do
      server_klass = Middleware::Sidekiq::Server::FastDebounce

      expect(server_middleware.include?(server_klass)).to eq(false)
      # hacking around the fact that tests execute on the sidekiq client side
      ::Sidekiq.configure_client do |config|
        SidekiqFastDebounce.add_server_middleware!(config)
      end

      expect(server_middleware.include?(server_klass)).to eq(true)
    end

    it 'adds client middleware' do
      client_klass = Middleware::Sidekiq::Client::FastDebounce

      expect(client_middleware.include?(client_klass)).to eq(false)
      SidekiqFastDebounce.add_client_middleware

      expect(client_middleware.include?(client_klass)).to eq(true)
    end
  end

  describe 'perform_debounce' do
    it 'should call client_push' do
      t = Time.now
      allow(Time).to receive(:now).and_return(t)

      expect(SfdWorker).to receive(:client_push).with(
        'class' => SfdWorker,
        'args' => ['abc123'],
        'at' => (t.to_f + 3.to_f),
        'debounce' => 3.to_f
      )

      SfdWorker.perform_debounce(3, 'abc123')
    end
  end
end
