# encoding: utf-8

require 'rss'

class Podcast
	def initialize(url)
		@url = url
		yield self if block_given?
	end

	def download(name = nil)
		rss = RSS::Parser.parse(@url)
		name = rss.channel.title unless name
		episode = rss.items.first
		serial = episode.link.scan(%r|\d+[^/]*|).flatten.first
		unless serial
			puts "fail: recent episode not found."
			return
		end

		file = "#{name}##{serial}.mp3"
		if File.exist? file
			puts "'#{file}' is existent. skipped."
			return
		end
		print "getting #{serial}..."
		open(file, 'wb:ASCII-8BIT') do |o|
			o.write(open(episode.enclosure.url, 'rb:ASCII-8BIT', &:read))
		end
		puts "done."
	end
end

