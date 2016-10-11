# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hermaeus/version'

Gem::Specification.new do |spec|
	spec.name          = "hermaeus"
	spec.version       = Hermaeus::VERSION
	spec.authors       = ["myrrlyn"]
	spec.email         = ["myrrlyn@outlook.com"]

	spec.summary       = "Archivist for /r/teslore"
	spec.description   = <<-EOS
Hermaeus provides archival services for /r/teslore by collecting lists of posts
and then downloading the source material those lists reference.
	EOS
	spec.homepage      = "https://github.com/myrrlyn/hermaeus"
	spec.license       = "MIT"

	spec.files         = `git ls-files -z`.split("\x0").reject do |f|
	  f.match(%r{^(test|spec|features)/})
	end
	spec.bindir        = "exe"
	spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
	spec.require_paths = ["lib"]

	spec.add_development_dependency "bundler", "~> 1.13"
	spec.add_development_dependency "rake", "~> 10.0"
	spec.add_development_dependency "pry"

	spec.add_dependency "nokogiri", "~> 1.6"
	spec.add_dependency "redd", "~> 0.7"
	spec.add_dependency "tomlrb"
end
