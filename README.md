# AtlassianStatusUpdater

For now, utility code to just look for 'doneish' issues and try to close them. (Maybe add more functionality later?)

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/atlassian_status_updater`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'atlassian_status_updater'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install atlassian_status_updater

## Usage

1. Copy `.env.example` to `.env` and populate the values as applicable.

2. Run `bundle install`.

3. To status-change to 'Closed', run

  ```
  MAX_RESULTS=3 INGORE_PREV_SKIPS=false RUN_VERBOSE=false ruby bin/close_tickets.rb
  ````

  ... but first adjusting the env var's (MAX_RESULTS, INGORE_PREV_SKIPS and RUN_VERBOSE) as applicable:
  * MAX_RESULTS: How many ticket to check
  * INGORE_PREV_SKIPS: 
    * `true` (to NOT 'seed' the skips from `log/errored_tickets.log`)
    * `false` (to 'seed' the skips from `log/errored_tickets.log`)

    Each time this script runs, it first checks for skipped tickets noted in `log/errored_tickets.log` and will ignore those in the `jql` search.

    As it runs, it collects any 'error' tickets that it wasn't able to status-change.

    At the end, it will add (merge) the error tickets to `log/errored_tickets.log` and put (replace) the successful tickets to `log/successful_ticket_keys.log`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/atlassian_status_updater.
