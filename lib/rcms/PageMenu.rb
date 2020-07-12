require_relative './server/file/FileCMS'
require_relative './server/security/AdminAccessControler'
require_relative './xml/XMLSmart'
require_relative './xml/XMLSmartClient'
require_relative './server/GlobalSettings'
require_relative './MenuItem'

class PageMenu
    @@FS = File::SEPARATOR
    @myFileCMS = nil


    def initialize(*args)
      @pageSmart = XMLSmart.new
      @menuItems = Array.new
      @docDataDir = File.absolute_path(GlobalSettings.getDocumentDataDirectory)
      @docWorkDir = File.absolute_path(GlobalSettings.getDocumentWorkAreaDirectory)


      if(args.size == 1)
        if(args[0].class.name == 'MenuItem')
            initialize_fcms(args[0])
        else
            initialize_path(args[0])
        end
      elsif(args.size == 2)
          if(args[0].class.name == 'MenuItem')
              initialize_fcms_reload(args[0], args[1])
          else
              initialize_path_reload(args[0], args[1])
          end
      elsif(args.size == 3)
        initialize_fcms_version_reload(args[0], args[1], args[2])
      end
    end

    def initialize_fcms(menuFile)
        initialize_fcms_reload(menuFile, false)
    end

    def initialize_fcms_reload(menuFile, forceReload)
        #TODO: Finish off to build menu
        @myFileCMS = menuFile
        buildMenu(File.absolute_path(@myFileCMS.VERSIONED_FILE.getCurrentVersion()), forceReload)
    end

    def initialize_fcms_version(menuFile, version)
        initialize_fcms_version_reload(menuFile, version, false)
    end

    def initialize_fcms_version_reload(menuFile, version, forceReload)
        #TODO: Finish off to build menu
        @myFileCMS = menuFile
        if(version == -1)
            buildMenu(File.absolute_path(menuFile.VERSIONED_FILE.getCurrentVersion()), forceReload)
        else
            buildMenu(File.absolute_path(menuFile.VERSIONED_FILE.getVersionByNumber(version).getCurrentVersion()), forceReload)
        end
    end

    def initialize_path(menuFile)
        initialize_path_reload(menuFile, false)
    end

    def initialize_path_reload(menuFile, forceReload)
        #puts "-----#{menuFile} ------- #{forceReload}-------"
        if(menuFile.index(@docWorkDir) != nil || menuFile.index(@docDataDir) != nil)
            buildMenu(menuFile, forceReload)
        else
            buildMenu("#{@docDataDir}#{menuFile}", forceReload)
        end
    end

    def removeMenuItem( toRemove)
        @menuItems.delete(toRemove)
    end

    def addMenuItem(toAdd)
        @menuItems << toAdd
    end

    def compileMenu

        menu = "<page-menu>"
        @menuItems.each{ |mitem|
          menu.concat(mitem.menuItemToXML)
        }
        menu.concat("</page-menu>")
        return menu
    end

    def saveMenu(toSaveMenuTo, sessionId, userName)

        if(AccessControler.checkFileAccessWrite(sessionId, userName, toSaveMenuTo))

            page = File.read(toSaveMenuTo)
            newPage = ""
            if(page.index("<page-menu>") != nil)

                newPage.concat(page[0..page.index("<page-menu>")-1])
                newPage.concat(compileMenu)
                newPage.concat(page[page.indexOf("</page-menu>")+11])

            else

                newPage.concat(page[0..page.index("</pageinfo>")-1])
                newPage.concat(compileMenu)
                newPage.concat(page[page.index("</pageinfo>")-1])
            end

            f = File.new(toSaveMenuTo, 'w')
            f.write(newPage)
            return true
        end
        return false
    end

    def getMenuItems

        if(@menuItems.size > 0)
            return @menuItems
        else
            return Array.new
        end
    end

    def buildMenu(renderPage, forceReload)


        showSubMenu = true
        menu = renderPage
        menu = GlobalSettings.changeFilePathToMatchSystem(menu)

        mainSmart = XMLSmartClient.new

        if(!forceReload)
            @pageSmart.setXmlFile(menu)
            mainSmart.setXML(@pageSmart.getXML)
            #puts "-----------------------\n\nMenu setXmlFile 1 : #{menu}\n\n---------------------------------"

        else
            mainSmart.setXmlFile(menu)
            #puts "-----------------------\n\nMenu setXmlFile 2 : #{menu}\n\n---------------------------------"

        end

        xmlMenu = XMLSmartClient.new
        #puts "#{mainSmart.getNodeElement("page/pageinfo/page-menu/menu-entry",0,"menu-link/menu-text/menu-link-target")}"



        mainSmart.setNode("page/pageinfo/page-menu/menu-entry")
        if(mainSmart.getCount == nil)
            #puts "Setting xml ::::: #{renderPage}"
            xmlMenu.setXmlFile(renderPage)
            showSubMenu = false
            xmlMenu.setNode("page/pageinfo/page-menu/menu-entry")
            if(xmlMenu.getCount > 0)
                mainSmart.setXmlFile(xmlMenu.getXmlFile)
            end
            mainSmart.setNode("page/pageinfo/page-menu/menu-entry")
        end
        #puts "XML:::: #{mainSmart.getXML}"
        count = mainSmart.getCount
        for i in 0..count-1
            menuTmp = mainSmart.getNode(i)
            #puts " Check menuTmp :::#{menuTmp}"
            smart = XMLSmartClient.new
            smart.setXML(menuTmp)
            smart.setNode("menu-entry")
            smart.setIndex(0)
            smart.setNodeElement("menu-link/menu-text/menu-link-target/")
            link = smart.getNodeElement
            linkText = smart.getNodeElement
            linkTarget = smart.getNodeElement
            submenu = makeSubMenu("#{@docDataDir}#{@FS}#{link}")
            #puts "Menu Item -- link:#{link} :: link_text: #{linkText}"
            linkOpenType = MenuItem.getOpenLinkIn_String(linkTarget)
            #(linkTarget == "_self"? MenuItem.OPEN_SAME_WINDOW:MenuItem.OPEN_NEW_WINDOW )
            menuItem = MenuItem.new(link, linkOpenType, linkText, submenu)

            @menuItems << menuItem

        end
        #puts "All menu items ::: #{@menuItems}"
    end


    def makeSubMenu(xmlFile)
        #puts "Making sub menu:::: #{xmlFile}"
        xmlMenu = XMLSmartClient.new
        xmlMenu.setXmlFile(xmlFile)
        xmlMenu.setNode("page/pageinfo/page-menu/menu-entry")
        count = xmlMenu.getCount
        submenu = Array.new
        for i in 0..count-1

            menuTmp = xmlMenu.getNode(i)
            smart = XMLSmartClient.new
            smart.setXML(menuTmp)
            smart.setNode("menu-entry")
            smart.setIndex(0)
            smart.setNodeElement("menu-link/menu-text/menu-link-target/")
            link = smart.getNodeElement()
            linkText = smart.getNodeElement()
            linkTarget = smart.getNodeElement()

            linkOpenType = MenuItem.getOpenLinkIn_String(linkTarget)
            menuItem = MenuItem.new(link, linkOpenType, linkText, Array.new)
            submenu << menuItem

        end
        return submenu

    end


end
