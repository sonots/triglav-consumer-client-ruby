# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'triglav/consumer/client/version'

Gem::Specification.new do |spec|
  spec.name          = "triglav-consumer-client"
  spec.version       = Triglav::Consumer::Client::VERSION
  spec.authors       = ["Triglav Team"]
  spec.email         = ["triglav_admin_my@dena.jp"]

  spec.summary       = %q{Consumer client helper library in Ruby for Triglav, data-driven workflow tool.}
  spec.description   = %q{Consumer client helper library in Ruby for Triglav, data-driven workflow tool.}
  spec.homepage      = "https://github.com/triglav-dataflow/triglav-consumer-client-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "triglav_client"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit"
end
