module CloudDB
  class Connection
    
    attr_reader   :authuser
    attr_reader   :authkey
    attr_accessor :authtoken
    attr_accessor :authok
    attr_accessor :lbmgmthost
    attr_accessor :lbmgmtpath
    attr_accessor :lbmgmtport
    attr_accessor :lbmgmtscheme
    attr_reader   :auth_url
    attr_reader   :region
    
    # Creates a new CloudDB::Connection object.  Uses CloudDB::Authentication to perform the login for the connection.
    #
    # Setting the retry_auth option to false will cause an exception to be thrown if your authorization token expires.
    # Otherwise, it will attempt to reauthenticate.
    #
    # This will likely be the base class for most operations.
    #
    # The constructor takes a hash of options, including:
    #
    #   :username - Your Rackspace Cloud username *required*
    #   :api_key - Your Rackspace Cloud API key *required*
    #   :region - The region in which to manage database instances. Current options are :dfw (Rackspace Dallas/Ft. Worth Datacenter),
    #             :ord (Rackspace Chicago Datacenter) and :lon (Rackspace London Datacenter). *required*
    #   :auth_url - The URL to use for authentication.  (defaults to Rackspace USA).
    #   :retry_auth - Whether to retry if your auth token expires (defaults to true)
    #
    #   db = CloudDB::Connection.new(:username => 'YOUR_USERNAME', :api_key => 'YOUR_API_KEY', :region => :dfw)
    def initialize(options = {:retry_auth => true}) 
      @authuser = options[:username] || (raise CloudDB::Exception::Authentication, "Must supply a :username")
      @authkey = options[:api_key] || (raise CloudDB::Exception::Authentication, "Must supply an :api_key")
      @region = options[:region] || (raise CloudDB::Exception::Authentication, "Must supply a :region")
      @retry_auth = options[:retry_auth]
      @auth_url = options[:auth_url] || CloudDB::AUTH_USA
      @snet = ENV['RACKSPACE_SERVICENET'] || options[:snet]
      @authok = false
      @http = {}
      CloudDB::Authentication.new(self)
    end
    
    # Returns true if the authentication was successful and returns false otherwise.
    #
    #   lb.authok?
    #   => true
    def authok?
      @authok
    end
    
    # Returns the list of available database instances.
    #
    # Information returned includes:
    #   * :id - The numeric ID of this instance
    #   * :name - The name of the instance
    #   * :status - The current state of the instance (BUILD, ACTIVE, BLOCKED, RESIZE, SHUTDOWN, FAILED)
    def list_instances()
      response = dbreq("GET",lbmgmthost,"#{lbmgmtpath}/instances",lbmgmtport,lbmgmtscheme)
      CloudDB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      instances = CloudDB.symbolize_keys(JSON.parse(response.body)["instances"])
      return instances
    end
    alias :instances :list_instances
    
    # Returns a CloudDB::Instance object for the given instance ID number.
    #
    #    >> db.get_instance(692d8418-7a8f-47f1-8060-59846c6e024f)
    def get_instance(id)
      CloudDB::Instance.new(self,id)
    end
    alias :instance :get_instance
    
    # Creates a brand new database instance under your account.
    #
    # A minimal request must pass in :flavor_ref and :size
    #
    # Options:
    # :flavor_ref - reference (href) to a flavor as specified in the response from the List Flavors API call.
    # :size - specifies the volume size in gigabytes (GB). The value specified must be between 1 and 10.
    # :name - the name of the database instance.  Limited to 128 characters or less.
    def create_instance(options = {})
      body = Hash.new
      (body[:flavor_ref] = options[:flavor_ref]) or raise CloudDB::Exception::MissingArgument, "Must provide a flavor to create an instance"
      (body[:size] = options[:size]) or raise CloudDB::Exception::MissingArgument, "Must provide a size to create an instance"
      body[:name].upcase! if body[:name]
      response = dbreq("POST",lbmgmthost,"#{lbmgmtpath}/instances",lbmgmtport,lbmgmtscheme,{},body.to_json)
      CloudDB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      body = JSON.parse(response.body)['instance']
      return get_instance(body["id"])
    end

    # This method actually makes the HTTP REST calls out to the server. Relies on the thread-safe typhoeus
    # gem to do the heavy lifting.  Never called directly.
    def dbreq(method,server,path,port,scheme,headers = {},data = nil,attempts = 0) # :nodoc:
      if data
        unless data.is_a?(IO)
          headers['Content-Length'] = data.respond_to?(:lstat) ? data.stat.size : data.size
        end
      else
        headers['Content-Length'] = 0
      end
      hdrhash = headerprep(headers)
      url = "#{scheme}://#{server}#{path}"
      print "DEBUG: Data is #{data}\n" if (data && ENV['DATABASES_VERBOSE'])
      request = Typhoeus::Request.new(url,
                                      :body          => data,
                                      :method        => method.downcase.to_sym,
                                      :headers       => hdrhash,
                                      :user_agent    => "Cloud Databases Ruby API #{VERSION}",
                                      :verbose       => ENV['DATABASES_VERBOSE'] ? true : false)
      CloudDB.hydra.queue(request)
      CloudDB.hydra.run
      
      response = request.response
      print "DEBUG: Body is #{response.body}\n" if ENV['DATABASES_VERBOSE']
      raise CloudDB::Exception::ExpiredAuthToken if response.code.to_s == "401"
      response
    rescue Errno::EPIPE, Errno::EINVAL, EOFError
      # Server closed the connection, retry
      raise CloudDB::Exception::Connection, "Unable to reconnect to #{server} after #{attempts} attempts" if attempts >= 5
      attempts += 1
      @http[server].finish if @http[server].started?
      start_http(server,path,port,scheme,headers)
      retry
    rescue CloudDB::Exception::ExpiredAuthToken
      raise CloudDB::Exception::Connection, "Authentication token expired and you have requested not to retry" if @retry_auth == false
      CloudDB::Authentication.new(self)
      retry
    end
    
    
    private
    
    # Sets up standard HTTP headers
    def headerprep(headers = {}) # :nodoc:
      default_headers = {}
      default_headers["X-Auth-Token"] = @authtoken if (authok? && @account.nil?)
      default_headers["X-Storage-Token"] = @authtoken if (authok? && !@account.nil?)
      default_headers["Connection"] = "Keep-Alive"
      default_headers["Accept"] = "application/json"
      default_headers["Content-Type"] = "application/json"
      default_headers.merge(headers)
    end    
        
  end
end
