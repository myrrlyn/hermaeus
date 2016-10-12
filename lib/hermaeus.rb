require "hermaeus/apocryphon"
require "hermaeus/archivist"
require "hermaeus/client"
require "hermaeus/config"
require "hermaeus/error"
require "hermaeus/version"

require "fileutils"

# Public: Root module for Hermaeus.
#
# Hermaeus’ top-level methods provide the interface used by `mora`.
module Hermaeus
	# Public: Initializes Hermaeus for use.
	#
	# Raises a ConfigurationError if Hermaeus’ config file does not exist, and
	# creates a sample configuration file for modification.
	def self.init
		FileUtils.mkdir_p(Config::DIR)
		if File.exist? Config::FILE
			@cfg = Config.load
			Config.validate @cfg
		else
			File.open Config::FILE, "w+" do |file|
				File.open File.expand_path(Config::SOURCE), "r", "0600" do |cfg|
					file << cfg.read
				end
			end
			raise ConfigurationError.new <<-EOS
You must put your reddit credentials in #{File.join Config::DIR,"config.toml"} \
for Hermaeus to function.
			EOS
		end
	end

	# Public: Connects Hermaeus to reddit.
	def self.connect
		@client = Client.new @cfg[:client]
	end

	# Public: Downloads Apocrypha posts.
	#
	# type - "index" or "com"
	# ids - A list of thread IDs to access and scrape, if type is "com"
	def self.seek type, ids, &block
		if type == "index"
			list = @client.get_global_listing
		elsif type == "com"
			list = @client.get_weekly_listing ids
		end
		ids = @client.get_fullnames list
		posts = @client.get_posts ids, &block
	end

	# Public: Print usage information for `mora`.
	#
	# `mora` may not know where Hermaeus is installed, so Hermaeus has to load the
	# help file for it.
	def self.help
		File.open File.join(File.dirname(__FILE__), "..", "data", "usage.txt") do |f|
			puts f.read
		end
	end
end
