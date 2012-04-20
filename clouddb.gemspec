# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require File.expand_path('../lib/clouddb/version.rb', __FILE__)
 
Gem::Specification.new do |s|
  s.name        = "clouddb"
  s.version     = CloudDB::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = %w("Jorge Miramontes", "H. Wade Minter")
  s.email       = %w(jorge.miramontes@rackspace.com minter@lunenburg.org)
  s.homepage    = "http://github.com/rackspace/ruby-clouddb"
  s.summary     = "Ruby API into the Rackspace Cloud Databases product"
  s.description = "A Ruby API to manage the Rackspace Cloud Databases product"
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_runtime_dependency "typhoeus"
  s.add_runtime_dependency "json"
 
  s.files = [
    "COPYING",
    ".gitignore",
    "README.rdoc",
    "clouddb.gemspec",
    "lib/clouddb.rb",
    "lib/clouddb/authentication.rb",
    "lib/clouddb/instance.rb",
    "lib/clouddb/connection.rb",
    "lib/clouddb/exception.rb",
    "lib/clouddb/version.rb"
  ]
  s.require_path = 'lib'
end
