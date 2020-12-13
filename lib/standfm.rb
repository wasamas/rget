require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'json'

class StandFm < WebRadio
	def initialize(params, options)
		super
		@offset = 0
	end

	def download
		uri = URI(@url)
		html = Nokogiri(uri.open.read)
		episode = uri + html.css('#root a[href^="/episodes/"]').map{|e|e.attr('href')}.uniq[@offset]

		html = episode.open.read
		json = JSON.parse(html.scan(%r[<script>window.__SERVER_STATE__=(.*)</script>]).flatten[0])
		m4a = json['topics'].find{|k,v|v['episodeId'] == File.basename(episode.path)}.last['downloadUrl']

		doc = Nokogiri(html)
		serial = doc.title.scan(/#(\d+)/).flatten.first.to_i
		@cover = doc.css('meta[property="og:image"]').attr('content').text unless @cover
		m4a_file = "#{@label}##{serial}.m4a"
		mp3_file = "#{@label}##{serial}.mp3"

		mp3nize(m4a_file, mp3_file) do
			open(m4a_file, 'wb:ASCII-8BIT') do |w|
				w.write(URI(m4a).open.read)
			end
		end
	end

	def dump
		uri = URI(@url)
		tag = File.basename(uri.path)
		html = Nokogiri(uri.open.read)
		label, = html.css('title').text.split(/ \| /)
		cover = html.css('meta[property="og:image"]').attr('content').text
		return {
			tag => {
				'desc' => label,
				'url' => @url,
				'label' => label,
				'cover' => cover
			}
		}
	end

private
	def find_player(url)
		programs = Nokogiri(URI.open(url).read)
		programs.css('.list-main-product a.wrap').each do |program|
			begin
				return Nokogiri(URI.open("https://asobistore.jp#{program.attr('href')}").read).css('iframe').last.attr('src')
			rescue # access denied because only access by premium members
				next
			end
		end
		raise StandardError.new('movie not found.')
	end
end
