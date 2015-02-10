require 'webradio'
require 'niconico'
require 'pit'
require 'pathname'
require 'open-uri'
require 'rss'

class Nicovideo < WebRadio
	def initialize(url)
		account = Pit::get('nicovideo', :require => {
			:id => 'your nicovideo id',
			:pass => 'your nicovideo password'
		})
		@nico = Niconico.new(account[:id], account[:pass])
		@nico.login
		super
	end

	def download(name)
		rss = RSS::Parser.parse(@url)
		item = rss.items.first
		player_url = item.link
		video = @nico.video(Pathname(URI(player_url).path).basename.to_s)
		serial = video.title.scan(/(?:[#第]| EP)(\d+)|/).flatten.compact[0].to_i
		@file = "#{name}##{'%02d' % serial}.#{video.type}"
		if File.exist? @file
			puts "'#{@file}' is existent. skipped."
			return
		end

		print "getting #{serial}..."
		open(@file, 'wb:ASCII-8BIT') do |o|
			video.get_video do |body|
				print '.'
				o.write(body)
			end
		end
		puts "done."
	end

	def mp3ize
		mp3_convert(@file, @file.sub(/\....$/, '.mp3'))
	end

private
end
