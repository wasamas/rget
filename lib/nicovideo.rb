require 'webradio'
require 'niconico'
require 'pit'
require 'pathname'
require 'open-uri'
require 'rss'

class Nicovideo < WebRadio
	def initialize(url, options)
		account = Pit::get('nicovideo', :require => {
			:id => 'your nicovideo id',
			:pass => 'your nicovideo password'
		})
		@nico = Niconico.new(account[:id], account[:pass])
		@nico.login
		super
	end

	def download(name)
		begin
			player_url = get_player_url(@url)
		rescue NoMethodError
			raise DownloadError.new('video not found')
		end

		video = @nico.video(Pathname(URI(player_url).path).basename.to_s)
		serial = video.title.scan(/(?:[#第]|[ 　]EP|track-)(\d+)|/).flatten.compact[0].to_i
		appendix = video.title =~ /おまけ|アフタートーク/ ? 'a' : ''
		@file = "#{name}##{'%02d' % serial}#{appendix}.#{video.type}"
		@mp3_file = @file.sub(/\....$/, '.mp3')
		mp3nize(@file, @mp3_file) do
			open(@file, 'wb:ASCII-8BIT') do |o|
				begin
					video.get_video do |body|
						print '.'
						o.write(body)
					end
				rescue Niconico::Video::VideoUnavailableError => e
					raise DownloadError.new(e.message)
				end
			end
		end
	end

private
	def get_player_url(list_url)
		begin
			rss = RSS::Parser.parse(list_url)
			item = rss.items.first
			return item.link
		rescue RSS::NotWellFormedError
			html = open(list_url, &:read)
			url = html.scan(%r|/watch/[\w]+|).first
			raise WebRadio::DownloadError.new('video not found in this pege') unless url
			return "http://www.nicovideo.jp#{url}"
		end
	end
end
