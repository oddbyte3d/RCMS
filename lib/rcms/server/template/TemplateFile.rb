$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), './lib/' ) )
require_relative "../../Page"
require_relative "../GlobalSettings"
require_relative "../../util/Parser"
require_relative "./Template"
require "erb"

class ERBContext
  def initialize(hash)
    #puts "Init ERBContext : #{hash}"
    hash.each_pair do |key, value|
      instance_variable_set('@' + key.to_s, value)
    end
  end

  def get_binding
    binding
  end
end

class TemplateFile


    def initialize(*args)

      @myPart = ""
      @myTemplateDir = args[0]
      @myTemplate = nil
      @myPageToRender = nil
      @myModuleToRender = nil
      @mySession = nil
      @myRequest = nil

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
        initialize_3(templateDir,templatePart,renderPage)
        @configProperties = configPs
        configPropertiesSecond = Hash.new
    end

    def setAdditionalParameters(params)
      @params = params
    end

    def setTemplateConfig(config)
        @configPropertiesSecond = config
    end

    def setTemplate(template)
        @myTemplate = template
    end

    def setSession(session)
      puts "Setting Session::::::::: #{@mySession}"
      @mySession = session
    end

    def setRequest(request)
      @myRequest = request
    end


    def setModuleToRender(mod)
      @myModuleToRender = mod
    end

    def parseTemplate

            if(@configProperties == nil)
                @configProperties = Hash.new
            end
            #test = "mytest..."
            parameters = Hash.new
            #puts "Page to render :#{@myPageToRender}"
            template = File.read(@myPart)
            puts "------------------\n#{@configProperties}\n-----------------------------"
            if(template == nil)
                template = ""
            end

            while(template.index("*IF(") != nil)
                #puts "IF....."
                start = template.index("*IF(")
                #if(start > 0)
                #  start = start-1
                #end
                startIfB = start+4
                endIfB = template.index('){*', startIfB)+2
                bend = template.index("*}*", start)-1
                check = template[startIfB..template.index("){*", start)-1]
                key = nil
                if(check.index('|') != nil)
                  key = check[check.index('|')+1..check.size-1]
                  check = check[0..check.index('|')-1]
                  puts "-----\nCheck: #{check}\nKey: #{key}\n------"
                end
                #puts "CHECK : #{check}"
                #puts "--------Config Props-------------\n#{@configProperties[check].strip != ""}\n------------------------------"
                # Next check is to see if an empty or !empty case is requested, well I guess the !empty case is handled above....
                if( (!@configProperties.key?(check) && key == "[empty]") || (@configProperties.key?(check) && @configProperties[check].strip == "" && key == "[empty]") ||
                          (@configProperties.key?(check) && key == "[!empty]" && @configProperties[check].strip != ""))

                          puts "\n------Found Empty Check:::: #{key}-------------"
                          templateTmp = template
                          if(start == 0)
                            template = "#{templateTmp[endIfB+2..bend-1]}#{templateTmp[bend+6..templateTmp.size-1]}"
                          else
                            template = "#{templateTmp[0..start-1]}#{templateTmp[endIfB+2..bend-1]}#{templateTmp[bend+6..templateTmp.size-1]}"
                          end
                elsif( (@configProperties.key?(check) && @configProperties[check].strip != "" &&
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




                elsif(processIFKey(check, key))
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
                    #puts "Template:::: #{template}"
                end

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
                if subData.is_a? Array
                  #The following is exposed to the ERB template
                  parameters[key] = subData

                else
                  subData.keys.each{ |subkey|
                    replace = subData[subkey]
                    template = processKey(subkey, replace, template)
                  }
                end
              }

            end

            #puts "Template : #{template}"


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
              if @configPropertiesSecond.is_a? Array
                #TO-DO: implement functionality to process multiple data elements
              else
                @configPropertiesSecond.keys.each{ |key|
                    replace = @configPropertiesSecond[key]
                    template = processKey(key, replace, template)
                }
              end
            end


            b = ERBContext.new( parameters)
            erb = ERB.new(template)
            template = erb.result(b.get_binding)

            if @params != nil
              @params.keys.each{ |key|
                template = processKey(key, @params[key], template)
              }
            end

            return template
    end



    def processIFKey(check, key)

        if(!check.start_with?("page;") && !check.start_with?("string;") &&
          !check.start_with?("file;") && !check.start_with?("class;") && !check.start_with?("global;"))

            return false
        end
        type = check[0..check.index(';')-1]
        key = check[check.index(';')+1..check.index('|')+1]
        value = check[check.index('|')+1..check.size-1]
        test = nil
        #puts "---------\nType: #{type}\nKey: #{key}\nValue: #{value}\n-----------------"
        if(type == "global" )
          test = GlobalSettings.getGlobal(key)
        elsif(type == "page")
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
        #puts "Returning : #{(test != nil && test == value)}"
        return (test != nil && test == value)
    end




    # TO-DO: make private
    def processKey(key, replace, template)
        #puts "What?? :::::::::::::: #{key} ==== #{replace}"
        if !replace.is_a? String
          return template
        end
        #puts "processKey : #{key} -- #{replace}"
        if(!replace.start_with?("page;") && !replace.start_with?("string;") &&
                !replace.start_with?("file;") && !replace.start_with?("class;") &&
                !replace.start_with?("page_tag;") && !replace.start_with?("global;"))

            replace = "string;#{replace}"
        end

        type = replace[0..replace.index(';')-1]
        replace = replace[replace.index(';')+1..replace.size-1]
        #puts "---------\nKey: #{key}\nReplace: #{replace}\n-----------------"
        if(type == "string")
            template = Parser.replaceAll(template, "*#{key}*", replace)
        elsif(type == "global")
            template = Parser.replaceAll(template, "*#{key}*", GlobalSettings.getGlobal(replace))
        elsif(type == "page_tag")

            if(replace == "title")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.title)
            elsif(replace == "author")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.author)
            elsif(replace == "description")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.description)
            elsif(replace == "keywords")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.keywords)
            elsif(replace == "owner")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.owner)
            elsif(replace == "url")
                template = Parser.replaceAll(template, "*#{key}*", @myPageToRender.webPath)
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
          #puts "Returned : #{myreplace}"
          template = Parser.replaceAll(template, "*#{key}*", myreplace)
        elsif(type == "class" && @myTemplate != nil)

          className = replace
          load = replace
          parameters = []
          if className.index("(") != nil
            className = className[0..className.index("(")-1]
            load = className
            tmpParms = replace[replace.index("(")+1..replace.index(")")-1]
            parameters = tmpParms.split(",")
          end
          className = className[className.rindex("/")+1..className.size]

          puts "Class To Load : #{load} #{parameters}"
          require_relative(load)

          cr = Kernel.const_get(className).new(*parameters)
          if(cr.is_a?(GenericContent))
            cr.setRequest(@myRequest)
            cr.setSession(@mySession)
            template = Parser.replaceAll(template, "*#{key}*",
              cr.getValue(@myTemplateDir, @myPageToRender, @myTemplate, key, @configProperties))
          end
        end
        #TODO: add code to handle getting values from myPageToRender so that these values may be used to replace things in the template
        return template
    end
end
