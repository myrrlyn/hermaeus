%w[
	htmlentities
	nokogiri
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

		# Public: Scrapes the Compilation full index
		#
		# Optional parameters:
		#
		# query: A CSS selector string that will be used to target the HTML nodes
		# desired.
		#
		# Returns a String Array containing the links pointed to by the Compendium
		# index page.
		def get_global_listing **opts
			# This is a magic string that targets the index format /r/teslore uses to
			# enumerate their Compendium.
			query = opts[:query] || "td:first-child a"
			# The returned HTML content is escaped, so it cannot be parsed as HTML.
			fetch = @client.get("/r/teslore/wiki/compilation").body[:data]
			# Rebind fetch to be unescaped HTML that Nokogiri can actually parse.
			fetch = @html_filter.decode(fetch[:content_html])
			# Feed the HTML text to Nokogiri for parsing.
			doc = Nokogiri::HTML(fetch)
			# CSS select all the links referenced by the index page. The CSS selector
			# method returns Nokogiri objects, which are mapped down to the href data.
			doc.css(query).map do |item|
				item.attributes["href"].value
			end
		end
	end
end
