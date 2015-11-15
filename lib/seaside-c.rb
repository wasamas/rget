require 'webradio'

class SeasideCommnunications < WebRadio
	def download(name)
		html = open(@url, &:read)
		playlist_url, serial = html.scan(%r[(http:.*?\_(\d+).wax)]).flatten
		unless playlist_url
			raise WebRadio::DownloadError.new("recent radio program not found.")
		end
		serial = serial.to_i

		playlist = open(playlist_url, &:read)
		wma_url, = playlist.scan(%r[http://.*?\.wma])

		@wma_file = "#{name}##{serial}.wma"
		@mp3_file = @wma_file.sub(/\.wma$/, '.mp3')
		mp3nize(@wma_file, @mp3_file) do
			open(@wma_file, 'wb:ASCII-8BIT') do |wma|
				wma.write(open(wma_url, &:read))
			end
		end
	end
end

