require 'open-uri'
require 'json'

class Youtube < WebRadio
	def initialize(params, options)
		super
		@offset = 0
	end

    def download
        html = URI.open(@url).read
        json_str = html.scan(/ytInitialData = (.*);<\/script>/).flatten.first
        json = JSON.parse(json_str)
        File.open("debug.log", "w") do |f|
            f.puts JSON.pretty_generate(json)
        end
        title = json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"][0]["tabRenderer"]["content"]["sectionListRenderer"]["contents"][0]["itemSectionRenderer"]["contents"][0]["playlistVideoListRenderer"]["contents"][0]["playlistVideoRenderer"]["title"]["runs"][0]["text"]
        @cover = json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"][0]["tabRenderer"]["content"]["sectionListRenderer"]["contents"][0]["itemSectionRenderer"]["contents"][0]["playlistVideoListRenderer"]["contents"][0]["playlistVideoRenderer"]["thumbnail"]["thumbnails"].last["url"]
        mp4_url = "https://www.youtube.com#{json["contents"]["twoColumnBrowseResultsRenderer"]["tabs"][0]["tabRenderer"]["content"]["sectionListRenderer"]["contents"][0]["itemSectionRenderer"]["contents"][0]["playlistVideoListRenderer"]["contents"][0]["playlistVideoRenderer"]["navigationEndpoint"]["commandMetadata"]["webCommandMetadata"]["url"]}"
        serial = title.scan(/[0-9]+/).first

        mp4_file = "#{@label}##{serial}.mp4"
        mp3_file = "#{@label}##{serial}.mp3"
        begin
            mp3nize(mp4_file, mp3_file) do
                loop do
                    print '.'
                    _, err, status = Open3.capture3("youtube-dl -f mp4 -o #{mp4_file} --netrc '#{mp4_url}'")
                    break if status == 0
                    next if err =~ /403: Forbidden/
                    raise ForbiddenError.new("Could not access to #{mp4_url}") if err =~ /TypeError|AssertionError/
                    raise DownloadError.new(err)
                end
            end
		rescue ForbiddenError
			puts "#{$!.message}, try next."
			@offset += 1
			retry
		rescue NotFoundError
			raise DownloadError.new('video not found')
        end
    end
end
