require "hermaeus/error"

require "tomlrb"

module Hermaeus
	# Public: Provides configuration services for Hermaeus
	module Config
		# Directory where Hermaeus configuration files are stored
		DIR = File.join Dir.home, ".hermaeus"
		# File in which Hermaeus configuration values are stored
		FILE = File.join DIR, "config.toml"
		# Configuration template in Hermaeus’ source code
		SOURCE = File.join(File.dirname(__FILE__), "..", "..", "data", "config.toml")
		# List of allowed types a reddit client can take
		ALLOWED_TYPES = %w[script web userless installed]

		# Public: Accessor for the loaded and parsed information.
		#
		# Returns nil if the config file has yet to be processed.
		def self.info
			@info
		end

		# Public: Load a configuration file into memory
		#
		# Returns the configuration file represented as a Hash with Symbol keys
		def self.load
			@info = Tomlrb.load_file FILE, symbolize_keys: true
		end

		# Public: Performs validation checks on a configuration structure
		#
		# Returns true if the configuration argument is valid
		#
		# Raises a ConfigurationError if the configuration is invalid, with an
		# error message describing the failure.
		def self.validate!
			unless @info.has_key? :client
				raise ConfigurationError.new <<-EOS
Hermaeus’ configuration file must contain a [client] section.
				EOS
			end
			unless @info[:client].has_key?(:type) && ALLOWED_TYPES.include?(@info[:client][:type])
				raise ConfigurationError.new <<-EOS
Hermaeus’ [client] section must include a type key whose value is one of:
#{ALLOWED_TYPES.join(", ")}.

[client]
type = "one of the listed types"
				EOS
			end
			unless @info[:client].has_key?(:id) && @info[:client].has_key?(:secret)
				raise ConfigurationError.new <<-EOS
Hermaeus’ [client] section must include keys for the ID and secret provided by
reddit for your application.

[client]
id = "an ID from reddit"
secret = "a secret from reddit"
				EOS
			end
			if @info[:client][:type] == "script"
				client = @info[:client]
				unless client.has_key?(:username) && client.has_key?(:password)
					raise ConfigurationError.new <<-EOS
When configured for `type = "script"`, Hermaeus’ [client] section must include
keys for the reddit account username and password as which it will work.

[client]
username = "a_reddit_username"
password = "hunter2"
					EOS
				end
			end
		@info[:archive] ||= { path: "archive" }
		@info[:index] ||= { path: "/r/teslore/wiki/archive" }
		true
		end
	end
end
