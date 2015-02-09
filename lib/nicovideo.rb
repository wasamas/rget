require 'webradio'
require 'mechanize'
require 'pit'
require 'pathname'
require 'open-uri'
require 'rss'

class NicovideoAPI
	def initialize(id, pw)
		@agent = Mechanize::new
		@id, @pw = id, pw
	end

	def login(id, pw)
		@agent.get('https://account.nicovideo.jp/login')
		@agent.page.forms[0].tap do |form|
			form.mail_tel = id
			form.password = pw
			form.click_button
		end
	end

	def metainfo(player_url)
		uri = "http://ext.nicovideo.jp/api/getthumbinfo/#{video_id(player_url)}"
		@agent.get(uri)
		xml = @agent.page.body
		xml.scan(%r|<thumb>(.*)</thumb>|m).flatten.first.scan(%r|<(.*?)>(.*)</.*?>|).to_h
	end

	def video_url(player_url)
		begin
			@agent.get(player_url)
			res = @agent.get("http://flapi.nicovideo.jp/api/getflv/#{video_id(player_url)}")
			raise StandardError.new if res.response['x-niconico-authflag'].to_i == 0
			CGI.unescape res.body.scan(/(.*?)=(.*?)[&$]/).to_h['url']
		rescue
			login(@id, @pw)
			retry
		end
	end

	def download_video(video_url)
		cookies = @agent.cookie_jar.cookies('http://nicovideo.jp').map{|c|c.to_s}.join(';')
		uri = URI(video_url)
		http = Net::HTTP.new(uri.host, uri.port)
		http.request_get(uri.request_uri, 'Cookie' => cookies) do |res|
			res.read_body do |body|
				yield body
			end
		end
	end

private
	def video_id(player_url)
		Pathname(URI(player_url).path).basename.to_s
	end
end

class Nicovideo < WebRadio
	def initialize(url)
		account = Pit::get('nicovideo', :require => {
			:id => 'your nicovideo id',
			:pass => 'your nicovideo password'
		})
		@nicovideo = NicovideoAPI.new(account[:id], account[:pass])
		super
	end

	def download(name)
		rss = RSS::Parser.parse(@url)
		item = rss.items.first
		player_url = item.link
		type = @nicovideo.metainfo(player_url)['movie_type']
		serial = item.title.scan(/#(\d+)/).flatten[0].to_i
		@file = "#{name}##{'%03d' % serial}.#{type}"
		if File.exist? @file
			puts "'#{@file}' is existent. skipped."
			return
		end

		print "getting #{serial}..."
		open(@file, 'wb:ASCII-8BIT') do |o|
			video_url = @nicovideo.video_url(player_url)
			@nicovideo.download_video(video_url) do |body|
				print '.'
				o.write(body)
			end
		end
		puts "done."
	end

	def mp3ize
		mp3_convert(@file, @file.sub(/\....$/, '.mp3'))
	end

private
end
