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
		@offset = 0
	end

	def download
		program = File.basename(URI(@url).path)
		html = URI.open(@url, HEADERS, &:read)
		serial = 0
		Nokogiri(html).css('.play-video-info tr').each do |tr|
			begin
				serial = tr.css('td')[0].text.scan(/\d+/)[0].to_i
			rescue NoMethodError
				next # the header of tables
			end
			break unless serial == 0
		end
		m3u8 = html.gsub(%r[\\u002F], '/').scan(%r|"(https:[^:]*?.m3u8)"|).flatten.select{|m|
			m.match(%r|/\d+/#{program}.*?-#{serial}\.mp4|)
		}.first
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
