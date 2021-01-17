require 'open-uri'
require 'json'


class Youtube < WebRadio
    def initialize(params, options)
		super
        @offset = 0
        @target_content = []
	end

    private

    def youtube_download(mp4_url, mp4_file, mp3_file)
        begin
            mp3nize(mp4_file, mp3_file) do
                loop do
                    print '.'
                    _, err, status = Open3.capture3("youtube-dl -f mp4 -o '#{mp4_file}' --netrc '#{mp4_url}'")
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

    def first_video(html)
        json_str = html.scan(/ytInitialData = (.*);<\/script>/).flatten.first
        json = JSON.parse(json_str)
        contents = json.dig(*@target_content)
        yield contents.first
    end

    def serial_file(title, label, serial, ext)
        if serial > 0
            "#{@label}##{serial}.#{ext}"
        else
            "#{title}.#{ext}"
        end
    end
end

class YoutubePlaylist < Youtube

    def initialize(params, options)
		super
		@target_content = ["contents", "twoColumnBrowseResultsRenderer", "tabs", 0, "tabRenderer", "content", "sectionListRenderer", "contents", 0, "itemSectionRenderer", "contents", 0, "playlistVideoListRenderer", "contents"].freeze
	end

    def download
        first_video(URI.open(@url).read) do |content|
            item = content['playlistVideoRenderer']
            @cover = item['thumbnail']['thumbnails'].last['url']
            title = item['title']['runs'][0]['text']
            serial = title.scan(/\d+/).first.to_i
            url = "https://www.youtube.com#{item["navigationEndpoint"]["commandMetadata"]["webCommandMetadata"]["url"]}"

            mp4_file = serial_file title, @label, serial, 'mp4'
            mp3_file = serial_file title, @label, serial, 'mp3'

            youtube_download url, mp4_file, mp3_file
        end
    end
end

class YoutubeChannel < Youtube
	def initialize(params, options)
        super
        @target_content = ['contents', 'twoColumnBrowseResultsRenderer', 'tabs', 1, 'tabRenderer', 'content', 'sectionListRenderer', 'contents', 0, 'itemSectionRenderer', 'contents', 0, 'gridRenderer', 'items'].freeze
    end

    def download
        first_video(URI.open(@url).read) do |content|
            item = content['gridVideoRenderer']
            @cover = item['thumbnail']['thumbnails'].last['url']
            title = item['title']['runs'][0]['text']
            serial = title.scan(/\d+/).first.to_i
            url = "https://www.youtube.com#{item['navigationEndpoint']['commandMetadata']['webCommandMetadata']['url']}"

            mp4_file = serial_file title, @label, serial, 'mp4'
            mp3_file = serial_file title, @label, serial, 'mp3'

            youtube_download url, mp4_file, mp3_file
        end
    end
end
