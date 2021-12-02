# frozen_string_literal: true

require 'spec_helper'

class NamespaceWorker; end

class KeyWorker; end

RSpec.describe SidekiqFastDebounce::Utils do
  describe 'extract_opt!' do
    it 'returns present: false' do
      args = {
        things: 1234
      }

      opt = SidekiqFastDebounce::Utils.extract_opt!(:test, args)

      expect(opt.size).to eq(0)
      expect(opt.key?(:value)).to eq(false)

      expect(args.size).to eq(1)
      expect(args[:things]).to eq(1234)
    end

    it 'finds symbol' do
      args = {
        things: 1234,
        stuff: :junk
      }

      opt = SidekiqFastDebounce::Utils.extract_opt!(:things, args)

      expect(opt.size).to eq(1)
      expect(opt[:value]).to eq(1234)

      expect(args.size).to eq(1)
      expect(args[:stuff]).to eq(:junk)
      expect(args.key?(:things)).to eq(false)
    end

    it 'finds string' do
      args = {
        'things' => 1234,
        :stuff => :junk
      }

      opt = SidekiqFastDebounce::Utils.extract_opt!(:things, args)

      expect(opt.size).to eq(1)
      expect(opt[:value]).to eq(1234)

      expect(args.size).to eq(1)
      expect(args[:stuff]).to eq(:junk)
      expect(args.key?(:things)).to eq(false)
    end
  end

  describe 'debounce_opts' do
    it 'finds no override opts' do
      job = sidekiq_job('KeyWorker', [1, 'arg'])
      opts = SidekiqFastDebounce::Utils.debounce_opts(job)

      expect(opts.size).to eq(0)
      expect(job['args'].length).to eq(2)
      expect(job['args']).to eq([1, 'arg'])
    end

    it 'find debounce_key option' do
      job = sidekiq_job('KeyWorker', [1, 'arg', { 'debounce_key' => 'abc123' }])
      opts = SidekiqFastDebounce::Utils.debounce_opts(job)

      expect(opts.size).to eq(1)
      expect(opts[:debounce_key]).to eq('abc123')

      expect(job['args'].length).to eq(2)
      expect(job['args']).to eq([1, 'arg'])
    end

    it 'find debounce_namespace option' do
      job = sidekiq_job('KeyWorker', [1, 'arg', { 'debounce_namespace' => 'abc123' }])
      opts = SidekiqFastDebounce::Utils.debounce_opts(job)

      expect(opts.size).to eq(1)
      expect(opts[:debounce_namespace]).to eq('abc123')

      expect(job['args'].length).to eq(2)
      expect(job['args']).to eq([1, 'arg'])
    end

    it 'find debounce_key option - leave other arg alone' do
      job = sidekiq_job('KeyWorker', [1, 'arg', { 'stuff' => 'junk', 'debounce_key' => 'abc123' }])
      opts = SidekiqFastDebounce::Utils.debounce_opts(job)

      expect(opts.size).to eq(1)
      expect(opts[:debounce_key]).to eq('abc123')

      expect(job['args'].length).to eq(3)
      expect(job['args']).to eq([1, 'arg', { 'stuff' => 'junk' }])
    end
  end

  describe 'debounce_namespace' do
    it 'should return the class name' do
      namespace = SidekiqFastDebounce::Utils.debounce_namespace(NamespaceWorker, {})
      expect(namespace).to eq('NamespaceWorker')
    end

    it 'should return the namespace override' do
      deb_opts = { debounce_namespace: 'test' }
      namespace = SidekiqFastDebounce::Utils.debounce_namespace(NamespaceWorker, {}, deb_opts)
      expect(namespace).to eq('test')
    end
  end

  describe 'debounce_key' do
    it 'should raise error' do
      job = sidekiq_job('KeyWorker', [])
      expect do
        SidekiqFastDebounce::Utils.debounce_key(KeyWorker, job)
      end.to raise_exception(ArgumentError)
    end

    it 'should return the only argument' do
      job = sidekiq_job('KeyWorker', [1])
      deb_key = SidekiqFastDebounce::Utils.debounce_key(KeyWorker, job)
      expect(deb_key).to eq(1)
    end

    it 'should return the MD5 hash of the arguments' do
      job = sidekiq_job('KeyWorker', [1, 'arg'])
      deb_key = SidekiqFastDebounce::Utils.debounce_key(KeyWorker, job)
      expect(deb_key).to eq('415320f7fea0e4bfc905250606eeb3f5')
    end

    it 'should return the debounce_key override' do
      deb_opts = { debounce_key: 'test' }
      sidekiq_job('KeyWorker', [1, 'arg'])
      deb_key = SidekiqFastDebounce::Utils.debounce_key(KeyWorker, {}, deb_opts)
      expect(deb_key).to eq('test')
    end
  end
end
