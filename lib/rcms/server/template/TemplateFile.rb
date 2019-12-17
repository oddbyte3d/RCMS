
require_relative "../../Page"
require_relative "../GlobalSettings"
require_relative "../../util/Parser"
require_relative "./Template"

class TemplateFile


    def initialize(*args)

      @myPart = ""
      @myTemplateDir = args[0]
      @myTemplate = nil
      @myPageToRender = nil
      @myModuleToRender = nil

      if(args.size == 3)
          initialize_3(args[0], args[1], args[2])
      else
          initialize_4(args[0], args[1], args[2], args[3])
      end

    end
    def initialize_3(templateDir, templatePart, renderPage)
      @myPageToRender = renderPage
      #puts "template : #{templatePart}"
      if(File.exist?(templatePart))
          @myPart = templatePart
          @myPartConfig = "#{@myPart}.yaml"
          #puts "myPartConfig : #{@myPartConfig}"
          if(File.exist?(@myPartConfig))
              @configProperties = YAML.load_file(@myPartConfig)
          end
          @configPropertiesSecond = Hash.new
      end

    end


    def initialize_4(templateDir, templatePart, renderPage, configPs)
        @myPageToRender = renderPage
        this(templateDir,templatePart,renderPage)
        @configProperties = configPs
        configPropertiesSecond = Hash.new
    end


    def setTemplateConfig(config)
        @configPropertiesSecond = config
    end

    def setTemplate(template)
        @myTemplate = template
    end

    def setModuleToRender(mod)
      @myModuleToRender = mod
    end

    def parseTemplate

            if(@configProperties == nil)
                @configProperties = Hash.new
            end
            #puts "Page to render :#{@myPageToRender}"
            template = File.read(@myPart)
            #puts "------------------\n#{template}\n-----------------------------"
            if(template == nil)
                template = ""
            end

            if(@myModuleToRender != nil)
              moduleData = @myModuleToRender.getModuleData

              template = processKey("visible", "#{@myModuleToRender.isVisible}", template)
              template = processKey("id", "#{@myModuleToRender.moduleID}", template)
              #puts "-------------------Module Data----------------------\n#{moduleData}\n---------------------------"
              at = 0
              moduleData.keys.each{ |key|
                subData = moduleData[key]
                if(at == 0)
                  @configPropertiesSecond = subData
                  at = at.next
                end
                subData.keys.each{ |subkey|
                  replace = subData[subkey]
                  template = processKey(subkey, replace, template)
                }

              }

            end

            #puts "Template : #{template}"
            while(template.index("*IF(") != nil)
                puts "IF....."
                start = template.index("*IF(")
                #if(start > 0)
                #  start = start-1
                #end
                startIfB = start+4
                endIfB = template.index('{', startIfB)
                bend = template.index("*}*", start)-1
                check = template[startIfB..template.index(")", start)-1]
                key = nil
                if(check.index('|') != nil)
                  key = check[check.index('|')+1..check.size-1]
                  check = check[0..check.index('|')-1]
                  #puts "-----\nCheck: #{check}\nKey: #{key}\n------"
                end
                #puts "CHECK : #{check}"
                #puts "--------Config Props-------------\n#{@configProperties[check].strip != ""}\n------------------------------"
                if( (@configProperties.key?(check) && @configProperties[check].strip != "" &&
                        @configProperties[check].strip != "##Not-found##" &&
                        (key != nil && @configProperties[check] == key)) ||
                        (@configPropertiesSecond.key?(check) && @configPropertiesSecond[check].strip != "" &&
                        @configPropertiesSecond[check].strip != "##Not-found##"
                        (key != nil && @configPropertiesSecond[check] == key)) )



                    templateTmp = template
                    if(start == 0)
                      template = "#{templateTmp[endIfB+2..bend]}#{templateTmp[bend+4..templateTmp.size-1]}"
                    else
                      template = "#{templateTmp[0..start]}#{templateTmp[endIfB+1..bend]}#{templateTmp[bend+4..templateTmp.size-1]}"
                    end
                elsif(processIFKey(check))
                  templateTmp = template
                  if(start == 0)
                    template = "#{templateTmp[endIfB+1..bend]}#{templateTmp[bend+4..templateTmp.size-1]}"
                  else
                    template = "#{templateTmp[0..start]}#{templateTmp[endIfB+1..bend]}#{templateTmp[bend+4..templateTmp.size-1]}"
                  end
                  #template = "#{templateTmp[0..start]}#{templateTmp[endIfB+1..bend]}#{templateTmp[bend+4..templateTmp.size-1]}"
                else
                    templateTmp = template
                    #puts "Start: #{start}"
                    #puts "#{templateTmp[0..start]}#{templateTmp[bend+4..templateTmp.size]}"
                    if(start == 0)
                      template = "#{templateTmp[bend+4..templateTmp.size-1]}"
                    else
                      template = "#{templateTmp[0..start-1]}#{templateTmp[bend+4..templateTmp.size-1]}"
                    end
                    puts "Template:::: #{template}"
                end

            end

            #puts "------------------------\n#{@configProperties["TOP_LEVEL_MENU"]}\n----------------------------"

            #puts "configProperties : -----\n#{@configProperties}\n-----"
            if(@configProperties != nil && @configProperties.size > 0)
                @configProperties.keys.each{ |key|
                    replace = @configProperties[key]
                    #puts "configProperties : -----\n#{key}\n-----"
                    template = processKey(key, replace, template)
                }
            end
            if(@configPropertiesSecond != nil && @configPropertiesSecond.size > 0)
              @configPropertiesSecond.keys.each{ |key|
                  replace = @configPropertiesSecond[key]
                  template = processKey(key, replace, template)
              }
            end
            return template
    end

    def processIFKey(check)

        if(!check.start_with?("page;") && !check.start_with?("string;") &&
                !check.start_with?("file;") && !check.start_with?("class;") &&
                !check.start_with?("page_tag;") && !check.start_with?("global;"))

            return false
        end
        type = check[0..check.index(';')-1]
        key = check[check.index(';')+1..check.index('|')+1]
        value = check[check.index('|')+1..check.size-1]
        test = nil
        puts "---------\nType: #{type}\nKey: #{key}\nValue: #{value}\n-----------------"
        if(type == "global" )
          test = GlobalSettings.getGlobal(key)
        elsif(type == "page_tag")
            test = nil
            if(key == "title")
                test = @myPageToRender.title
            elsif(key == "author")
                test = @myPageToRender.author
            elsif(key == "description")
                test = @myPageToRender.description
            elsif(key == "keywords")
                test = @myPageToRender.keywords
            elsif(key == "owner")
                test = @myPageToRender.owner
            end

        #elsif(type == "file")
        #    part = TemplateFile.new(@myTemplateDir, replace, @myPageToRender)
        #    template = Parser.replaceAll(template, "*#{key}*", part.parseTemplate)
        #elsif(type == "page")

        elsif(type == "class")
          #TO-DO: Ok, need to think on this one
        end
        puts "Returning : #{(test != nil && test == value)}"
        return (test != nil && test == value)
    end




    # TO-DO: make private
    def processKey(key, replace, template)

        #puts "processKey : #{key} -- #{replace}"
        if(!replace.start_with?("page;") && !replace.start_with?("string;") &&
                !replace.start_with?("file;") && !replace.start_with?("class;") &&
                !replace.start_with?("page_tag;") && !replace.start_with?("global;"))

            replace = "string;#{replace}"
        end
        type = replace[0..replace.index(';')-1]
        replace = replace[replace.index(';')+1..replace.size-1]
        #puts "---------\nType: #{type}\nReplace: #{replace}\n-----------------"
        if(type == "string")
            template = Parser.replaceAll(template, "*#{key}*", replace)
        elsif(type == "global")
            template = Parser.replaceAll(template, "*#{key}*", GlobalSettings.getGlobal(replace))
        elsif(type == "page_tag")

            if(key == "title")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.title)
            elsif(key == "author")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.author)
            elsif(key == "description")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.description)
            elsif(key == "keywords")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.keywords)
            elsif(key == "owner")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.owner)
            end

        elsif(type == "file")
            part = TemplateFile.new(@myTemplateDir, replace, @myPageToRender)
            template = Parser.replaceAll(template, "*#{key}*", part.parseTemplate)
        elsif(type == "page")

          #tmpRenderer = @myTemplate.getRenderer
          #renderer = tmpRenderer.class.new#.loadPageContent(replace, @myPageToRender.webPath)
          #properties = PropertyLoader.new(GlobalSettings.getGlobal("Parent-PropertyFile"))
          #replace = renderer.renderOutput( tmpRenderer.myRequest, tmpRenderer.myResponse,
          #                                tmpRenderer.mySession, properties, replace,
          #                                tmpRenderer.myTheme, tmpRenderer.baseDocRoot, tmpRenderer.baseDocRootInc)

          #puts "Lets parse page: #{replace}"
          myreplace = @myTemplate.getRenderer().loadPageContent(replace, @myPageToRender.webPath)
          puts "Returned : #{myreplace}"
          template = Parser.replaceAll(template, "*#{key}*", myreplace)
        elsif(type == "class")

            #Object cl = Class.forName(replace).newInstance();
            #if(cl instanceof ContentReplacer)
            #{
            #    ContentReplacer cr = (ContentReplacer)cl;
            #    cr.setRequest(this.myTemplate.getHTMLRenderer().getRequest());
            #    cr.setResponse(this.myTemplate.getHTMLRenderer().getResponse());
            #    template = parser.replaceAllInString(template, "*"+key+"*",cr.getValue(this.myTemplateDir, this.myPageToRender, template, key, configProperties));
            #}
        end
        #TODO: add code to handle getting values from myPageToRender so that these values may be used to replace things in the template
        return template
    end
end
