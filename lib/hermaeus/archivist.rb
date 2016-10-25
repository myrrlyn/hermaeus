require "hermaeus/config"

module Hermaeus
	class Archivist
		# Public: Initializes the Archivist.
		def initialize
			Hermaeus.log.info "Initializing the Archivist..."
			@html_filter = HTMLEntities.new
			Config.validate!
			@config = Config.info[:archive]
			FileUtils.mkdir_p @config[:path]
		end

		def add_metadata apoc
			<<-EOS
---
author: #{apoc.author}
title: #{@html_filter.decode(apoc.title)}
date: #{Time.at(apoc.created.to_i).iso8601}
reddit: #{apoc.id}
---

			EOS
		end

		def save_to_file apoc
			unless apoc.text == "[deleted]" || apoc.text == "[removed]"
				title = @html_filter.decode(title)
				title = apoc.title.downcase.gsub(/[ \/]/, "_").gsub(/[:"',]/, "")
				title << ".html.md"
				File.open(File.join(@config[:path], title), "w+") do |file|
					file << add_metadata(apoc)
					file << prettify(apoc.text)
				end
			end
		end

		def prettify text, length: 80
			@html_filter.decode(text)
			.split("\n")
			.map do |line|
				# Put the newline back in
				line << "\n"
				break_line line, length
			end
			.join
		end

		private

		def break_line line, length
			if line.length > length + 1
				left, right = line[0...length], line[length...line.length]
				cut = left.rindex " "
				if cut
					left, right = line[0...cut] << "\n", line[(cut + 1)...line.length]
				end
				right = break_line right, length
				line = left.concat right
			end
			line
		end
	end
end
