#!/usr/bin/env ruby
# 
# == Cloud Databases API
# ==== Connects Ruby Applications to Rackspace's {Cloud Databases service}[http://www.rackspace.com/cloud/cloud_hosting_products/databases/]
# By Jorge Miramontes <jorge.miramontes@rackspace.com> and H. Wade Minter <minter@lunenburg.org>
#
# See COPYING for license information.
# Copyright (c) 2012, Rackspace US, Inc.
# ----
# 
# === Documentation & Examples
# To begin reviewing the available methods and examples, peruse the README.rodc file, or begin by looking at documentation for the 
# CloudDB::Connection class.
#
# The CloudDB class is the base class.  Not much of note aside from housekeeping happens here.
# To create a new CloudDB connection, use the CloudDB::Connection.new method.

module CloudDB
  
  AUTH_USA = "https://auth.api.rackspacecloud.com/v1.0"
  AUTH_UK = "https://lon.auth.api.rackspacecloud.com/v1.0"

  require 'uri'
  require 'rubygems'
  require 'json'
  require 'date'
  require 'typhoeus'

  unless "".respond_to? :each_char
    require "jcode"
    $KCODE = 'u'
  end

  $:.unshift(File.dirname(__FILE__))
  require 'clouddb/version'
  require 'clouddb/exception'
  require 'clouddb/authentication'
  require 'clouddb/connection'
  require 'clouddb/instance'

  # Helper method to recursively symbolize hash keys.
  def self.symbolize_keys(obj)
    case obj
    when Array
      obj.inject([]){|res, val|
        res << case val
        when Hash, Array
          symbolize_keys(val)
        else
          val
        end
        res
      }
    when Hash
      obj.inject({}){|res, (key, val)|
        nkey = case key
        when String
          key.to_sym
        else
          key
        end
        nval = case val
        when Hash, Array
          symbolize_keys(val)
        else
          val
        end
        res[nkey] = nval
        res
      }
    else
      obj
    end
  end
  
  def self.hydra
    @@hydra ||= Typhoeus::Hydra.new
  end
  
  # CGI.escape, but without special treatment on spaces
  def self.escape(str,extra_exclude_chars = '')
    str.gsub(/([^a-zA-Z0-9_.-#{extra_exclude_chars}]+)/) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end
  end
  
  def self.paginate(options = {})
    path_args = []
    path_args.push(URI.encode("limit=#{options[:limit]}")) if options[:limit]
    path_args.push(URI.encode("offset=#{options[:offset]}")) if options[:offset]
    path_args.join("&")
  end
  

end
