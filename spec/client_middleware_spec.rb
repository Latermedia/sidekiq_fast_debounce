# frozen_string_literal: true

RSpec.describe Middleware::Sidekiq::Client::FastDebounce do
  describe 'middleware' do
    describe 'client' do
      it 'should not debounce anything via perform_async' do
        expect(SidekiqFastDebounce::Utils).to_not receive(:debounce_opts)

        SfdWorker.perform_async('abc123')
      end

      it 'should debounce via perform_debounce' do
        expect(SidekiqFastDebounce::Utils).to receive(:debounce_opts).and_return({})

        SfdWorker.perform_debounce(3, 'abc123')
      end

      it 'should update debounce key one follow up calls to perform_debounce' do
        # not present yet
        ::Sidekiq.redis do |conn|
          expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
        end

        # set it to this job id
        jid1 = SfdWorker.perform_debounce(3, 'abc123')

        ::Sidekiq.redis do |conn|
          expect(conn.get('debounce::SfdWorker::abc123')).to eq(jid1)
        end

        # update key to new job id
        jid2 = SfdWorker.perform_debounce(3, 'abc123')

        ::Sidekiq.redis do |conn|
          expect(conn.get('debounce::SfdWorker::abc123')).to eq(jid2)
        end
      end

      it 'should use debounce_key override passed into perform_debounce' do
        # not present yet
        ::Sidekiq.redis do |conn|
          expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
          expect(conn.get('debounce::SfdWorker::stuff')).to eq(nil)
        end

        # set it to this job id
        jid1 = SfdWorker.perform_debounce(3, 'abc123', { debounce_key: 'stuff' })

        ::Sidekiq.redis do |conn|
          expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
          expect(conn.get('debounce::SfdWorker::stuff')).to eq(jid1)
        end

        # update key to new job id
        jid2 = SfdWorker.perform_debounce(3, 'abc123', { debounce_key: 'stuff' })

        ::Sidekiq.redis do |conn|
          expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
          expect(conn.get('debounce::SfdWorker::stuff')).to eq(jid2)
        end
      end

      it 'should use debounce_namespace override passed into perform_debounce' do
        # not present yet
        ::Sidekiq.redis do |conn|
          expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
          expect(conn.get('debounce::stuff::abc123')).to eq(nil)
        end

        # set it to this job id
        jid1 = SfdWorker.perform_debounce(3, 'abc123', { debounce_namespace: 'stuff' })

        ::Sidekiq.redis do |conn|
          expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
          expect(conn.get('debounce::stuff::abc123')).to eq(jid1)
        end

        # update key to new job id
        jid2 = SfdWorker.perform_debounce(3, 'abc123', { debounce_namespace: 'stuff' })

        ::Sidekiq.redis do |conn|
          expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
          expect(conn.get('debounce::stuff::abc123')).to eq(jid2)
        end
      end
    end
  end
end
