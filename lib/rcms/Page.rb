require 'date'
require_relative './server/GlobalSettings'
require_relative './util/Parser'
require_relative './xml/XMLSmart'
require_relative './PageModule'
require_relative './PageMenu'
#require_relative './MenuItem'

 class Page

   attr_reader  :page, :pagePath, :webPath, :description, :title, :author,
                :owner, :keywords, :updatedBy, :lastUpdated, :CACHE
   #attr_accessor :description

    def initialize(*args)
      beforeInit
      if(args.size == 2)
        #puts "Args : #{args[0].class.name}"
        if(args[1].class.name == "HttpSession")
          initialize_session(args[0], args[1])
        else
          initialize_2(args[0], args[1])
        end
      elsif(args.size == 4)
        initialize_4(args[0], args[1], args[2], args[3])
      end

    end

    def initialize_session( page, session)
      @SESSION = session
      @pageSmart = XMLSmart.new(@SESSION, "<test/>")
      @page = page
      @workArea = GlobalSettings.getCurrentWorkArea(session)
      if(@page.index(@workArea) == nil)
        @page = @workArea.concat(@page)
      end
      @pagePath = File.absolute_path(@page)
      if File.absolute_path(@pagePath).index(@serverDataPath) == nil
          @serverDataPath = GlobalSettings.changeFilePathToMatchSystem(File.absolute_path(GlobalSettings.getDocumentWorkAreaDirectory()))
      end

      if(@pagePath.index(@serverDataPath) != nil)
          @webPath = Parser.replaceAll(@pagePath, @serverDataPath, "")
      elsif(@pagePath.index(@serverWorkPath) != nil)
          @webPath = Parser.replaceAll(@pagePath, @serverWorkPath, "")
      end
      @pageSmart.setXmlFile(File.absolute_path(@page))
      #puts "About to parse page: #{@page} -- #{@webPath}"
      parsePage(@pageSmart.getXML, @webPath)
      @pagePath = @webPath
    end

    def initialize_4(myPage, version, session, pagePath)
       #throws FileNotFound, FileAccessDenied, IOException

        @SESSION = session
        @pageSmart = XMLSmart.new(@SESSION, "<test/>")
        @pageSmart.setXmlFile(File.absolute_path(myPage.VERSIONED_FILE.getCurrentVersion()), version)
        parsePage(@pageSmart.getXML, File.absolute_path(myPage.VERSIONED_FILE.getCurrentVersion()))
    end

    def initialize_2(page, pagePath)
        parsePage(page, pagePath)
    end

    def beforeInit

      @xmlWorker = XMLDocumentHash.new
      @serverDataPath = GlobalSettings.getDocumentDataDirectory
      @serverWorkPath = GlobalSettings.getDocumentWorkAreaDirectory
      @DATA_NOT_PROVIDED = "Not entered"
      @CACHE = false
      @updatedBy = "-No Updates-"
      @lastUpdated = Date.today
      @lastUpdatedString = ""
      @title = nil
      @author = nil
      @owner = nil
      @keywords = nil
      @description = nil
      @webPath = nil
      #@pageFile = nil
      @modCount = nil
      @mods = Array.new #PageModule
      #private PageMenu menu;


      @serverDataPath = GlobalSettings.changeFilePathToMatchSystem(@serverDataPath)


    end



    #TO-DO: make private
    private def parsePage(page, pagePath)
        #puts "Loading page : ----#{pagePath}"
        if(pagePath.index(@serverDataPath) != nil)
            @webPath = Parser.replaceAll(pagePath, @serverDataPath, "")
        elsif(pagePath.index(@serverWorkPath) != nil)
            @webPath = Parser.replaceAll(pagePath, @serverWorkPath, "")
        end
        @pageSmart.setXML(page)
        #puts "Set XML: #{@pageSmart.getXML}"
        data = @pageSmart.getNodeElement("page/pageinfo",0,"pagetitle/author/owner/keywords/description")
        puts "Page Data:::::::#{data}"
        @title = data[0]
        @author = data[1]
        @owner = data[2]
        @keywords = data[3]
        @description = data[4]

        @pageSmart.setNode("page/pageinfo/edit_history/edit_by")
        @pageSmart.setNodeElement("name/date/")
        @updatedBy = @pageSmart.getNodeElement()
        @lastUpdatedString = @pageSmart.getNodeElement()


        #java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat((String)GlobalSettings.getGlobal("PageUpdatedDateFormat"));
        #this.lastUpdated = sdf.parse(lastUpdatedString);
        @lastUpdatedString = GlobalSettings.formatDate(GlobalSettings.getGlobal("PageUpdatedDateFormat"), @lastUpdated)
        #puts "Last Updated: #{@lastUpdated} --- #{@lastUpdatedString}"

        @pageSmart.setNode("page/pageinfo/")
        @pageSmart.setNodeElement("cache_page/")
        @CACHE = (@pageSmart.getNodeElement() == true)



        if(@title == nil || @title == "##Not-found##")
            @title = @DATA_NOT_PROVIDED
        end
        if(@author == nil || @author == "##Not-found##")
            @author = @DATA_NOT_PROVIDED
        end
        if(@owner == nil || @owner == "##Not-found##")
            @owner = @DATA_NOT_PROVIDED
        end
        if(@keywords == nil || @keywords == "##Not-found##")
            @keywords = @DATA_NOT_PROVIDED
        end
        if(@description == nil || @description == "##Not-found##")
            @description = @DATA_NOT_PROVIDED
        end

        #puts "-------------------------------"
        @pageSmart.setXmlFile(pagePath)
        #puts "XML :::::: #{@pageSmart.getXML}"
        @pageSmart.setNode("module")
        #puts "Module Count: #{@pageSmart.getCount}"
        @modCount = @pageSmart.getCount

        #puts "pagePath : #{@pagePath}"
        #mods = Array.new
        for i in 0..@modCount-1
            #puts "ModAt : #{i} -- Data : #{@pageSmart.getNode(i)}"
            @mods[i] = PageModule.new(@xmlWorker.getChildNode(@pageSmart.getNode(i),0))
        end
        if(!pagePath.start_with?("/"))
            pagePath = "/"+pagePath
        end
        @menu = PageMenu.new(pagePath)
    end

    def getMenu
        return @menu
    end

    def getPageModule(index)
        return @mods[index]
    end

    def getPageModuleById(id)
        for i in 0..mods.size
            if(mods[i].getID()==id)
                return mods[i]
            end
        end
        return nil
    end

    def getAllPageModules
        return @mods
    end


    def getModuleCount
        return @modCount
    end

end
