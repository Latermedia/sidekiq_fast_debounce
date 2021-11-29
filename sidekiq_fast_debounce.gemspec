# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq_fast_debounce/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq_fast_debounce'
  spec.version       = SidekiqFastDebounce::VERSION
  spec.authors       = ['Les Fletcher']
  spec.email         = ['les@later.com']

  spec.summary       = 'Debounce Sidekiq jobs'
  spec.description   = 'Add debounce functionality to Sidekiq without touching the ScheduledSet.'
  spec.homepage      = 'https://github.com/Latermedia/sidekiq_fast_debounce'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.5'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'bundler-audit'
  spec.add_development_dependency 'fakeredis'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.2'
  spec.add_development_dependency 'rubocop', '~> 1.22.1'
  spec.add_development_dependency 'yard'
end
