# frozen_string_literal: true

require 'spec_helper'

class MyWorker; end

RSpec.describe SidekiqFastDebounce::Utils do
  describe 'base_key' do
    it 'no args' do
      job = sidekiq_job('MyWorker', [])
      base_key = SidekiqFastDebounce::Utils.base_key(job)
      expect(base_key).to eq('DEBOUNCE_NO_ARGS')
    end

    it 'should return the only argument' do
      job = sidekiq_job('MyWorker', [1])
      base_key = SidekiqFastDebounce::Utils.base_key(job)
      expect(base_key).to eq(1)
    end

    it 'should return the MD5 hash of the arguments' do
      job = sidekiq_job('MyWorker', [1, 'arg'])
      base_key = SidekiqFastDebounce::Utils.base_key(job)
      expect(base_key).to eq('415320f7fea0e4bfc905250606eeb3f5')
    end

    context 'debounce_key override' do
      it 'string' do
        job = sidekiq_job('MyWorker', [])
        job['debounce_key'] = 'my_key'
        base_key = SidekiqFastDebounce::Utils.base_key(job)
        expect(base_key).to eq('my_key')
      end

      it 'symbol' do
        job = sidekiq_job('MyWorker', [1])
        job[:debounce_key] = 'my_key'
        base_key = SidekiqFastDebounce::Utils.base_key(job)
        expect(base_key).to eq('my_key')
      end
    end
  end

  describe 'debounce_key' do
    it 'base case' do
      job = sidekiq_job('MyWorker', [1])
      deb_key = SidekiqFastDebounce::Utils.debounce_key(job)
      expect(deb_key).to eq('debounce::MyWorker::1')
    end

    context 'debounce_namespace override' do
      it 'string' do
        job = sidekiq_job('MyWorker', ['asdf'])
        job['debounce_namespace'] = 'my_name'
        deb_key = SidekiqFastDebounce::Utils.debounce_key(job)
        expect(deb_key).to eq('debounce::my_name::asdf')
      end

      it 'string' do
        job = sidekiq_job('MyWorker', [1])
        job[:debounce_namespace] = 'my_name'
        deb_key = SidekiqFastDebounce::Utils.debounce_key(job)
        expect(deb_key).to eq('debounce::my_name::1')
      end
    end
  end
end
