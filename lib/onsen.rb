# encoding: utf-8

require 'webradio'
require 'nokogiri'

class Onsen < WebRadio
	def download(name)
		onsen_download(name, @url.scan(%r|/([^/]*)/$|).flatten.first)
	end

private
	def onsen_download(name, program_id)
		html = Nokogiri(open('http://onsen.ag/', 'User-Agent' => 'iPhone', &:read))
		begin
			serial = html.css("##{program_id}").text.scan(/#(\d+)/).flatten.first
			mp3_url = html.css('form[target=_self]').select {|form|
				form.attr('action') =~ %r[/#{program_id}\w+\.mp3]
			}.first.attr('action')
		rescue NoMethodError
			raise NotFoundError.new("no radio program in #{program_id}.")
		end
		mp3_file = "#{name}##{serial}.mp3"
		mp3ize(mp3_file, mp3_file, false) do
			open(mp3_file, 'wb:ASCII-8BIT') do |mp3|
				mp3.write open(mp3_url, 'rb:ASCII-8BIT', &:read)
			end
		end
	end
end
