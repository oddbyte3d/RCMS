require 'net/http'

require_relative '../../Page'
require_relative '../../PageModule'
require_relative '../net/HttpSession'
require_relative '../../util/PropertyLoader'
require_relative '../file/FileCMS'
require_relative '../file/exception/FileAccessDenied'
require_relative '../Hub'
require_relative '../template/Template'

class OutputRenderer

    attr_reader :mySession, :myRequest, :myResponse, :myTheme, :baseDocRoot, :baseDocRootInc, :SOURCE_IS_XML

    def initialize
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
    end

    # Creates a new instance of OutputRenderer */
    def render( request, response, session, properties, xmlFileToRender, theme, baseDocRoot,
                      baseDocRootInclude, onlyModules)


      pageContent = renderOutput(request, response, session, properties, xmlFileToRender, theme, baseDocRoot,
                        baseDocRootInclude, onlyModules)
      pageContent = Hub.applyFilters(request, response, session, pageContent)
      pageContent = Template.filterOutput(nil, @extraParams, pageContent)

    end

    def setAdditionalParameters(params)
      #puts "Setting parameters ::::::::::: #{params}"
      @extraParams = params
    end
end
