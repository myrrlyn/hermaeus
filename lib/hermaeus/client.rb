%w[
	htmlentities
	nokogiri
	redd
].each(&method(:require))

include Enumerable

require "hermaeus/config"
require "hermaeus/version"

module Hermaeus
	# Public: Wraps a reddit client for access to reddit's API, and provides
	# methods for downloading posts from reddit.
	class Client
		USER_AGENT = "Redd/Ruby:Hermaeus:#{Hermaeus::VERSION} (by /u/myrrlyn)"
		# Public: Connects the Hermaeus::Client to reddit.
		def initialize
			Config.validate!
			cfg = Config.info[:client]
			@client = Redd.it(:script, *cfg.values, user_agent: USER_AGENT)
			@client.authorize!
			@html_filter = HTMLEntities.new
		end

		# Public: Scrapes the Compilation full index.
		#
		# Wraps Client#scrape_index; see it for documentation.
		def get_global_listing
			scrape_index Config.info.dig :index, :path
		end

		# Public: Scrapes a Weekly Community Thread patch index.
		#
		# ids - A String Array of reddit post IDs for Weekly Community Threads.
		#
		# Examples:
		#
		# get_weekly_listing "56j7pq" # Targets one Community Thread
		# get_weekly_listing "56j7pq", "55erkr" # Targets two Community Threads
		# get_weekly_listing "55erkr", css: "td:last-child a" # Custom CSS selector
		#
		# Wraps Client#scrape_index; see it for documentation.
		def get_weekly_listing ids, **opts
			ids.map! do |id|
			 "t3_#{id}" unless id.match /^t3_/
			end
			# TODO: Ensure that this is safe (only query <= 100 IDs at a time), and
			# call the scraper multiple times and reassemble output if necessary.
			query = "/by_id/#{ids.join(",")}"
			scrape_index query
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
			# TODO: Move this regex to the configuration file.
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
		def get_posts fullnames, &block
			ret = []
			# reddit has finite limits on acceptable query sizes. Split the list into
			# manageable portions
			fullnames.each_slice(100).each do |chunk|
				# Assemble the list of reddit objects being queried
				query = "/by_id/#{chunk.join(",")}.json"
				response = scrape_posts query, &block
				ret << response.body
			end
			ret
		end

		private

		# Internal: Governs the actual functionality of the index scrapers.
		#
		# path - The reddit API or path being queried. It can be a post ID/fullname
		# or a full URI.
		#
		# Returns an array of all the referenced links. These links will need to be
		# broken down into reddit fullnames before Hermaeus can download them.
		def scrape_index path
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
					if item.respond_to?(:has_key?) && item.has_key?(k)
						item[k]
					else
						item
					end
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
				item.css(Config.info.dig :index, :css).map do |item|
					item.attributes["href"].value
				end
			end
			.flatten
		end

		# Internal: Provides the actual functionality for collecting posts.
		#
		# query - The reddit API endpoint or path being queried.
		# opts - Options for the reddit API call
		# block - This method yields each post fetched to its block.
		# tries - hidden parameter used to prevent infinite stalling on rate limits.
		#
		# Returns reddit's response to the query.
		def scrape_posts query, tries = 0, **opts, &block
			begin
				# Ask reddit to procure our items
				response = @client.get(query, opts)
				if response.success?
					payload = response.body
					# The payload should be a Listing even for a single-item query; the
					# :children array will just have one element.
					if payload[:kind] == "Listing"
						payload[:data][:children].each do |item|
							yield item[:data]
						end
					end
					return response
				end
			# If at first you don't succeed...
			rescue Redd::Error::RateLimited => e
				sleep e.time + 1
				# Try try again.
				if tries < 3
					scrape_posts query, tries + 1
				else
					raise RuntimeError, "reddit rate limit will not unlock"
				end
			end
		end
	end
end
