# encoding: utf-8

require 'open-uri'
require 'open3'

class WebRadio
	class DownloadError < StandardError; end

	def self.instance(url, options)
		case url
		when %r[^http://hibiki-radio\.jp/]
			require 'hibiki'
			Hibiki.new(url, options)
		when %r[^http://sp\.animate\.tv/]
			require 'animate'
			Animate.new(url)
		when %r[^http://onsen\.ag/program/]
			require 'onsen'
			Onsen.new(url, options)
		when %r[^http://seaside-c\.jp/program/], %r[http://nakamuland\.net/]
			require 'seaside-c'
			SeasideCommnunications.new(url, options)
		when %r[nicovideo\.jp]
			require 'nicovideo'
			Nicovideo.new(url, options)
		when %r[www\.youtube\.com]
			require 'youtube'
			YouTube.new(url, options)
		else
			raise 'unsupported url.'
		end
	end

	def initialize(url, options)
		raise 'do not instanciate directly, use WebRadio method.' if self.class == WebRadio
		@url = url
		@options = options
		if @options.path =~ %r|^dropbox://|
			require 'dropbox'
			@dropbox = DropboxAuth.client
		end
	end

	def download(name)
		raise 'not implemented.'
	end

private
	def mp3ize(src, dst, delete_src = true)
		# download src file
		if !File.exist?(src) && !exist?(dst)
			print "getting #{src}..."
			begin
				yield
				puts "done."
			rescue DownloadError => e
				puts "failed."
				File.delete(src) if File.exist?(src)
				$stderr.puts e.message
				return
			end
		end

		# convert to mp3
		return self unless @options.mp3

		print "converting to mp3..."
		if exist? dst
			puts "skipped."
			return
		else
      	result = Open3.capture3("ffmpeg -i #{src} -ab 64k #{dst}")
			if result[2].to_i == 0
				File.delete(src) if delete_src
				puts "done."
			else
				puts "failed."
				$stderr.puts result[1]
			end
		end

		# move to path
		if @options.path
			print "move to #{@options.path}..."
			begin
				move(dst)
				puts "done."
			rescue => e
				puts "failed."
				$stderr.puts e.message
			end
		end
	end

	def exist?(dst)
		if @dropbox
			begin
				!@dropbox.ls(dropbox_file(dst))[0]['is_deleted']
			rescue Dropbox::API::Error::NotFound, NoMethodError
				false
			end
		else
			File.exist?(dst)
		end
	end

	def move(dst)
		if @dropbox
			@dropbox.chunked_upload(dropbox_file(dst), open(dst))
			File.delete(dst)
		elsif @options.path
			FileUtils.mv(dst, @options.path)
		end
	end

	def dropbox_file(file)
		path = @options.path.sub(%r|^dropbox://|, '')
		File.join(path, file)
	end
end

def WebRadio(url, options)
	radio = WebRadio.instance(url, options)
	yield radio if block_given?
	radio
end

