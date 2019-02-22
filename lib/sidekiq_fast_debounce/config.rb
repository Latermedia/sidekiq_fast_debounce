# frozen_string_literal: true

module SidekiqFastDebounce
  class Config
    GRACE_TTL_DEFAULT = 60

    attr_accessor :grace_ttl

    def initialize
      @grace_ttl = GRACE_TTL_DEFAULT
    end
  end
end
