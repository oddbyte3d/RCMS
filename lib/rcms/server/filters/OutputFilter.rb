require_relative "../file/FileCMS"
require_relative "../net/HttpSession"
require_relative "../GlobalSettings"

class OutputFilter
    @@FS = File::SEPARATOR

    def initialize(session)
      @session = session
      @configFile = FileCMS.new(session, "#{GlobalSettings.getDocumentConfigDirectory()}#{@@FS}Filters/OutputFilter.yaml")
    end

    def filterOutput(request, response, session, input)
      return input
    end
    def getFilterDescription
      return "Basis filter, just returns input unaltered"
    end
    def getConfigurationFile
      return @configFile
    end
end
