require 'webradio'
require 'nokogiri'
require 'json'

class FreshLive < WebRadio
	def initialize(url, options)
		super
		@archive = URI(File.join(@url + '/archive'))
		@doc = Nokogiri(open(@archive).read).root
	end

	def download
		offset = 0
		begin
			meta = program_meta(program_id(offset))
			serial = meta['data']['title'].scan(/\d+$/).first.to_i
			open("#{@label}##{'%02d' % serial}.ts", 'wb') do |w|
				ts_list(meta['data']['archiveStreamUrl']).each do |u|
					w.write(open(u, 'rb').read)
				end
			end
		rescue OpenURI::HTTPError
			offset += 1
			retry
		end
	end

	def dump
		tag = Pathname(@url).basename.to_s
		meta = JSON.parse(@doc.css('script').first)

		return {
			tag => {
				'desc' => meta['name'],
				'url' => @url,
				'label' => tag
			}
		}
	end

private
	def program_id(offset = 0)
		Pathname(@doc.css('.ProgramTitle a')[offset].attr('href')).basename.to_s
	end

	def program_meta(id)
		JSON.parse(open("https://freshlive.tv/proxy/Programs;id=#{id}").read)
	end

	def ts_list(rate_m3u8)
		ts_m3u8 = open(rate_m3u8).read.each_line.grep_v(/^#/)[1].chomp
		open(URI(rate_m3u8) + ts_m3u8).read.each_line.grep_v(/^#/).map{|u|URI(rate_m3u8) + u.chomp}
	end
end
