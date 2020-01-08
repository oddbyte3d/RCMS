
require 'net/http'

require_relative '../../Page'
require_relative '../../PageModule'
require_relative '../net/HttpSession'
require_relative '../../util/PropertyLoader'
require_relative '../file/FileCMS'
require_relative '../file/exception/FileAccessDenied'
require_relative '../Hub'
require_relative './OutputRenderer'
require_relative '../template/JSONTemplate'
require_relative '../template/JSONTemplateFile'
require "erb"

class JSON_XMLRenderer < OutputRenderer


    # Creates a new instance of XML_HTMLRenderer
    def initialize
      @SOURCE_IS_XML = false
    end

    #Render json -> xml output
    # request - Hash :
    # response - Hash :
    # session - For the moment it is rcms/server/net/HttpSession simple Hash wrapper
    # properties - PropertyLoader
    # etc....


    def renderOutput(request, response, session, propertyLoader, xmlFileToRender, theme)
        @mySession = session
        @myPropertyLoader = propertyLoader
        @myTheme = theme
        rendererConfig = YAML.load_file( "#{GlobalSettings.getGlobal("Server-ConfigPath")}OutputRenderers/JSON_XMLRenderer.yaml")
        cWorkArea = GlobalSettings.getCurrentWorkArea(session)
        docDataDir = GlobalSettings.getDocumentDataDirectory
        @FS = File::SEPARATOR
        xmlFileToRender = xmlFileToRender[0..xmlFileToRender.rindex(".")]+"xml" if xmlFileToRender.end_with? ".admin"
        #puts "\n\n----------------------------FileToRender: #{xmlFileToRender}--------------------\n\n"
        file = "#{cWorkArea}#{xmlFileToRender}"
        file = GlobalSettings.changeFilePathToMatchSystem(file)
        fcms = nil
        myPage = nil
        if File.exists? file
          fcms = FileCMS.new(session, file, false)
          myPage = Page.new(fcms, -1, session, file)
          #puts "\n\n-------------\n\nLoaded Page: #{myPage.title}\n\n---------------------------------------"
        else
          fcms = FileCMS.new(session, file, true)
        end
        #puts "Theme is: #{theme}"
        themeTmp = request["template"]
        templateDir = "#{docDataDir}#{@FS}system#{@FS}templates#{@FS}#{theme}"

        puts "TemplateDir exists? #{templateDir} -- #{File.exist?(templateDir)}"
        if(!File.exist?(templateDir) && request["template"] == nil)
            theme = "default"
            templateDir = "#{docDataDir}#{@FS}system#{@FS}templates#{@FS}#{theme}"
        end

        version = -1
        if(request["version"] != nil)
            version = request["version"].to_i
        end

        # TO-DO: Implement Template system then this....

        myTemplate = JSONTemplate.new(templateDir, request["file_contents"], myPage)
        myTemplate.setRenderer(self)
        #myTemplate.setHTMLRenderer(self)
        pageContent = myTemplate.getParsedTemplate
        pageModuleContent = ""
        if myTemplate.hasModuleTemplates


            file_contents = request["file_contents"][:blocks]
            #puts "HELLOOOOOO :::::: #{file_contents}"
            file_contents.each{ |key|
              #puts "Request ::::::  #{key}"
              if key.is_a? Array
                #modType = key[:type]
                at = 0
                modId = nil
                key.each{ |nkey|

                  if at == 0
                    modId = nkey
                    at = at.next
                    #puts "Module ID::::: #{modId}"
                  elsif nkey.is_a? Hash

                    modType = nkey["type"]
                    #puts "\n\nNext module type: #{modType}\n\n"
                    if myTemplate.containsModuleTemplate(modType)

                        #TO-DO: process needs to be implemented to support templates in modules....
                        modTemplate = myTemplate.getModuleTemplate(modType)
                        puts "#{modType}   :::: Data:::: #{nkey["data"]}"
                        modParameters = nkey["data"]
                        modParameters["id"] = "#{modId}"
                        modParameters["visible"] = "true"
                        modParameters["descriptive_name"] = "#{modType.capitalize} module"
                        puts "\n\nModule Parameters: #{modParameters}\n\n"
                        modTemplate.setModuleData(modParameters)
                        #puts "------------------>Processing module template: #{modType} :: #{modTemplate}"
                        #modTemplate.setModuleToRender(mod)
                        pageModuleContent.concat("<module>")
                        pageModuleContent.concat(modTemplate.parseTemplate)
                        pageModuleContent.concat("</module>")
                        #puts "\n\n\n#{pageModuleContent}\n\n\n"
                    else
                        pageModuleContent.concat("\"unsupported\": \"Module not supported:#{modType}\"")
                    end
                  end
                }
              end
            }
        end
        #puts "Test...."
        pageContent = Parser.replaceAll(pageContent, "*CONTENT*", pageModuleContent)
        pageContent = Hub.applyFilters(request, response, session, pageContent)

        myFile = fcms.getFileForWrite# { |file|
        myFile.write( pageContent )
        myFile.close
        return "{\"success\": \"Writing to #{fcms.getFileURL} success\"}"

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

end
