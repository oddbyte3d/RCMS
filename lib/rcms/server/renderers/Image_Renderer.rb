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

class Image_Renderer < OutputRenderer

    def initialize
    end

    def renderOutput( request, response, session, properties, fileToRender, theme, baseDocRoot,
                      baseDocRootInclude, onlyModules)
            @FS = File::SEPARATOR
            rendererConfig = YAML.load_file( "#{GlobalSettings.getGlobal("Server-ConfigPath")}OutputRenderers/Image_Renderer.yaml")
            #puts "Image Renderer config : #{rendererConfig}"

            cWorkArea = GlobalSettings.getCurrentWorkArea(session)
            cssFile = FileCMS.new(session, "#{cWorkArea}#{@FS}#{fileToRender}")
            if cssFile.exist?
              @out = cssFile.getFileForRead.read
              #if(rendererConfig["ApplyFilters"] != nil &&
              #        rendererConfig["ApplyFilters"] == "true")
              #    @out = Hub.applyFilters(request, response, session, out)
              #end
            else
              raise FileNotFound.new("#{fileToRender} does not exist....")
            end

            return @out

    end


end
