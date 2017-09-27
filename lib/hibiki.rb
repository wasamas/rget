# encoding: utf-8

require 'webradio'
require 'mechanize'
require 'json'
require 'uri'
require 'openssl'

class Hibiki < WebRadio
	def initialize(url, options)
		super
		@url = @url.sub(%r|/detail\Z|, '')
	end

	def download
		hibiki_download(@label, Pathname(@url).basename.to_s)
	end

	def dump
		tag = Pathname(@url).basename.to_s.gsub(%r|[-/]|, '_')
		agent = Mechanize.new
		media_info = hibiki_media_info(agent, tag)

		return {
			tag => {
				'desc' => media_info[:name],
				'url' => @url,
				'label' => tag
			}
		}
	end

private
	def header
		{'X-Requested-With' => 'XMLHttpRequest'}
	end

	def hibiki_media_info(agent, program_id)
		agent.request_headers = header
		json = agent.get("https://vcms-api.hibiki-radio.jp/api/v1/programs/#{program_id}").body
		JSON.parse(json, symbolize_names: true)
	end

	def find_cover(media_info)
		media_info[:episode][:episode_parts].map{|s|s[:pc_image_url]}.reject(&:empty?)[0]
	end

	def hibiki_download(name, program_id)
		begin
			agent = Mechanize.new
			media_info = hibiki_media_info(agent, program_id)
			@cover = find_cover(media_info) unless @cover
			serial = media_info[:episode][:name].scan(/([\d\.]+)/).flatten.first
			video_id = media_info[:episode][:video][:id]

			video_info = JSON.parse(agent.get("https://vcms-api.hibiki-radio.jp/api/v1/videos/play_check?video_id=#{video_id}").body,{:symbolize_names => true})
			playlist_url = video_info[:playlist_url]
			m3u8_url = agent.get(playlist_url).body.scan(/http.*/).flatten.first

			base_url = URI.parse(m3u8_url)
			base_path = File.dirname(base_url.path)

			m3u8 = agent.get(m3u8_url).body
			key_url = m3u8.scan(/URI="(.*)"/).flatten.first

			tses = m3u8.scan(/ts_.*\.ts/)
			key = agent.get_file(key_url)
			iv = m3u8.scan(/IV=0x(.*)$/).flatten.pack("H*")
		rescue NoMethodError
			$stderr.puts $!
			raise NotFoundError.new("no radio program in #{program_id}.")
		end

		ts_file = "#{name}##{serial}.ts"
		mp3_file = "#{name}##{serial}.mp3"

		decoder = OpenSSL::Cipher.new('aes-128-cbc')
		decoder.key = key
		decoder.iv = iv

		decoder.decrypt

		mp3nize(ts_file, mp3_file) do
			open(ts_file, 'wb:ASCII-8BIT') do |ts|
				tses.each do |file|
					base_url.path = "#{base_path}/#{file}"
					ts.write(decoder.update(agent.get_file(base_url)))
				end
				ts.write(decoder.final)
			end
		end
	end
end
