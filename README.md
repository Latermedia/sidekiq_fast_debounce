# SidekiqFastDebounce

`SidekiqFastDebounce` add debounce functionality to your Sidekiq workers via the `perform_debounce` method. There are a few other Sidekiq debounce gems out there, but the two most popular ones both search the `ScheduledSet` to remove previous jobs. At the time of writing our `ScheduledSet` contains over 1 million jobs. Searching through even a small fraction of those jobs would be a problem.

Instead we decided to rely on the fact that Sidekiq jobs should be [idempotent](https://github.com/mperham/sidekiq/wiki/Best-Practices#2-make-your-job-idempotent-and-transactional). If multiple version of the job run, that is ok.

When a job is debounced via `perform_debounce`, we generate what is effectively a lock key for a job based on its worker class and arguments, that we call the `debounce_key`. We store the Sidekiq job id as the value of this key/value pair and and any Sidekiq job that runs that doesn't match the stored job id, will get skipped. This ensures on the last debounced job actually runs. As the job runs it cleans up the `debounce_key` so that the next debounced job would be able to run.

We are treating debouncing as an omptimization, not a strict requirement.

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

`perform_debounce` will automatically be available on any Sidekiq worker.

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
Can also we set for an individual job
```ruby
MyWorker.set(debounce_ttl: 30).perform_debounce(10.seconds, 'arg1')
```

### Debouncing

Basic usage:
```ruby
MyWorker.perform_debounce(10.seconds, 'arg1', :arg2)
```

### Debounce Key

The debounce key is what provides a the uniqueness between the enqueued debounced jobs. Generally, you'll just let it be set implicitly as a value dervide from the worker name and the arguments. Any job for with the same worker and arguments will have the same debounce key.

If you need to debounce jobs such that different arguments result in the same key, you can explicity set the key via the `set` method.

```ruby
MyWorker.set(debounce_key: 'abc123').perform_debounce(10.seconds, 'arg1')
```

### Debounce Namespace

By default the debounce keys are namespaced with the worker class name. You can override this using `set`.

```ruby
MyWorker.set(debounce_namespace: 'ns123').perform_debounce(10.seconds, 'arg1', :arg2)
```

### Debouncing Completely Different Jobs

By explicity setting both `debounce_key` and `debounce_namespace`, you have complete control of the Redis key being used to control the debounce nature of the jobs

```ruby
MyWorker.set(debounce_key: 'abc123', debounce_namespace: 'ns123').perform_debounce(10.seconds, 'arg1')
```

### Retries

If job 1 fails, then job 2 gets enqueued via `perform_debounce`, job 1 will not be processed if its retry happened before job 2 runs. This is because job 2 will handle whatever job 1 would have. (Remember, Sidekiq jobs should be [idempotent](https://github.com/mperham/sidekiq/wiki/Best-Practices#2-make-your-job-idempotent-and-transactional).) If the job 1's retry would happen after job 2 run, the job 1's retry will run.

For details on the implementation you can checkout the server side middleware's source.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Latermedia/sidekiq_fast_debounce. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SidekiqFastDebounce project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Latermedia/sidekiq_fast_debounce/blob/master/CODE_OF_CONDUCT.md).
