# SidekiqFastDebounce

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/sidekiq_fast_debounce`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq_fast_debounce'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install sidekiq_fast_debounce
```

## Usage

### Add Middleware

This will automatically register client and server middleware. Place in an initializer, probably the same one you configure `sidekiq` in.
```ruby
SidekiqFastDebounce.add_middleware
```

If you have specific ordering needs you can add the following classes as required:
```ruby
Middleware::Sidekiq::Client::FastDebounce
Middleware::Sidekiq::Server::FastDebounce
```

### Configuration

You can configure a global options for `sidekiq_fast_debounce`.
- `grace_ttl` configures how many extra seconds the debounce lock key lives after time the job is suppose to have started. This is useful for if you have queues that back up. Default is `60` seconds.

```ruby
SidekiqFastDebounce.configure do |config|
  config.grace_ttl = 60
end
```

### Debouncing

Basic usage:
```ruby
MyWorker.perform_debounce(10.seconds, 'arg1', :arg2)
```

### Debounce Key

There are a number of different ways to specify the debounce key. They are listed here in order of presedence. If none of these methods are found, it will raise an `ArgumentError`.

#### In `perform_debounce`

As a optional param at the end of the `perform_debounce`. This will be removed from the args before being pushed to Redis.

```ruby
MyWorker.perform_debounce(10.seconds, 'arg1', :arg2, debounce_key: 'abc123')
```

#### Directly from the job arguments

The value of `arg1` will be the debounce key.

```ruby
class MyWorker
  include Sidekiq::Worker
  include SidekiqFastDebounce

  def perform(arg1)
    #
  end
end
```

The jobs args will be converted to JSON then the MD5 hash of the resulting JSON will be the debounce key.

```ruby
class MyWorker
  include Sidekiq::Worker
  include SidekiqFastDebounce

  def perform(arg1, arg2)
    #
  end
end
```

### Debounce Namespace

By default the debounce keys are namespaced with the worker class name. You can override this with an optional param at the end of the `perform_debounce`. This will be removed from the args before being pushed to Redis.

```ruby
MyWorker.perform_debounce(10.seconds, 'arg1', :arg2, debounce_namespace: 'ns123')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Latermedia/sidekiq_fast_debounce. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SidekiqFastDebounce project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Latermedia/sidekiq_fast_debounce/blob/master/CODE_OF_CONDUCT.md).
