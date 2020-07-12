require_relative "../../GlobalSettings"
require_relative "../../security/AdminAccessControler"
require_relative "../../file/FileCMS"
require_relative "../../../Page"
require_relative "../../file/exception/FileAccessDenied"
require_relative "../../file/exception/FileNotFound"
require_relative "../../../util/PropertyLoader"
require "require_all"
require_all 'lib/rcms/server/renderers/'


class PageActions

  def initialize(session, params)
    @status = 200
    sessionId = session["sessionId"]
    my_session = GlobalSettings.getSession(sessionId)
    userName = GlobalSettings.getUserLoggedIn(my_session)
    parentProperyFile = GlobalSettings.getGlobal("Parent-PropertyFile")
    propertyLoader = PropertyLoader.new(parentProperyFile)

    if userName != "guest"  # Guests should not be accessing this but just in case.
      case params["action"]
      when "save_xml"
        begin
          jsonRenderer = JSON_XMLRenderer.new
          @out = jsonRenderer.renderOutput(params, Hash.new, my_session, propertyLoader, params["file"], "json_to_xml")
          #puts "Out:::::::::: #{out}"
        rescue FileAccessDenied => fae
          #status = 403
          @out  = "{\"error\": \"#{fae.message}\"}"
        rescue FileNotFound => fne
          @out  = "{\"error\": \"#{fne.message}\"}"
        end
      when "publish"  #Publish a file to live
        begin
          version = -1
          if params["version"] != nil
            version = params["version"].to_i
          end
          fcms = FileCMS.new(my_session, params["file"], false)
          if fcms.canPublish?
            if fcms.publishVersion(version)
              @out = "{\"success\": \"file published\"}"
            end
          else
            raise FileAccessDenied.new("Publish permission denied.")
          end
        rescue FileAccessDenied => fae
          @out  = "{\"error\": \"#{fae.message}\"}"
        rescue FileNotFound => fne
          @out  = "{\"error\": \"#{fne.message}\"}"
        end
      end
    else
      @status  = 403
    end


  end

  def getResult
    return @out
  end

  def getStatus
    return @status
  end
end
