require 'webradio'
require 'open-uri'
require 'nokogiri'

class YouTube < WebRadio
	def download(name)
		list = {}
		playlist = Nokogiri(open(@url, &:read))
		playlist.css('#pl-video-list tr').each do |tr|
			title = tr.attr('data-title')
			serial = title.scan(/(?:[#第]| EP)(\d+)|/).flatten.compact[0].to_i
			video_url = tr.css('a').attr('href').to_s
			list[serial] = video_url
		end
		serial = list.keys.sort.last
		@src = "#{name}##{'%02d' % serial}.mp4"
		@dst = "#{name}##{'%02d' % serial}.mp3"
		mp3ize(@src, @dst) do
			player_url = "http://www.youtube.com#{list[serial]}"
     		result = Open3.capture3("viddl-rb -u -q '*:*:mp4' '#{player_url}'")
			video_url = result[0].split.last.chomp
			open(@src, 'wb:ASCII-8BIT') do |o|
				o.write open(video_url, 'r:ASCII-8BIT', &:read)
			end
		end
	end
end
