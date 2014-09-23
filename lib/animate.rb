# encoding: utf-8

require 'uliza'

class Animate < Uliza
	def download(name)
		uliza_download(name, open(@url, 'User-Agent' => 'iPhone', &:read), /(?:活動|第)(\d+)(?:週目『|回 「)/, %r|src="(http://www2.uliza.jp/IF/iphone/iPhonePlaylist.m3u8.*?)"|)
	end
end

