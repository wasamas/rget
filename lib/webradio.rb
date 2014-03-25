# encoding: utf-8

require 'open-uri'
require 'nokogiri'

class WebRadio
	def initialize(url)
		@url = url
		yield self if block_given?
	end

	def download(name)
		case @url
		when %r[^http://hibiki-radio\.jp/]
			hibiki(name, open(@url, &:read))
		when %r[^http://sp\.animate\.tv/]
			animate(name, open(@url, 'User-Agent' => 'iPhone', &:read))
		when %r[^http://onsen\.ag/program/]
			onsen(name, @url.scan(%r|/([^/]*)/$|).flatten.first)
		end
		self
	end

	def mp3ize
		mp3_file = @m4a_file.sub(/\.m4a$/, '.mp3')
		if File.exist? mp3_file
			puts "'#{mp3_file}' is existent. skipped."
			return self
		end
		system "ffmpeg -i #{@m4a_file} -ab 128k #{mp3_file}"
		self
	end

private
	def hibiki(name, html)
		independent_download(name, html, /更新！ #(\d+)/, %r|href="(http://www2.uliza.jp/IF/iphone/iPhonePlaylist.m3u8\?.*?)"|)
	end

	def animate(name, html)
		independent_download(name, html, /(?:活動|第)(\d+)(?:週目|回)/, %r|src="(http://www2.uliza.jp/IF/iphone/iPhonePlaylist.m3u8.*?)"|)
	end

	def onsen(name, program_id)
		html = Nokogiri(open('http://onsen.ag/', 'User-Agent' => 'iPhone', &:read))
		serial = html.css("##{program_id}").text.scan(/#(\d+)/).flatten.first
		mp3_url = html.css('form[target=_self]').select {|form|
			form.attr('action') =~ %r[/#{program_id}\d+\.mp3]
		}.first.attr('action')
		mp3_file = "#{name}##{serial}.mp3"
		if File.exist? mp3_file
			puts "'#{mp3_file}' is existent. skipped."
			return
		end
		print "getting #{serial}..."
		open(mp3_file, 'wb:ASCII-8BIT') do |mp3|
			mp3.write open(mp3_url, 'rb:ASCII-8BIT', &:read)
		end
		puts "done."
	end

	def independent_download(name, html, serial_pattern, m3u_pattern)
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
