require 'open-uri'

class WebRadio
	def initialize(url)
		@url = url
	end

	def download(name)
		case @url
		when %r[^http://hibiki-radio\.jp/]
			hibiki(name, open(@url, &:read))
		when %r[^http://sp\.animate\.tv/]
			animate(name, open(@url, 'User-Agent' => 'iPhone', &:read))
		end
	end

private
	def hibiki(name, html)
		independent_download(name, html, /更新！ #(\d+)/, %r|href="(http://www2.uliza.jp/IF/iphone/iPhonePlaylist.m3u8\?.*?)"|)
	end

	def animate(name, html)
		independent_download(name, html, /活動(\d+)週目/, %r|src="(http://www2.uliza.jp/IF/iphone/iPhonePlaylist.m3u8.*?)"|)
	end

	def independent_download(name, html, serial_pattern, m3u_pattern)
		serial = html.scan(serial_pattern).flatten.first
		file = "#{name}##{serial}.m4a"
		if File.exist? file
			puts "'#{file}' is existent. skipped."
			return
		end

		m3u_meta2 = html.scan(m3u_pattern).flatten.first
		print "getting #{serial}"
		
		m3u_meta1 = open(m3u_meta2, &:read)
		m3u = m3u_meta1.scan(/^[^#].*/).first
		save_m4a(URI(m3u), file)
		puts "done."
	end

	def get_m4a(uri_playlist)
		open(uri_playlist).each_line do |l|
			next if /^#/ =~ l
			l.chomp!
			print "."
			yield open(uri_playlist + l, 'r:ASCII-8BIT', &:read)
		end
	end
	
	def save_m4a(uri_playlist, file_m4a)
		open(file_m4a, 'wb:ASCII-8BIT') do |m4a|
			get_m4a(uri_playlist) do |part|
				m4a.write part
			end
		end
	end
end
