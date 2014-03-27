require 'webradio'

class Uliza < WebRadio
	def mp3ize
		mp3_convert(@m4a_file, @m4a_file.sub(/\.m4a$/, '.mp3'))
	end

private
	def uliza_download(name, html, serial_pattern, m3u_pattern)
		serial = html.scan(serial_pattern).flatten.first
		@m4a_file = "#{name}##{serial}.m4a"
		if File.exist? @m4a_file
			puts "'#{@m4a_file}' is existent. skipped."
			return
		end

		m3u_meta2 = html.scan(m3u_pattern).flatten.first
		unless m3u_meta2
			puts "fail: recent radio program not found."
			exit -1
		end
		print "getting #{serial}"

		m3u_meta1 = open(m3u_meta2, &:read)
		m3u = m3u_meta1.scan(/^[^#].*/).first
		save_m4a(URI(m3u), @m4a_file)
		puts "done."
		self
	end

	def get_m4a(uri_playlist)
		open(uri_playlist).each_line do |l|
			next if /^#/ =~ l
			l.chomp!
			print "."
			yield open(uri_playlist + l, 'r:ASCII-8BIT', &:read)
		end
	end
	
	def save_m4a(uri_playlist, m4a_file)
		open(m4a_file, 'wb:ASCII-8BIT') do |m4a|
			get_m4a(uri_playlist) do |part|
				m4a.write part
			end
		end
	end
end

