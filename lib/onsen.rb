# encoding: utf-8

require 'webradio'
require 'nokogiri'

class Onsen < WebRadio
	def initialize(params, options)
		super
		@cover = "//*[@id='newProgramWrap']//img[1]/@src" unless @cover
	end

	def download
		onsen_download(@label, @url.scan(%r|/([^/]*)/$|).flatten.first)
	end

	def dump
		tag = Pathname(@url).basename.to_s.gsub(%r|[-/]|, '_')
		html = Nokogiri(open(@url, &:read))
		title = html.css('#outLineWrap h1').text
		return {
			tag => {
				'desc' => title,
				'url' => @url,
				'label' => tag
			}
		}
	end

private
	def onsen_download(name, program_id)
		html = Nokogiri(open('http://onsen.ag/', 'User-Agent' => 'iPhone', &:read))
		begin
			serial = html.css("##{program_id}").text.scan(/#(\d+)/).flatten.first
			mp3_url = html.css('form[target=_self]').select {|form|
				form.attr('action') =~ %r|/#{program_id}\w+\.mp[34]|
			}.first.attr('action')
		rescue NoMethodError
			raise NotFoundError.new("no radio program in #{program_id}.")
		end
		src_file = "#{name}##{serial}#{mp3_url.scan(/\.mp[34]$/).first}"
		mp3_file = "#{name}##{serial}.mp3"
		mp3nize(src_file, mp3_file, false) do
			open(src_file, 'wb:ASCII-8BIT') do |mp3|
				mp3.write open(mp3_url, 'rb:ASCII-8BIT', &:read)
			end
		end
	end
end
