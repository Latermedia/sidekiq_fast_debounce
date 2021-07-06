# frozen_string_literal: true

RSpec.describe Middleware::Sidekiq::Client::FastDebounce do
  describe 'middleware' do
    describe 'client' do
      it 'should not debounce anything via perform_async' do
        expect(SidekiqFastDebounce::Utils).to_not receive(:debounce_key)

        SfdWorker.perform_async('abc123')
      end

      it 'should debounce via perform_debounce' do
        expect(SidekiqFastDebounce::Utils).to receive(:debounce_key).and_return('asdf')

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

      describe 'option overrides' do
        it 'should use debounce_key override' do
          # not present yet
          ::Sidekiq.redis do |conn|
            expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
            expect(conn.get('debounce::SfdWorker::stuff')).to eq(nil)
          end

          # set it to this job id
          jid1 = SfdWorker.set(debounce_key: 'stuff').perform_debounce(3, 'abc123')

          ::Sidekiq.redis do |conn|
            expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
            expect(conn.get('debounce::SfdWorker::stuff')).to eq(jid1)
          end

          # update key to new job id
          jid2 = SfdWorker.set(debounce_key: 'stuff').perform_debounce(3, 'abc123')

          ::Sidekiq.redis do |conn|
            expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
            expect(conn.get('debounce::SfdWorker::stuff')).to eq(jid2)
          end
        end

        it 'should use debounce_namespace override' do
          # not present yet
          ::Sidekiq.redis do |conn|
            expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
            expect(conn.get('debounce::stuff::abc123')).to eq(nil)
          end

          # set it to this job id
          jid1 = SfdWorker.set(debounce_namespace: 'stuff').perform_debounce(3, 'abc123')

          ::Sidekiq.redis do |conn|
            expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
            expect(conn.get('debounce::stuff::abc123')).to eq(jid1)
          end

          # update key to new job id
          jid2 = SfdWorker.set(debounce_namespace: 'stuff').perform_debounce(3, 'abc123')

          ::Sidekiq.redis do |conn|
            expect(conn.get('debounce::SfdWorker::abc123')).to eq(nil)
            expect(conn.get('debounce::stuff::abc123')).to eq(jid2)
          end
        end

        it 'should use debounce_ttl override' do
          SfdWorker.perform_debounce(3, 'abc123')

          ::Sidekiq.redis do |conn|
            expect(conn.ttl('debounce::SfdWorker::abc123')).to be_within(1).of(63)
          end

          SfdWorker.set(debounce_ttl: 30).perform_debounce(3, 'abc1234')

          ::Sidekiq.redis do |conn|
            expect(conn.ttl('debounce::SfdWorker::abc1234')).to be_within(1).of(33)
          end
        end
      end
    end
  end
end
