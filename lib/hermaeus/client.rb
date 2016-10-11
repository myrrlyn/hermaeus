%w[
	htmlentities
	redd
].each(&method(:require))

require "hermaeus/config"

module Hermaeus
	# Public: Wraps a reddit client for access to reddit's API
	class Client
		USER_AGENT = "Redd/Ruby:Hermaeus:#{Hermaeus::VERSION} (by /u/myrrlyn)"
		# Public: Connects the Hermaeus::Client to reddit
		#
		# info - A Hash with Symbol keys containing reddit connection information.
		# It should be the `[:client]` section of the Hash returned by
		# `Hermaeus::Config.load`.
		def initialize client
			Config.validate client: client
			@client = Redd.it(client.delete(:type).to_sym, *client.values, user_agent: USER_AGENT)
			@client.authorize!
			@html_filter = HTMLEntities.new
		end
	end
end
