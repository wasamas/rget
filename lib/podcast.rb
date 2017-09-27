# encoding: utf-8

require 'rss'

class Podcast
	def initialize(url, options)
		@url = url
		@options = options
		yield self if block_given?
	end

	def download
		rss = RSS::Parser.parse(@url)
		label = @label || rss.channel.title
		episode = rss.items.first
		serial = episode.link.scan(%r|\d+[^/\.]*|).flatten.first
		if serial.to_i > 2000 # may be year
			serial = episode.pubDate.strftime('%Y%m%d')
		end
		unless serial
			puts "fail: recent episode not found."
			return
		end

		file = "#{label}##{serial}.mp3"
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

