require 'webradio'

class SeasideCommnunications < WebRadio
	def mp3ize
		mp3_convert(@wma_file, @wma_file.sub(/\.wma$/, '.mp3'))
	end

	def download(name)
		html = open(@url, &:read)
		playlist_url, serial = html.scan(%r[(http:.*?\_(\d+).wax)]).flatten
		unless playlist_url
			puts "fail: recent radio program not found."
			exit -1
		end
		serial = serial.to_i

		playlist = open(playlist_url, &:read)
		wma_url, = playlist.scan(%r[http://.*?\.wma])

		@wma_file = "#{name}##{serial}.wma"
		if File.exist? @wma_file
			puts "'#{@wma_file}' is existent. skipped."
			return
		end

		print "getting #{serial}..."
		open(@wma_file, 'wb:ASCII-8BIT') do |wma|
			wma.write(open(wma_url, &:read))
		end
		puts "done."
		self
	end
end

