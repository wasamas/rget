require 'webradio'
require 'nokogiri'
require 'json'

class FreshLive < WebRadio
	def download
		if URI(@url).path =~ %r|/search/|
			archive = @url
		else
			archive = URI(File.join(@url + '/programs/archive'))
		end

		each_programs(Nokogiri(open(archive).read)) do |meta|
			begin
				serial = meta['data']['title'].scan(/\d+$/).first.to_i
				src = "#{@label}##{'%02d' % serial}.ts"
				dst = src.sub(/\.ts$/, '.mp4')
				if exist?(dst)
					puts "#{dst} is existent, skipped."
					return
				end
				open(src, 'wb') do |w|
					print "getting #{src}..."
					ts_list(meta['data']['archiveStreamUrl']).each do |u|
						print '.'
						w.write(open(u, 'rb').read)
					end
				end
				dst = mp4nize(src)
				puts 'done.'
				move(dst)
				return
			rescue OpenURI::HTTPError
				puts 'try next.'
				next
			rescue
				puts 'fail.'
				$stderr.puts 'faild to convert .ts => .mp4'
				return
			end
		end
		puts 'fail.'
		$stderr.puts 'free program not found.'
	end

	def dump
		u = URI(@url)
		if u.path =~ %r|/search/|
			desc = URI.decode_www_form_component(Pathname(u.path).basename.to_s)
			return {
				'freshlive_search' => {
					'desc' => desc,
					'url' => @url,
					'label' => desc
				}
			}
		else
			tag = Pathname(u.path).basename.to_s
			meta = JSON.parse(Nokogiri(open(@url, &:read)).css('script').first)
			return {
				tag => {
					'desc' => meta['name'],
					'url' => @url,
					'label' => tag
				}
			}
		end
	end

private
	def each_programs(html)
		x = "//section[h1[contains(text(),'アーカイブ')]]//*[contains(@class,'ProgramTitle')]/a/@href"
		html.xpath(x).each do |href|
			id = Pathname(href.value).basename.to_s
			yield JSON.parse(open("https://freshlive.tv/proxy/Programs;id=#{id}", &:read))
		end
	end

	def ts_list(rate_m3u8)
		ts_m3u8 = open(rate_m3u8).read.each_line.grep_v(/^#/)[1].chomp
		open(URI(rate_m3u8) + ts_m3u8).read.each_line.grep_v(/^#/).map{|u|URI(rate_m3u8) + u.chomp}
	end

	def mp4nize(src)
		dst = src.sub(/ts$/, 'mp4')
		command = "ffmpeg -i #{src} -vcodec copy -strict -2 #{dst}"
		result = Open3.capture3(command)
		if result[2].to_i == 0
			File.delete(src)
		else
			File.delete(dst) if File.exist?(dst)
		end
		return dst
	end
end
