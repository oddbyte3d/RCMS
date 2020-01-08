require_relative "../../Page"
require_relative "../GlobalSettings"
require_relative "../net/HttpSession"
require_relative "../../util/Parser"
require "yaml"

class GenericContent

    def initialize

    end

    def setRequest(request)
        @request = request
    end

    def setSession(session)
      @session = session
    end

    def getValue(templateDir, page, template, searchKey, options)
    end

end
