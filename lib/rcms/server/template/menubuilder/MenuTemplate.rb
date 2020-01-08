require_relative "../../../Page"
require_relative "../../../PageMenu"
require_relative "../../../MenuItem"
require_relative "../../GlobalSettings"
require_relative "../../net/HttpSession"
require_relative "../../../util/Parser"
require_relative "../GenericContent"
require_relative "../TemplateFile"
require_relative "../../security/AccessControler"
require "yaml"

class MenuTemplate < GenericContent

    def initialize(*args)
      if args.size == 1
        @myPage = args[0]
      end
      puts "Init menu: #{@myPage}"
      @@MENUITEM_TEMPLATE = "MenuItem.erb"
      @@FS = File::SEPARATOR
    end

    def getValue(templateDir, page, template, searchKey, options)

        @options = options
        @myTemplate = template
        #puts "TEMPLATE??????  = #{@myTemplate}"
        @myTemplateDir = templateDir
        @ACCESS = AccessControler.new
        value = ""
        @session = @myTemplate.getRenderer.mySession
        @request = @myTemplate.getRenderer.myRequest
        if(@myPage == nil)
          @myPage = page
        elsif @myPage.is_a? String
          #puts "initiating page::::::::::::::::::::: #{@myPage} :: #{@session}"
          @myPage = Page.new(@myPage, @session)
        end
        user = GlobalSettings.getUserLoggedIn(@session)
        workPath = GlobalSettings.getCurrentWorkArea(@session);

        myMenu = @myPage.getMenu
        if(myMenu != nil && myMenu.getMenuItems.size > 0)

            mItems = myMenu.getMenuItems
            @menuItemT = "#{@myTemplateDir}#{@@FS}#{@@MENUITEM_TEMPLATE}"
            if File.exist? @menuItemT
                #puts "User: #{user} Menu Items: #{mItems}"
                mItems.each{ |mitem|
                  puts "........Menu Item : #{mitem.getLink}"
                  if(@ACCESS.checkUserFileAccess(user, "#{workPath}#{mitem.getLink}"))
                      value.concat( processMenuItem(mitem, @menuItemT) )
                  end
                }

            end
        end

        return value
    end

    def processMenuItem(myItem, menuItem)
      puts "Menu Item:::: #{myItem}"
      options = createOptions(myItem)
      puts "\n\n-----------------------\nOptions ::: #{options}"
      tmp = TemplateFile.new(@myTemplateDir, menuItem, @myPage, options)
      tmp.setSession(@session)
      tmp.setRequest(@request)
      test = tmp.parseTemplate
      #puts "Menu Item:: #{test}"
      return test
    end


    def createOptions(myItem)

        menuItemP = Hash.new
        menuItemP["LINK_HREF"] = myItem.getLink
        menuItemP["LINK_TOOLTIP"] = myItem.getText
        menuItemP["LINK_TITLE"] = myItem.getText

        #puts "Submenu in createOptions ::: #{myItem.getAllSubMenuItems.size}"
        if(myItem.getAllSubMenuItems.size != nil)
            sub = myItem.getAllSubMenuItems
            subMenu = ""
            sub.each{ |nsub|
              subMenu.concat(processMenuItem(nsub, @menuItemT))
            }
            #myprops = Hash.new
            #myprops["SUB_MENU"] = subMenu
            #tmp = TemplateFile.new(@myTemplateDir, @menuItemT, @myPage, myprops)
            menuItemP["SUB_MENU"] = subMenu#tmp.parseTemplate
        end
        return menuItemP
    end


end
