#!/usr/bin/env ruby

require 'open-uri'

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

html = open('http://hibiki-radio.jp/description/idolmaster', &:read)
serial = html.scan(/更新！ #(\d+)/).flatten.first
m3u_meta2 = html.scan(%r|href="(http://www2.uliza.jp/IF/iphone/iPhonePlaylist.m3u8\?.*?)"|).flatten.first
print "getting #{serial}"

m3u_meta1 = open(m3u_meta2, &:read)
m3u = m3u_meta1.scan(/^[^#].*/).first
save_m4a(URI(m3u), "アイスタ##{serial}.m4a")
puts "done."
