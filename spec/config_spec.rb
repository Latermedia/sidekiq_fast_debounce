# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqFastDebounce::Config do
  describe 'configuration' do
    before(:each) do
      if SidekiqFastDebounce.instance_variable_defined?(:@config)
        SidekiqFastDebounce.remove_instance_variable(:@config)
      end
    end

    it 'config block and reset work' do
      c1 = SidekiqFastDebounce.config

      expect(c1.grace_ttl).to eq(SidekiqFastDebounce::Config::GRACE_TTL_DEFAULT)

      SidekiqFastDebounce.configure do |config|
        config.grace_ttl = 120
      end

      c2 = SidekiqFastDebounce.config

      expect(c2.grace_ttl).to eq(120)

      SidekiqFastDebounce.reset_config

      c3 = SidekiqFastDebounce.config

      expect(c3.grace_ttl).to eq(SidekiqFastDebounce::Config::GRACE_TTL_DEFAULT)
    end
  end
end
