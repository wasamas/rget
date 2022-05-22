# encoding: utf-8

require 'hls'
require 'nokogiri'
require 'json'

class Onsen < HLS
	HEADERS = {
		"Referer" => 'https://www.onsen.ag/'
	}

	def initialize(params, options)
		super
		@cover = "//*[@class='newest-content--left']//img[1]/@src" unless @cover
	end

	def download
		html = URI.open(@url, HEADERS, &:read)
		serial = Nokogiri(html).css('.play-video-info td')[0].text.scan(/\d+/)[0].to_i
		m3u8 = JSON.parse(html.scan(%r|("https:[^:]*?.m3u8")|).flatten.last)
		hls_download(@label, serial, m3u8, HEADERS)
	end

	def dump
		tag = Pathname(@url).basename.to_s.gsub(%r|[-/]|, '_')
		html = Nokogiri(URI.open(@url, HEADERS, &:read))
		title = html.css('h3')[0].text
		return {
			tag => {
				'desc' => title,
				'url' => @url,
				'label' => tag
			}
		}
	end
end
