require_relative "../../Page"
require_relative "../GlobalSettings"
require_relative "../net/HttpSession"
require_relative "../../util/Parser"
require_relative "./GenericContent"
require_relative "./TemplateFile"
require_relative "../security/AccessControler"
require "yaml"

class Pagination < GenericContent

    def initialize(*args)
      if args.size == 1
        @myPage = args[0]
      end
      @@FS = File::SEPARATOR

    end

    def getValue(templateDir, page, template, searchKey, options)

        #puts "\n\n-----------------------------\nsearchKey: #{searchKey}\nOptions: #{options}\ntemplateDir: #{templateDir}\ntemplate: #{template}\npage: #{page}\n--------------------------------------"
        @options = options
        @myTemplate = template
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
          count = @myPage.getModuleCount
          for i in 1..count
            value.concat("<li><span class=\"pagin_item\"> </span></li>")
          end
        end
        user = GlobalSettings.getUserLoggedIn(@session)
        workPath = GlobalSettings.getCurrentWorkArea(@session)


        return value
    end

end
