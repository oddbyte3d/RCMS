
require 'net/http'

require_relative '../../Page'
require_relative '../../PageModule'
require_relative '../net/HttpSession'
require_relative '../../util/PropertyLoader'
require_relative '../file/FileCMS'
require_relative '../file/exception/FileAccessDenied'
require_relative '../Hub'
require_relative '../security/AccessControler'
require_relative './OutputRenderer'
require_relative '../template/Template'
require "erb"

class MENU_JSONRenderer < OutputRenderer


    # Creates a new instance of XML_HTMLRenderer
    def initialize
      @SOURCE_IS_XML = false
      @ACCESS = AccessControler.new
    end

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
        #rendererConfig = YAML.load_file( "#{GlobalSettings.getGlobal("Server-ConfigPath")}OutputRenderers/XML_JSONRenderer.yaml")
        cWorkArea = GlobalSettings.getCurrentWorkArea(session)
        user = GlobalSettings.getUserLoggedIn(session)
        #docDataDir = GlobalSettings.getDocumentDataDirectory
        @FS = File::SEPARATOR
        menuFile =  GlobalSettings.changeFilePathToMatchSystem("#{cWorkArea}#{@FS}#{xmlFileToRender}")
        myPage = FileCMS.new(session, menuFile)

        page = Page.new(myPage, -1, session, myPage.getFileURL)
        menu = page.getMenu
        pageContent = "{ \"menu\": ["
        if(menu != nil && menu.getMenuItems.size > 0)
            mItems = menu.getMenuItems
            at = 0
            mItems.each{ |mitem|
              if(@ACCESS.checkUserFileAccess(user, menuFile))
                  pageContent.concat( processMenuItem(mitem) )
                  pageContent.concat(",") if at < mItems.size-1
              end
              at = at.next
            }
        end
        pageContent.concat("]}")
        pageContent = Hub.applyFilters(request, response, session, pageContent)

        return pageContent
    end

    def processMenuItem(myItem)
      options = createOptions(myItem)
      if options.end_with? ","
        options = options[0..options.rindex(",")-1]
      end
      link = myItem.getLink
      link = link[0..link.rindex(".")]+"json"
      menu = "{\"link\": \"#{link}\", \"text\": \"#{myItem.getText}\""
      menu.concat(", \"submenu\": [#{options}]") if options != nil && options.strip != ""
      menu.concat "}"
      return menu
    end

    def createOptions(myItem)
        subMenu = ""
        nat = 0
        if(myItem.getAllSubMenuItems.size != nil)
            sub = myItem.getAllSubMenuItems
            puts "Submenu Count : #{sub.size}"
            sub.each{ |nsub|
              subMenu.concat(processMenuItem(nsub))
              puts "---- At : #{nat} #{nat < sub.size-1}"
              subMenu.concat(",") if nat < sub.size-1
            }
            nat = nat.next
        end
        return subMenu
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
