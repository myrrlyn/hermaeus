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

		# Public: Transforms a list of raw reddit links ("/r/SUB/comments/ID/NAME")
		# into their reddit fullname ("t3_ID").
		#
		# data - A String Array such as that returned by get_global_listing.
		#
		# Optional parameters:
		#
		# regex: A Regular Expression used to match the reddit ID out of a link.
		#
		# Returns a String Array containing the reddit fullnames harvested from the
		# input list. Input elements that do not match are stripped.
		def get_fullnames data, **opts
			regex = opts[:regex] || %r(/r/.+/(comments/)?(?<id>[0-9a-z]+)/.+)
			data.map do |item|
				m = item.match regex
				"t3_#{m[:id]}" if m
			end
			.reject { |item| item.nil? }
		end

		# Public: Collects posts from reddit.
		#
		# fullnames - A String Array of reddit fullnames ("tNUM_ID", following
		# reddit documentation) to query.
		#
		# Yields a sequence of Hashes, each describing a reddit post.
		#
		# Returns an Array of the response bodies from the reddit call(s).
		#
		# Examples
		#
		# get_posts get_fullnames get_global_listing do |post|
		#   puts post[:selftext] # Prints the Markdown source of each post
		# end
		# => returns an array of hashes, each of which includes an array of posts.
		def get_posts fullnames
			ret = []
			# reddit has finite limits on acceptable query sizes. Split the list into
			# manageable portions
			fullnames.fracture.each do |chunk|
				# Assemble the list of reddit objects being queried
				query = chunk.join(",")
				# Ask reddit to procure our items
				response = @client.get("/by_id/#{query}.json")
				if response.success?
					payload = response.body
					# The payload should be a Listing even for a single-item query; the
					# :children array will just have one element.
					if payload[:kind] == "Listing"
						payload[:data][:children].each do |item|
							yield item[:data]
						end
					# else
					end
					ret << payload
				end
				# Keep the rate limiter happy
				sleep 1
			end
			ret
		end
	end
end

class Array
	# Public: Splits an Array into several arrays, each of which has a maximum
	# size.
	#
	# size - The maximum length of each segment. Defaults to 100.
	#
	# Returns an Array of Arrays. Each element of the returned array is a section
	# of the original array.
	#
	# Examples
	#
	# %w[a b c d e f g h i j k l m n o p q r s t u v w x y z].fracture 5
	# => [
	#	  ["a", "b", "c", "d", "e"],
	#   ["f", "g", "h", "i", "j"],
	#   ["k", "l", "m", "n", "o"],
	#   ["p", "q", "r", "s", "t"],
	#   ["u", "v", "w", "x", "y"],
	#   ["z"]
	# ]
	# %w[hello world].fracture 5 => [["hello", "world"]]
	def fracture size = 100
		if self.length < size
			[self]
		else
			ret = []
			self.each_with_index do |val, idx|
				ret[idx / size] ||= []
				ret[idx / size] << val
			end
			ret
		end
	end
end
