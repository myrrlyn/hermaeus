[![Gem Version](https://badge.fury.io/rb/hermaeus.svg)](https://badge.fury.io/rb/hermaeus)

# Hermaeus

Hermaeus Mora, the Daedric Prince of Fate and Knowledge, hoards information in
his halls of Apocrypha.

/r/teslore maintains a list of Apocryphal texts, but since they are reddit posts
by ordinary users, they are at risk of deletion. `Hermaeus` provides a means of
collecting and archiving /r/teslore Apocrypha.

`Hermaeus` works by scraping established index lists on /r/teslore, including
the Compendium wiki pages and the weekly Community Threads in which new entries
are announced, and collects the Markdown source of the referenced posts.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hermaeus'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hermaeus

## Usage

`Hermaeus` can be used in other Ruby scripts via top-level methods, or via the
`mora` executable.

On first run, `mora` will deliberately crash and complain that the config file
is missing. It will create a sample configuration file for you to edit, at
`$HOME/.hermaeus/config.toml`.

This file needs to be populated with reddit credentials so Hermaeus can log in.
The `[client]` section of this file has four keys, each of which have comments
explaining what they should hold. Hermaeus will crash with helpful (I hope)
error messages if any of these fields are missing, or if they are duplicates of
the example configuration file. Once you have filled in the configuration file
with correct values, Hermaeus will function properly.

Hermaeus’ configuration files can be specified using the environment variables
`HERMAEUS_DIR` and `HERMAEUS_FILE`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can
also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/myrrlyn/hermaeus.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
