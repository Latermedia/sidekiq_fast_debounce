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
        SfdWorker.perform_debounce(10, 'abc123')

        expect(SfdWorker.jobs.size).to eq(4)
        expect(SfdWorker).to receive(:trigger).once
        expect_any_instance_of(Redis).to receive(:del).with('debounce::SfdWorker::abc123').once
        Sidekiq::Worker.drain_all
      end

      it 'should only perform once - multiarg' do
        SfdWorker2.perform_debounce(10, 'abc123', 'stuff')
        SfdWorker2.perform_debounce(10, 'abc123', 'stuff')
        SfdWorker2.perform_debounce(10, 'abc123', 'stuff')
        SfdWorker2.perform_debounce(10, 'abc123', 'stuff')

        expect(SfdWorker2.jobs.size).to eq(4)
        expect(SfdWorker2).to receive(:trigger).once
        Sidekiq::Worker.drain_all
      end

      it 'should allow retries to pass through' do
        job = sidekiq_job(SfdWorker, ['abc123'])
        job['debounce_key'] = 'debounce::SfdWorker::abc123'
        job['retry_count'] = 2

        middleware = Middleware::Sidekiq::Server::FastDebounce.new

        trigger = double
        expect(trigger).to receive(:trigger)

        middleware.call(SfdWorker.new, job, 'default') do
          trigger.trigger
        end
      end

      it 'skip retries if another morker is scheduled for this key' do
        SfdWorker.perform_debounce(10, 'abc123')

        job = sidekiq_job(SfdWorker, ['abc123'])
        job['debounce_key'] = 'debounce::SfdWorker::abc123'
        job['retry_count'] = 2

        middleware = Middleware::Sidekiq::Server::FastDebounce.new

        trigger = double
        expect(trigger).to_not receive(:trigger)

        middleware.call(SfdWorker.new, job, 'default') do
          trigger.trigger
        end
      end

      context 'set options' do
        it 'debounce_key' do
          SfdWorker.set(debounce_key: 'abc').perform_debounce(10, '123')
          SfdWorker.set(debounce_key: 'abc').perform_debounce(10, '234')
          SfdWorker.set(debounce_key: 'abc').perform_debounce(10, '345')

          expect(SfdWorker.jobs.size).to eq(3)
          expect(SfdWorker).to receive(:trigger).once
          expect_any_instance_of(Redis).to receive(:del).with('debounce::SfdWorker::abc').once
          Sidekiq::Worker.drain_all
        end

        it 'debounce_namespace' do
          SfdWorker.set(debounce_namespace: 'abc').perform_debounce(10, '123')
          SfdWorker3.set(debounce_namespace: 'abc').perform_debounce(10, '123')

          expect(SfdWorker.jobs.size).to eq(1)
          expect(SfdWorker3.jobs.size).to eq(1)
          expect(SfdWorker).to_not receive(:trigger)
          expect(SfdWorker3).to receive(:trigger).once
          expect_any_instance_of(Redis).to receive(:del).with('debounce::abc::123').once
          Sidekiq::Worker.drain_all
        end

        it 'debounce_namespace & debounce_key' do
          SfdWorker.set(debounce_namespace: 'abc', debounce_key: '123').perform_debounce(10, 'arg1')
          SfdWorker3.set(debounce_namespace: 'abc', debounce_key: '123').perform_debounce(10, 'arg1')

          expect(SfdWorker.jobs.size).to eq(1)
          expect(SfdWorker3.jobs.size).to eq(1)
          expect(SfdWorker).to_not receive(:trigger)
          expect(SfdWorker3).to receive(:trigger).once
          expect_any_instance_of(Redis).to receive(:del).with('debounce::abc::123').once
          Sidekiq::Worker.drain_all
        end
      end
    end
  end
end
