require 'webradio'
require 'niconico'
require 'pit'
require 'pathname'
require 'open-uri'
require 'rss'

class Nicovideo < WebRadio
	def initialize(params, options)
		account = Pit::get('nicovideo', :require => {
			:id => 'your nicovideo id',
			:pass => 'your nicovideo password'
		})
		@nico = Niconico.new(account[:id], account[:pass])
		@nico.login
		super
	end

	def download
		begin
			video = get_video(@url)
		rescue NoMethodError
			raise DownloadError.new('video not found')
		end
		@cover = thumbinfo(video, 'thumbnail_url') unless @cover
		title = video.title || thumbinfo(video, 'title') || video.id
		title.tr!('０-９', '0-9')
		serial = title.scan(/(?:[#第]|[ 　]EP|track-)(\d+)|/).flatten.compact[0].to_i
		if serial == 0
			tmp = title.scan(/\d+/).last.to_i
			serial = tmp if tmp > 0
		end
		appendix = title =~ /おまけ|アフタートーク/ ? 'a' : ''
		@file = "#{@label}##{'%02d' % serial}#{appendix}.#{video.type}"
		@mp3_file = @file.sub(/\....$/, '.mp3')
		mp3nize(@file, @mp3_file) do
			loop do
				print '.'
				_, err, status = Open3.capture3("youtube-dl -f mp4 -o #{@file} --netrc #{video.url}")
				break if status == 0
				raise DownloadError.new(err) unless err =~ /403: Forbidden/
			end
		end
	end

	def dump
		begin
			tag = Pathname(@url).basename.to_s.gsub(%r|[-/]|, '_')
			rss_url = "#{@url}/video?rss=2.0"
			desc = RSS::Parser.parse(rss_url).channel.dc_creator
			return {
				tag => {
					'desc' => desc,
					'url' => rss_url,
					'label' => tag
				}
			}
		rescue RSS::NotWellFormedError
			raise
		end
	end

private
	def get_video(list_url)
		video_url = nil
		offset = 0
		begin
			begin
				rss = RSS::Parser.parse(list_url)
				item = rss.items[offset]
				video_url = item.link
			rescue RSS::NotWellFormedError
				html = open(list_url, &:read)
				url = html.scan(%r|/watch/[\w]+|)[offset]
				raise WebRadio::DownloadError.new('video not found in this pege') unless url
				video_url = "http://www.nicovideo.jp#{url}"
			end
			video = @nico.video(Pathname(URI(video_url).path).basename.to_s)
		rescue Net::HTTPForbidden, Mechanize::ResponseCodeError
			offset += 1
			retry
		end
	end

	def thumbinfo(video, elem = nil)
		xml = open("http://ext.nicovideo.jp/api/getthumbinfo/#{video.id}").read
		if elem
			return xml.scan(%r|<#{elem}>(.*)</#{elem}>|m).flatten.first
		else
			return xml
		end
	end
end
