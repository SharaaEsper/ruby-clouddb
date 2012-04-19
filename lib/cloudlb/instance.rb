module CloudDB
  class Instance
    
    attr_reader :id
    attr_reader :name
    attr_reader :hostname
    attr_reader :created
    attr_reader :udpated
    attr_reader :flavor_id
    attr_reader :volume_size
    attr_reader :status
    
    # Creates a new CloudDB::Instance object representing a Database instance.
    def initialize(connection,id)
      @connection    = connection
      @id            = id
      @lbmgmthost   = connection.lbmgmthost
      @lbmgmtpath   = connection.lbmgmtpath
      @lbmgmtport   = connection.lbmgmtport
      @lbmgmtscheme = connection.lbmgmtscheme
      populate
      return self
    end
    
    # Updates the information about the current Instance object by making an API call.
    def populate
      response = @connection.dbreq("GET",@lbmgmthost,"#{@lbmgmtpath}/instances/#{CloudDB.escape(@id.to_s)}",@lbmgmtport,@lbmgmtscheme)
      CloudDB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      data = JSON.parse(response.body)['instance']
      @id                    = data["id"]
      @name                  = data["name"]
      @hostname              = data["hostname"]
      @created               = data["created"]
      @updated               = data["updated"]
      @flavor_id             = data["flavor"]["id"]
      @volume_size           = data["volume"]["size"]
      @status                = data["status"]
      true
    end
    alias :refresh :populate
  
    # Lists the databases associated with this Instance
    #
    #    >> i.list_databases
    def list_databases
      response = @connection.dbreq("GET", @lbmgmthost, "#{@lbmgmtpath}/instances/#{CloudDB.escape(@id.to_s)}/databases",@lbmgmtport,@lbmgmtscheme)
      CloudDB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      CloudDB.symbolize_keys(JSON.parse(response.body)["databases"])
    end
    alias :databases :list_databases

    # Lists the users associated with this Instance
    #
    #    >> i.list_users
    def list_users
      response = @connection.dbreq("GET", @lbmgmthost, "#{@lbmgmtpath}/instances/#{CloudDB.escape(@id.to_s)}/users",@lbmgmtport,@lbmgmtscheme)
      CloudDB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      CloudDB.symbolize_keys(JSON.parse(response.body)["users"])
    end
    alias :users :list_users
      
    # Deletes the current instance object.  Returns true if successful, raises an exception otherwise.
    def destroy!
      response = @connection.dbreq("DELETE", @lbmgmthost, "#{@lbmgmtpath}/instances/#{CloudDB.escape(@id.to_s)}",@lbmgmtport,@lbmgmtscheme)
      CloudDB::Exception.raise_exception(response) unless response.code.to_s.match(/^202$/)
      true
    end

    private
    
    def update(body)
      response = @connection.dbreq("PUT", @lbmgmthost, "#{@lbmgmtpath}/instances/#{CloudDB.escape(@id.to_s)}",@lbmgmtport,@lbmgmtscheme,{},body.to_json)
      CloudDB::Exception.raise_exception(response) unless response.code.to_s.match(/^20.$/)
      populate
      true
    end

  end  
end
