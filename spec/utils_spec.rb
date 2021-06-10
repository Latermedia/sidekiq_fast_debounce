# frozen_string_literal: true

require 'spec_helper'

class NamespaceWorker; end
class KeyWorker; end

RSpec.describe SidekiqFastDebounce::Utils do
  describe 'debounce_key' do
    it 'should raise error' do
      job = sidekiq_job('KeyWorker', [])
      expect do
        SidekiqFastDebounce::Utils.debounce_key(job)
      end.to raise_exception(ArgumentError)
    end

    it 'should return the only argument' do
      job = sidekiq_job('KeyWorker', [1])
      deb_key = SidekiqFastDebounce::Utils.debounce_key(job)
      expect(deb_key).to eq(1)
    end

    it 'should return the MD5 hash of the arguments' do
      job = sidekiq_job('KeyWorker', [1, 'arg'])
      deb_key = SidekiqFastDebounce::Utils.debounce_key(job)
      expect(deb_key).to eq('415320f7fea0e4bfc905250606eeb3f5')
    end
  end
end
