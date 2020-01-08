require_relative '../../Page'
require_relative '../../PageModule'
require_relative '../net/HttpSession'
require_relative '../../util/PropertyLoader'
require_relative '../file/FileCMS'
require_relative '../file/exception/FileAccessDenied'
require_relative '../Hub'
require_relative './OutputRenderer'
require_relative '../template/Template'
require_relative '../GlobalSettings'
require_relative '../file/exception/FileNotFound'
require_relative '../file/exception/FileAccessDenied'
require 'yaml'
require 'erb'

class ERB_Renderer < OutputRenderer

    def initialize
    end

    def renderOutput( request, response, session, properties, fileToRender, theme, baseDocRoot,
                      baseDocRootInclude, onlyModules)
            @FS = File::SEPARATOR
            rendererConfig = YAML.load_file( "#{GlobalSettings.getGlobal("Server-ConfigPath")}OutputRenderers/Text_Renderer.yaml")

            cWorkArea = GlobalSettings.getCurrentWorkArea(session)
            cssFile = FileCMS.new(session, "#{cWorkArea}#{@FS}#{fileToRender}")
            if cssFile.exist?
              @out = cssFile.getFileForRead.read
              if(rendererConfig["ApplyFilters"] != nil &&
                      rendererConfig["ApplyFilters"])
                  @out = Hub.applyFilters(request, response, session, @out)
              end
            else
              raise FileNotFound.new("#{fileToRender} does not exist....")
            end
            #_erbTest = "Cool ERB works!"
            @out = ERB.new(@out)
            return @out

    end


end
