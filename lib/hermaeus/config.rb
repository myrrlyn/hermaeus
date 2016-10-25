require "hermaeus/error"

require "fileutils"
require "tomlrb"

module Hermaeus
	# Public: Provides configuration services for Hermaeus
	module Config
		# Directory where Hermaeus configuration files are stored
		DIR = ENV['HERMAEUS_DIR'] || File.join(Dir.home, ".hermaeus")
		# File in which Hermaeus configuration values are stored
		NAME = ENV['HERMAEUS_FILE'] || "config.toml"
		FILE = File.join DIR, NAME
		# Configuration template in Hermaeus’ source code
		SOURCE = File.join File.dirname(__FILE__), "..", "..", "data", "config.toml"

		# Since Archivist supports dynamic method calling from the config file, the
		# config file needs safety checks.
		ALLOWED_TITLE_ARGS = %w[
			author
			created
			created_utc
			edited
			id
			name
			score
			subreddit
			title
		]

		def self.init
			FileUtils.mkdir_p DIR
			load
			validate!
		end

		# Public: Accessor for the loaded and parsed information.
		#
		# Returns nil if the config file has yet to be processed.
		def self.info
			@info
		end

		# Public: Load a configuration file into memory.
		#
		# Returns the configuration file represented as a Hash with Symbol keys.
		#
		# Raises an exception if the configuration file could not be found, and
		# copies the example configuration file to the correct spot before crashing.
		def self.load
			begin
				File.open FILE, "r+" do |file|
					@info = Tomlrb.parse file.read, symbolize_keys: true
				end
			# The configuration file may not exist, in which case the sample file gets
			# written to the expected location and then Hermaeus crashes.
			rescue Errno::ENOENT
				File.open FILE, "w+", 0600 do |file|
					File.open File.expand_path(SOURCE), "r" do |cfg|
						file << cfg.read
					end
				end
				fail! <<-EOS
Hermaeus’ configuration file (at #{FILE}) could not be found, so an example file
has been created for you.

You must populate this file with your reddit credentials in order for Hermaeus
to function.
				EOS
			end
		end

		# Public: Performs validation checks on a configuration structure. This
		# method raises exceptions that should not be caught, as the exceptions
		# raised will always indicate a fatal lack of information for Hermaeus’
		# functionality.
		#
		# Returns nil.
		#
		# Raises a ConfigurationError if the configuration is invalid, with an
		# error message describing the failure.
		def self.validate!
			fail! "The configuration has not been loaded." unless @info

			# Compare values against the example file, to see if they have been set.
			#
			# Hermaeus cannot function with the default values, so ensuring that the
			# file has been actually filled in, rather than just copied into place, is
			# important.
			@example = Tomlrb.load_file SOURCE, symbolize_keys: true

			# Validate the [client] section.
			validate_client!

			# Validate the [archive] section.
			validate_archive!

			# Validate the [index] section.
			validate_index!

			nil
		end

		private

		# Internal: Validates the [client] section of a config file.
		def self.validate_client!
			unless @info.has_key? :client
				fail! <<-EOS
Hermaeus’ configuration file must contain a [client] section.
				EOS
			end

			client = @info[:client]

			# Validate the [client] section’s id and secret fields.
			unless client.has_key?(:id) && client.has_key?(:secret)
				fail! <<-EOS
Hermaeus’ [client] section must include fields for the ID and secret provided by
reddit for your application.

Example:

[client]
id = "an ID from reddit"
secret = "a secret from reddit"
				EOS
			end

			if client[:id]     == @example[:client][:id] \
			|| client[:secret] == @example[:client][:secret]
				fail! <<-EOS
You need to register an application with reddit to receive an ID and secret, and
paste these values into the configuration file for Hermaeus to use.

Example:

[client]
id = "the ID reddit gave you for your application"
secret = "the secret reddit gave you for your application"
				EOS
			end

			# Validate the [client] section’s username and password fields.
			if client[:type] == "script"
				if !client.has_key?(:username) \
				|| !client.has_key?(:password) \
				|| client[:password] == @example[:client][:password]
					fail! <<-EOS
Hermaeus’ [client] section must include information for the reddit account
username and password as which it will work.

If your password is actually hunter2, change your password.

Example:

[client]
username = "a_reddit_username"
password = "hunter2"
					EOS
				end
			end
		end

		# Internal: Validates the [archive] section of a config file.
		def self.validate_archive!
			unless @info.has_key? :archive
				fail! <<-EOS
Hermaeus’ configuration file must include an [archive] section to govern the
storage of downloaded posts.
				EOS
			end

			archive = @info[:archive]

			unless archive.has_key? :path
				fail! <<-EOS
Hermaeus’ [archive] section must include a path field containing a relative or
absolute path in which to store the downloaded posts.

Suggested default:

[archive]
path = "archive" # relative to the directory in which Hermaeus or mora is run

Example:

[archive]
path = "/tmp/teslore/archive" # absolute path
				EOS
			end

			unless archive.has_key?(:title_fmt) && archive.has_key?(:title_args)
				fail! <<-EOS
Hermaeus’ [archive] section must include fields for title format and arguments.
These fields consist of a format string and an array of attributes found on
posts. There must be as many arguments as there are format tokens.

Suggested default:

title_fmt = "%s"
title_args = ["title"]

Example:

[archive]
title_fmt = "%s - %s - %s"
title_args = ["id", "title", "author"]

This example saves posts as "zfxy9 - Jel Language - lu_ming".
				EOS
			end

			# Ensure that there are as many % tokens as there are arguments.
			# TODO: Skip %% tokens (which should never show up anyway in a filename).
			unless archive[:title_fmt].count("%") == archive[:title_args].length
				fail! <<-EOS
The number of %s tokens in title_fmt must be exactly equal to the number of
items in title_args.
				EOS
			end

			# Safety check on the title args: Whitelist only names known to map to
			# useful data on an Apocryphon object, and forbid everything else. This
			# feature exposes an attack surface, as the title_arg strings are called
			# as method names during Archivist processing.
			archive[:title_args].each do |arg|
				unless ALLOWED_TITLE_ARGS.include? arg
					fail! <<-EOS
The title_arg entry "#{arg}" is not permitted. Only the following items are
allowed as title_arg entries:

#{ALLOWED_TITLE_ARGS.join(", ")}.
					EOS
				end
			end
		end

		# Internal: Validates the [index] section of a config file.
		def self.validate_index!
			unless @info.has_key? :index
				fail! <<-EOS
Hermaeus’ configuration file must include an [index] section to govern the
processing of the subreddit’s index page.
				EOS
			end

			idx = @info[:index]

			unless idx.has_key? :path
				fail! <<-EOS
Hermaeus’ [index] section must include a path field containing the reddit page
at which the index resides.

Example:

[index]
path = "/r/teslore/wiki/archive"
				EOS
			end

			unless idx.has_key? :css
				fail! <<-EOS
The [index] section needs a css field containing the CSS selector used to access
the appropriate links on the index page. Finding an appropriate CSS selector may
take some experimentation.

Example:

[index]
css = "td:first-child a"
				EOS
			end
		end

		# Internal: Logs a fatal message and throws an exception.
		#
		# msg - A String describing the error that occurred. May be nil.
		#
		# Raises a ConfigurationError with the given message.
		def self.fail! msg = nil
			default_msg = <<-EOS
Your configuration file (#{FILE}) is invalid, and must be edited to continue.
			EOS
			Hermaeus.log.fatal default_msg
			raise ConfigurationError.new(msg || default_msg)
		end
	end
end
