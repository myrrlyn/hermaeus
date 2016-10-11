%w[
	htmlentities
	nokogiri
	redd
].each(&method(:require))

require "hermaeus/config"

module Hermaeus
	# Public: Wraps a reddit client for access to reddit's API, and provides
	# methods for downloading posts from reddit.
	class Client
		USER_AGENT = "Redd/Ruby:Hermaeus:#{Hermaeus::VERSION} (by /u/myrrlyn)"
		# Public: Connects the Hermaeus::Client to reddit.
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

		# Public: Scrapes the Compilation full index.
		#
		# Wraps Client#scrape_index; see it for documentation.
		def get_global_listing **opts
			scrape_index "/r/teslore/wiki/compilation", opts
		end

		# Public: Scrapes a Weekly Community Thread patch index.
		#
		# Wraps Client#scrape_index; see it for documentation.
		def get_weekly_listing id, **opts
			id = "/by_id/t3_#{id}" unless id.match /^t3_/
			scrape_index id, opts
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
				"/by_id/t3_#{m[:id]}" if m
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

		private

		# Internal: Governs the actual functionality of the index scrapers.
		#
		# path - The reddit API or path being queried. It can be a post ID/fullname
		# or a full URI.
		#
		# Optional parameters:
		#
		# css: The CSS selector string used to get the links referenced on the page.
		#
		# Returns an array of all the referenced links. These links will need to be
		# broken down into reddit fullnames before Hermaeus can download them.
		def scrape_index path, **opts
			# This is a magic string that targets the index format /r/teslore uses to
			# enumerate their Compendium, in the wiki page and weekly patch posts.
			query = opts[:css] || "td:first-child a"
			# Reddit will respond with an HTML dump, if we are querying a wiki page,
			# or a wrapped HTML dump, if we are querying a post.
			fetch = @client.get(path).body
			# Set fetch to be an array of hashes which have the desired text as a
			# direct child.
			if fetch[:kind] == "wikipage"
				fetch = [fetch[:data]]
			elsif fetch[:kind] == "Listing"
				fetch = fetch[:data][:children].map { |c| c[:data] }
			end
			# reddit will put the text data in :content_html if we queried a wikipage,
			# or :selftext_html if we queried a post. The two keys are mutually
			# exclusive, so this simply looks for both and remaps fetch items to point
			# to the actual data.
			[:content_html, :selftext_html].each do |k|
				fetch.map! do |item|
					item[k] if item.has_key? k
				end
			end
			# Ruby doesn't like having comments between each successive map block.
			# This sequence performs the following transformations on each entry in
			# the fetched list.
			# 1. Unescape the HTML text.
			# 2. Process the HTML text into data structures.
			# 3. Run CSS queries on the data structures to find the links sought.
			# 4. Unwrap the link elements to get the URI at which they point.
			# 5. In the event that multiple pages were queried to get data, the array
			# that each of those queries returns is flattened so that this method only
			# returns one single array of link URIs.
			fetch.map do |item|
				@html_filter.decode(item)
			end
			.map do |item|
				Nokogiri::HTML(item)
			end
			.map do |item|
				item.css(query)
			end
			.map do |item|
				item.attributes["href"].value
			end
			.flatten
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
