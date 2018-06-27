require 'open-uri'
require 'nokogiri'
require 'mechanize'

class AsobiStore < WebRadio
	def initialize(params, options)
		super
		@offset = 0
	end

	def download
		list = Nokogiri(open(@url).read)
		program = list.css('.list-main-product a.wrap').first.attr('href')
		content = Nokogiri(open("https://asobistore.jp#{program}").read)
		player = content.css('iframe').last.attr('src')
		html = Nokogiri(open("https:#{player}").read)
		src_m3u8 = html.css('source').first.attr('src')
		m3u8 = "#{File.dirname(src_m3u8)}/#{open(src_m3u8).read.match(/^[^#].*/)[0]}"

		serial = html.title.scan(/#(\d+)/).flatten.first.to_i
		@cover = "https:#{html.css('audio').first.attr('poster')}" unless @cover
		ts_file = "#{@label}##{serial}.ts"
		mp3_file = "#{@label}##{serial}.mp3"

		begin
			agent = Mechanize.new
			agent.get(m3u8)
			body = agent.page.body
		rescue ArgumentError
			body = open(m3u8, &:read)
		end
		tses = body.scan(/.*\.ts.*/)
		key_url = body.scan(/URI="(.*)"/).flatten.first

		if key_url
			key = agent.get_file(key_url)
			decoder = OpenSSL::Cipher.new('aes-128-cbc')
			decoder.key = key
			decoder.decrypt
		else
			decoder = ''
			def decoder.update(s); return s; end
		end

		mp3nize(ts_file, mp3_file) do
			open(ts_file, 'wb:ASCII-8BIT') do |ts|
				tses.each_with_index do |file, count|
					print "." if count % 10 == 0
					ts.write(decoder.update(agent.get_file(file)))
				end
				ts.write(decoder.final)
			end
		end
	end
end
