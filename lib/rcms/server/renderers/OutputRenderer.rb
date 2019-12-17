require 'net/http'

require_relative '../../Page'
require_relative '../../PageModule'
require_relative '../net/HttpSession'
require_relative '../../util/PropertyLoader'
require_relative '../file/FileCMS'
require_relative '../file/exception/FileAccessDenied'
require_relative '../Hub'

class OutputRenderer

    attr_reader :mySession, :myRequest, :myResponse, :myTheme, :baseDocRoot, :baseDocRootInc, :SOURCE_IS_XML

    @forward = ""
    @baseDocRoot = ""
    @baseDocRootInclude = ""
    @myTheme = ""
    @myPropertyLoader = nil
    @myRequest = nil
    @myResponse = nil
    @mySession = nil
    @out = nil
    @SOURCE_IS_XML = false

    def initialize
    end

    # Creates a new instance of OutputRenderer */
    def renderOutput( request, response, session, properties, xmlFileToRender, theme, baseDocRoot,
                      baseDocRootInclude, onlyModules)
        return "Do not use the base OutputRenderer...."
    end
end
