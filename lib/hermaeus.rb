%w[
	apocryphon
	archivist
	client
	config
	error
	version
].map { |mod| "hermaeus/#{mod}" }
.each { |mod| require mod }

require "logger"

# Public: Root module for Hermaeus.
#
# Hermaeus’ top-level methods provide the interface used by `mora`.
module Hermaeus
	# Public: Initializes Hermaeus for use.
	def self.init
		@log = Logger.new STDERR
		log.info "Initializing Hermaeus..."
		Config.init
	end

	# Public: Connects Hermaeus to reddit.
	def self.connect
		log.info "Connecting to reddit..."
		@client = Client.new
	end

	# Public: Downloads Apocrypha posts.
	#
	# type - "index" or "com"
	# ids - A list of thread IDs to access and scrape, if type is "com"
	def self.seek type, ids, &block
		if type == "index"
			log.info "Scanning index page..."
			list = @client.get_global_listing
		elsif type == "com"
			log.info "Scanning Community Thread(s)..."
			list = @client.get_weekly_listing ids
		end
		log.info "Collecting #{list.size} posts..."
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

	# Public: Accessor for Hermaeus’ Logger.
	#
	# Returns Hermaeus’ common logger.
	def self.log
		@log
	end
end
