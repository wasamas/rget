require 'open-uri'
require 'json'

class Himalaya < WebRadio
	def initialize(params, options)
		super
		@offset = 0
	end

	def download
		html = open(@url).read
		json_str = html.scan(/__NEXT_DATA__ = (.*)/).flatten.first
		json = JSON.parse(json_str)
		tracks = json['props']['seo']['albumData']['data']['tracks']['list']
		track = tracks[@offset]

		m4a_url = track['playPathAacv164']
		serial = Time.at(track['createdAt']/1000).strftime('%Y%m%d')
		@cover ||= track['coverLarge']

		m4a_file = "#{@label}##{serial}.m4a"
		mp3_file = "#{@label}##{serial}.mp3"
		mp3nize(m4a_file, mp3_file) do
			open(m4a_file, 'wb:ASCII-8BIT') do |m4a|
				m4a.write(open(m4a_url).read)
			end
		end
	end
end
