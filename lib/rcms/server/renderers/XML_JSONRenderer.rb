
require 'net/http'

require_relative '../../Page'
require_relative '../../PageModule'
require_relative '../net/HttpSession'
require_relative '../../util/PropertyLoader'
require_relative '../file/FileCMS'
require_relative '../file/exception/FileAccessDenied'
require_relative '../Hub'
require_relative './OutputRenderer'
require_relative '../template/Template'
require "erb"

class XML_JSONRenderer < OutputRenderer


    # Creates a new instance of XML_HTMLRenderer
    def initialize
      @SOURCE_IS_XML = true
    end

    #Render xml -> json output
    # request - Hash : this will need to be mapped from rails
    # response - Hash : this will need to be mapped from rails
    # session - For the moment it is rcms/server/net/HttpSession simple Hash wrapper
    # properties - PropertyLoader
    # etc....

#    {"menu": {
#      "id": "file",
#      "value": "File",
#      "popup": {
#        "menuitem": [
#          {"value": "New", "onclick": "CreateNewDoc()"},
#          {"value": "Open", "onclick": "OpenDoc()"},
#          {"value": "Close", "onclick": "CloseDoc()"}
#        ]
#      }
#    }}


    def renderOutput( request, response, session, properties, xmlFileToRender, theme, baseDocRoot,
                      baseDocRootInclude, onlyModules)
        @mySession = session
        @myRequest = request
        @myResponse = response
        @myPropertyLoader = properties
        @baseDocRoot = baseDocRoot
        @baseDocRootInclude = baseDocRootInclude
        @myTheme = theme
        rendererConfig = YAML.load_file( "#{GlobalSettings.getGlobal("Server-ConfigPath")}OutputRenderers/XML_JSONRenderer.yaml")
        cWorkArea = GlobalSettings.getCurrentWorkArea(session)
        docDataDir = GlobalSettings.getDocumentDataDirectory
        @FS = File::SEPARATOR
        tmp = properties.getProperties("redirect")
        myPage = FileCMS.new(session, "#{cWorkArea}#{@FS}#{xmlFileToRender}")

        #puts "Theme is: #{theme}"
        themeTmp = request["template"]
        templateDir = "#{docDataDir}#{@FS}system#{@FS}templates#{@FS}#{theme}"

        #puts "TemplateDir exists? #{templateDir} -- #{File.exist?(templateDir)}"
        if(!File.exist?(templateDir) && request["template"] == nil)
            theme = "default"
            templateDir = "#{docDataDir}#{@FS}system#{@FS}templates#{@FS}#{theme}"
        end

        version = -1
        if(request["version"] != nil)
            version = request["version"].to_i
        end
        page = Page.new(myPage, version, session, myPage.getFileURL)


        # TO-DO: Implement Template system then this....
        myTemplate = Template.new(templateDir, page)
        myTemplate.setRenderer(self)
        #myTemplate.setHTMLRenderer(self)
        if(!onlyModules)
          pageContent = myTemplate.getParsedTemplate
          #puts "PageContent : #{pageContent}"
        else
          pageContent = ""
        end

        if myTemplate.hasModuleTemplates

            #//TODO: process page, each module, one at a time.... Need to supply each with the correct module ID.
            pageModuleContent = ""
            mods = page.getAllPageModules
            #puts "Mod count : #{mods.size}"
            at = 0
            mods.each{ |mod|

                modType = mod.getModuleType
                if myTemplate.containsModuleTemplate(modType)
                    #TO-DO: process needs to be implemented to support templates in modules....
                    modTemplate = myTemplate.getModuleTemplate(modType)
                    modTemplate.setModuleToRender(mod)
                    pageModuleContent.concat(modTemplate.parseTemplate)
                else
                    pageModuleContent.concat("\"unsupported\": \"Module not supported:#{modType}\"")
                end
                if at < mods.size-1
                  pageModuleContent.concat(rendererConfig["module_separator"])
                end
                at = at.next

            }
        end

        if(!onlyModules)
          pageContent = Parser.replaceAll(pageContent, "*CONTENT*", pageModuleContent)
        else
          pageContent = pageModuleContent
        end
        pageContent = Hub.applyFilters(request, response, session, pageContent)

        return pageContent
    end

    #TO-DO: make private
    def getTemplate(theme)
        #puts "Theme : #{theme}"
        tmpTheme = theme
        themeFound = false
        while(tmpTheme != "")

            #puts "myPropertyLoader :  #{@myPropertyLoader.getProperties("TemplateDirectory")}"
            if(@myPropertyLoader.getProperties("TemplateDirectory")[tmpTheme] != nil)

                theme = @myPropertyLoader.getProperties("TemplateDirectory")[tmpTheme]
                themeFound = true
                tmpTheme = ""
                #puts "theme found..."
            else
                #if(tmpTheme.index("/") != nil)
                  #puts "--------------------\n#{tmpTheme}\n-------------------------------"
                  tmpTheme = tmpTheme[0..tmpTheme.rindex("/")-1]
                #end
            end
        end
        if(!themeFound)
            theme = @myPropertyLoader.getProperties("TemplateDirectory")["default"]
        end
        return theme
    end

    def getRequest
        return @myRequest
    end

    def getResponse
        return @myResponse
    end

    def loadPageContent(*args)

      if(args.size == 2)
        return loadPageContent_2(args[0], args[1])
      else
        return loadPageContent_2(args[0], args[0])
      end
    end

    def loadPageContent_2(pageToLoad, parentPage)
        #TO-DO: implement this function when it is clear how it all fits together....
        return renderOutput(@myRequest, @myResponse, @mySession, @myPropertyLoader, pageToLoad, @myTheme, @baseDocRoot, @baseDocRootInc, true)
    end

end
