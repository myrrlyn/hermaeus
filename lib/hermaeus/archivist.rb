require "hermaeus/config"

module Hermaeus
	class Archivist
		def initialize
			@html_filter = HTMLEntities.new
			@config = Config.load[:archive]
			FileUtils.mkdir_p @config[:path]
		end

		def add_metadata apoc
			str = <<-EOS
---
author: #{apoc.author}
title: #{apoc.title}
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
			.split("\n").map do |line|
				# Put the newline back in
				line << "\n"
				break_line line
			end
			.join
		end

		private

		def break_line line, length: 80
			if line.length > length + 1
				left, right = line[0...length], line[length...line.length]
				cut = left.rindex " "
				if cut
					left, right = line[0...cut] << "\n", line[(cut + 1)...line.length]
				end
				right = break_line right, length: length
				line = left.concat right
			end
			line
		end
	end
end
