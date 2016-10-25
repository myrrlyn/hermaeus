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
			# Compare values against the example file, to see if they have been set.
			demo = Tomlrb.load_file SOURCE, symbolize_keys: true

			# Validate the [client] section.
			unless @info.has_key? :client
				fail! <<-EOS
Hermaeus’ configuration file must contain a [client] section.
				EOS
			end

			client = @info[:client]

			# Validate the [client] section’s id and secret fields.
			unless client.has_key?(:id) && client.has_key?(:secret)
				fail! <<-EOS
Hermaeus’ [client] section must include keys for the ID and secret provided by
reddit for your application.

[client]
id = "an ID from reddit"
secret = "a secret from reddit"
				EOS
			end

			if client[:id]     == demo[:client][:id] \
			|| client[:secret] == demo[:client][:secret]
				fail! <<-EOS
You need to register an application with reddit to receive an ID and secret, and
paste these values into the configuration file for Hermaeus to use.

[client]
id = "the ID reddit gave you for your application"
secret = "the secret reddit gave you for your application"
				EOS
			end

			# Validate the [client] section’s username and password fields.
			if client[:type] == "script"
				if !client.has_key? :username \
				|| !client.has_key? :password \
				|| client[:username] == demo[:client][:username] \
				|| client[:password] == demo[:client][:password]
					fail! <<-EOS
Hermaeus’ [client] section must include information for the reddit account
username and password as which it will work.

[client]
username = "a_reddit_username"
password = "hunter2"
					EOS
				end
			end

			# Validate the [archive] section.
			unless @info.has_key? :archive
				fail! <<-EOS
Hermaeus’ configuration file must include an [archive] section to govern the
storage of downloaded posts.
				EOS
			end

			unless @info[:archive].has_key? :path
				fail! <<-EOS
Hermaeus’ [archive] section must include a path field containing a relative or
absolute path in which to store the downloaded posts.

[archive]
path = "./archive"
# path = "/tmp/teslore/archive"
				EOS
			end

			# Validate the [index] section.
			unless @info.has_key? :index
				fail! <<-EOS
Hermaeus’ configuration file must include an [index] section to govern the
processing of the subreddit’s index page.
				EOS
			end

			unless @info[:index].has_key? :path
				fail! <<-EOS
Hermaeus’ [index] section must include a path field containing the reddit page
at which the index resides.

[index]
path = "/r/teslore/wiki/archive"
				EOS
			end
			nil
		end

		private

		# Internal: Logs a fatal message and throws an exception.
		#
		# msg - A String describing the error that occurred.
		#
		# Raises a ConfigurationError with the given message.
		def self.fail! msg
			Hermaeus.log.fatal <<-EOS
Your configuration file (#{FILE}) is invalid, and must be edited to continue.
			EOS
			raise ConfigurationError.new msg
		end
	end
end
