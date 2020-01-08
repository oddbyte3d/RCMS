class MenuItem

    @OPEN_NEW_WINDOW = 0
    @OPEN_SAME_WINDOW = 1;
    @OPEN_IN_STRING = ["_blank", "_self"]



    @link = ""
    @openLinkIn = 1
    @text = ""

    @subMenu = Array.new

    def initialize(link, openType, text, submenu)

        @link = link
        @openLinkIn = openType
        @text = text
        if(submenu != nil)
            @subMenu = submenu
        else
            @subMenu = Array.new
        end
    end


    def menuItemToXML

        xml = "<menu-entry>"
        xml.concat("<menu-link>")
        xml.concat(@link)
        xml.concat("</menu-link>")

        xml.concat("<menu-link-target>")
        xml.concat(MenuItem.getOpenLinkIn_String(@openLinkIn))
        xml.concat("</menu-link-target>")

        xml.concat("<menu-text>")
        xml.concat(@text)
        xml.concat("</menu-text>")
        xml.concat("<menu-image></menu-image>")

        xml.concat("</menu-entry>")
        return xml
    end

    def addSubMenuItem(item)
        @subMenu << item
    end

    def getSubMenuItem(index)
        return @subMenu[index]
    end

    def getSubMenuCount
        return @subMenu.size
    end

    def getAllSubMenuItems
        return @subMenu
    end

    def getLink
        return @link
    end

    def setLink(link)
        @link = link
    end

    def self.getOpenLinkIn_String(openIn)
        if(openIn.class.name == "String")
          if(openIn == "_blank")
            openIn = 0
          else
            openIn = 1
          end
        end
        return @OPEN_IN_STRING[openIn]
    end

    def getOpenLinkIn
        return @openLinkIn
    end

    def setOpenLinkIn(openLinkIn)
        @openLinkIn = openLinkIn
    end

    def getText
        return @text
    end

    def setText(text)
        @text = text
    end


end
