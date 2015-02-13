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
	end

	def download(name)
		raise 'not implemented.'
	end

private
	def mp3ize(src, dst, delete_src = true)
		# download src file
		if !File.exist?(src) && !File.exist?(dst)
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
		if File.exist? dst
			puts "skipped."
		else
      	result = Open3.capture3("ffmpeg -i #{src} -ab 64k #{dst}")
			if result[2].to_i == 0
				File.delete(src) if delete_src
				puts "done."
			else
				puts "failed."
				$stderr.puts MediaConvertError.new(result[1])
			end
		end
	end
end

def WebRadio(url, options)
	radio = WebRadio.instance(url, options)
	yield radio if block_given?
	radio
end

