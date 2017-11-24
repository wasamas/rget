# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "rget"
  spec.version       = "4.3.1"
  spec.authors       = ["TADA Tadashi"]
  spec.email         = ["t@tdtds.jp"]
  spec.description   = %q{Downloading newest radio programs on the web. Supported radio stations are hibiki, onsen, niconico and freshlive.}
  spec.summary       = %q{Downloading newest radio programs on the web.}
  spec.homepage      = "https://bitbucket.org/tdtds/rget"
  spec.license       = "GPL"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "nokogiri", ">= 1.7.0"
  spec.add_runtime_dependency "niconico", ">= 1.8.0"
  spec.add_runtime_dependency "pit"
  spec.add_runtime_dependency "dropbox_api"
  spec.add_runtime_dependency "mp3info"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
end
