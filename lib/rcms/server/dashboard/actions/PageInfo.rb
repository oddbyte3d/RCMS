require_relative "../../GlobalSettings"
require_relative "../../security/AdminAccessControler"
require_relative "../../file/FileCMS"
require_relative "../../../Page"
require_relative "../../file/exception/FileAccessDenied"
require_relative "../../file/exception/FileNotFound"

class PageInfo

  def initialize(session, params)

    begin
      if params["file"] != nil  #Make sure all required parameters are supplied.
        file = params["file"]

        #Are we loading a particular version?
        version = -1
        if params["version"] != nil
          version = params["version"].to_i
        end

        sessionId = session["sessionId"]
        my_session = GlobalSettings.getSession(sessionId)
        userName = GlobalSettings.getUserLoggedIn(my_session)
        admin = AdminAccessControler.new
        #puts "\n\n-----------------\n#{file}\n----------------------------"
        fcms = FileCMS.new(my_session, file)
        page = Page.new(fcms, version, my_session, fcms.getFileURL)

        #If we are changing page info do it here.
        if (params["title"] != nil && params["description"] != nil && params["keywords"] != nil)
          page.setTitle(params["title"])
          page.setDescription(params["description"])
          page.setKeywords(params["keywords"])
          page.saveChanges
        end

        @out = "{\"versions\": ["
        versions = fcms.VERSIONED_FILE.getAllVersions
        if versions != nil
          vsize = versions.size
          at = 0
          versions.each{ |version|
            at = at.next
            @out.concat(  "{ \"recid\": \"#{version.versionNumber}\", ")
            @out.concat("\"ver_by\": \"#{version.versionUser}\",")
            @out.concat(" \"ver_desc\": \"#{version.versionDescription}\",")
            @out.concat(" \"ver_type\": \"#{version.getVersionTypeAsString}\" }")
            @out.concat(",") if at < vsize
          }
        end
        @out.concat("],")

        @out.concat("\"pageinfo\": {\"title\": \"#{page.title}\", \"keywords\": \"#{page.keywords}\", \"description\": \"#{page.description}\"}}")

        puts @out
      else
        @out = "{\"error\": \"parameters missing\"}"
      end

    rescue FileAccessDenied => e  #Catch any AccessDenied errors
      @out = "{\"error\": \"File Access Denied!\"}"
    rescue FileNotFound => e
      @out = "{\"error\": \"File Not Found!\"}"
    end

  end

  def getResult
    return @out
  end
end
