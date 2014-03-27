# encoding: utf-8

require 'uliza'

class Hibiki < Uliza
	def download(name)
		uliza_download(name, open(@url, &:read), /更新！ #(\d+)/, %r|href="(http://www2.uliza.jp/IF/iphone/iPhonePlaylist.m3u8\?.*?)"|)
	end
end
