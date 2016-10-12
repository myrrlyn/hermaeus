module Hermaeus
	# Public: Data structure describing a Compendium entry.
	class Apocryphon
		# Public: Constructs an Apocryphon from reddit data responses.
		#
		# data - A Hash emitted by Client#get_posts
		def initialize data
			@data = data
		end

		# Public: Serializes the Apocryphon item to a string.
		#
		# Returns a String containing the title and author.
		def to_s
			"#{self.title} – by #{self.author}"
		end

		# Public: Permit method-style access to the underlying data Hash's keys.
		def method_missing name, *args, &block
			@data[name.to_sym]
		end

		# Public: Accessor for the Apocryphon's Markdown text.
		def text
			@data[:selftext]
		end

		# Public: Accessor for the Apocryphon's HTML as compiled by reddit.
		def html
			data[:selftext_html]
		end
	end
end
