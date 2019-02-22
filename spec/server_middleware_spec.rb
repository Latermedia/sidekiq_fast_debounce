# frozen_string_literal: true

RSpec.describe Middleware::Sidekiq::Server::FastDebounce do
  describe 'middleware' do
    describe 'server' do
      it 'should not debounce anything via perform_async' do
        SfdWorker.perform_async('abc123')
        SfdWorker.perform_async('abc123')

        expect(SfdWorker.jobs.size).to eq(2)
        expect(SfdWorker).to receive(:trigger).twice
        Sidekiq::Worker.drain_all
      end

      it 'should only perform once - single arg' do
        SfdWorker.perform_debounce(10, 'abc123')
        SfdWorker.perform_debounce(10, 'abc123')
        SfdWorker.perform_debounce(10, 'abc123')
        jid = SfdWorker.perform_debounce(10, 'abc123')

        expect(SfdWorker.jobs.size).to eq(4)
        expect(SfdWorker).to receive(:trigger).once
        expect_any_instance_of(Redis).to receive(:del).with('debounce::SfdWorker::abc123').once
        Sidekiq::Worker.drain_all
      end

      it 'should only perform once - multiarg' do
        SfdWorker2.perform_debounce(10, 'abc123', 'stuff')
        SfdWorker2.perform_debounce(10, 'abc123', 'stuff')
        SfdWorker2.perform_debounce(10, 'abc123', 'stuff')
        jid = SfdWorker2.perform_debounce(10, 'abc123', 'stuff')

        expect(SfdWorker2.jobs.size).to eq(4)
        expect(SfdWorker2).to receive(:trigger).once
        Sidekiq::Worker.drain_all
      end
    end
  end
end
