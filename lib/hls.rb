require 'webradio'
require 'open3'

class HLS < WebRadio
private
	def hls_download(name, serial, m3u_meta)
		mp4_file = "#{name}##{serial}.mp4"
		mp3_file = "#{name}##{serial}.mp3"
		m3u = URI.open(m3u_meta, &:read).scan(/^[^#].*/).first
		m3u = Pathname(m3u_meta).dirname.join(m3u) if Pathname(m3u).relative?
		mp3nize(mp4_file, mp3_file) do
			result = Open3.capture3(%Q[ffmpeg -loglevel error -protocol_whitelist file,http,https,tcp,tls,crypto -i "#{m3u}" "#{mp4_file}"])
			unless result[2].to_i == 0
				raise WebRadio::DownloadError.new("failed download the radio program (#{@label}).")
			end
		end
	end
end

