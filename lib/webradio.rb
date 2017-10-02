# encoding: utf-8

require 'open-uri'
require 'open3'
require 'mp3info'

class WebRadio
	class NotFoundError < StandardError; end
	class DownloadError < StandardError; end

	def self.instance(params, options)
		case params['url']
		when %r[^http://hibiki-radio\.jp/]
			require 'hibiki'
			Hibiki.new(params, options)
		when %r[^http://(www\.)?onsen\.ag/program/]
			require 'onsen'
			Onsen.new(params, options)
		when %r[nicovideo\.jp]
			require 'nicovideo'
			Nicovideo.new(params, options)
		when %r[^https://freshlive\.tv/]
			require 'freshlive'
			FreshLive.new(params, options)
		else
			raise "unsupported url: #{params['url']}"
		end
	end

	def initialize(params, options)
		raise 'do not instanciate directly, use WebRadio method.' if self.class == WebRadio
		@url = params['url']
		@label = params['label']
		@cover = params['cover']
		@options = options
		if !@options.dump && @options.path =~ %r|^dropbox://|
			require 'dropbox'
			@dropbox = RGet::Dropbox.client
		end
	end

	def download
		raise 'not implemented.'
	end

	def dump
		raise 'not implemented.'
	end

private
	def mp3nize(src, dst, delete_src = true)
		if @options.mp3
			if exist?(dst)
				puts "#{dst} is existent, skipped."
				return
			end
		else
			if exist?(src)
				puts "#{src} is existent, skipped."
				return
			end
		end


		# download src file
		unless File.exist?(src)
			print "getting #{src}..."
			begin
				yield
				puts "done."
			rescue DownloadError => e
				File.delete(src) if File.exist?(src)
				puts "failed."
				$stderr.puts e.message
				return
			end
		end
		if !@options.mp3 || src == dst
			add_cover(src) if src =~ /\.mp3$/
			move(src) if @options.path
			return
		end

		# convert to mp3
		print "converting to mp3..."
		ffmpeg = (@options['mp3nize'] || "ffmpeg -i '$1' -ab 64k '$2'").gsub(/\$(.)/){|s|
			case $1
				when '1'; src
				when '2'; dst
				when '$'; '$'
				else; s
			end
		}
		result = Open3.capture3(ffmpeg)
		if result[2].to_i == 0
			File.delete(src) if delete_src
			add_cover(dst)
			puts "done."
		else
			File.delete(dst) if File.exist?(dst)
			puts "failed."
			$stderr.puts result[1]
			return
		end
		move(dst) if @options.path
	end

	def add_cover(dst)
		begin
			mp3 = Mp3Info.new(dst)
			mp3.tag.title = File.basename(dst, '.mp3')
			mp3.tag2.add_picture(cover_image) if @cover
			mp3.close
		rescue
			$stderr.puts "add mp3 info failed (#$!)"
		end
	end

	def cover_image
		if @cover =~ /^https?:/
			cover_image_as_url()
		else # XPath
			cover_image_as_xpath()
		end
	end

	def cover_image_as_url
		open(@cover, 'rb', &:read)
	end

	def cover_image_as_xpath
		html = Nokogiri(open(@url, &:read))
		image_url = (URI(@url) + (html.xpath(@cover).text)).to_s
		open(image_url, 'r:ASCII-8BIT', &:read)
	end

	def exist?(dst)
		if @dropbox
			@dropbox.exist?(dst, dropbox_path)
		elsif @options.path
			File.exist?(File.join(@options.path, dst))
		else
			File.exist?(dst)
		end
	end

	def move(dst)
		if @options.path
			begin
				print "move to #{@options.path}..."
				if @dropbox
					open(dst) do |r|
						@dropbox.upload(dropbox_file(dst)) do
							print '.'
							r.read(10_000_000)
						end
					end
					File.delete(dst)
				elsif !(Pathname(@options.path).expand_path == Pathname(dst).expand_path.dirname)
					FileUtils.mv(dst, @options.path)
				else
					puts "skip."
					return
				end
				puts "done."
			rescue => e
				puts "failed."
				$stderr.puts e.message
			end
		end
	end

	def dropbox_path
		@options.path.sub(%r|^dropbox://|, '/')
	end

	def dropbox_file(file)
		path = @options.path.sub(%r|^dropbox://|, '/')
		File.join(path, file)
	end
end

def WebRadio(params, options)
	radio = WebRadio.instance(params, options)
	yield radio if block_given?
	radio
end

