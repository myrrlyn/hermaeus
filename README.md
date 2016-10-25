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

### Configuration

The configuration file allows for some complex behavior. The `[archive]` section
permits relative or absolute paths in the `path` key, setting where Hermaeus
writes files to disk. The `title_fmt` and `title_args` fields set up a format
string for the filenames of the saved posts; the `title_fmt` field consists of
`%s` tokens in the desired layout, and the `title_args` field is an array of
metadata names. Since the strings in `title_args` are called as method names,
this field is whitelisted to limit the attack surface. The permitted items are:

- author
- created
- created_utc
- edited
- id
- name
- score
- subreddit
- title

The "created{,_utc}" and "edited" methods return Unix timestamps, which allow
for proper sorting on disk but are not otherwise useful in filenames.

The "score" method returns an integer, so it can be used with a `%i` token as
well as the generic `%s`.

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
