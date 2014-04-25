# encoding: utf-8

require 'open-uri'

class WebRadio
	def self.instance(url)
		case url
		when %r[^http://hibiki-radio\.jp/]
			require 'hibiki'
			Hibiki.new(url)
		when %r[^http://sp\.animate\.tv/]
			require 'animate'
			Animate.new(url)
		when %r[^http://onsen\.ag/program/]
			require 'onsen'
			Onsen.new(url)
		when %r[^http://seaside-c\.jp/program/], %r[http://nakamuland\.net/]
			require 'seaside-c'
			SeasideCommnunications.new(url)
		else
			raise 'unsupported url.'
		end
	end

	def initialize(url)
		raise 'do not instanciate directly, use WebRadio method.' if self.class == WebRadio
		@url = url
	end

	def download(name)
		raise 'not implemented.'
	end

	def mp3ize
		return
	end

private
	def mp3_convert(src, dst, bitrate = 64)
		if File.exist? dst
			puts "'#{dst}' is existent. skipped."
			return self
		end
		system "ffmpeg -i #{src} -ab #{bitrate}k #{dst}"
		self
	end
end

def WebRadio(url)
	radio = WebRadio.instance(url)
	yield radio if block_given?
	radio
end

