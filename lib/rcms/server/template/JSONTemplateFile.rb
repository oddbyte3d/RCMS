
require_relative "../../Page"
require_relative "../GlobalSettings"
require_relative "../../util/Parser"
require_relative "./Template"
require "erb"

class ERBContext
  def initialize(hash)
    puts "Init ERBContext : #{hash}"
    hash.each_pair do |key, value|
      instance_variable_set('@' + key.to_s, value)
    end
  end

  def get_binding
    binding
  end
end

class JSONTemplateFile


    def initialize(*args)

      @myPart = ""
      @myTemplateDir = args[0]
      @myTemplate = nil
      @myJSONToRender = nil
      @myModuleToRender = nil
      @myPageToRender = nil

      if(args.size == 3)
          initialize_3(args[0], args[1], args[2])
      else
          initialize_4(args[0], args[1], args[2], args[3])
      end

    end

    def initialize_3(templateDir, templatePart, renderJSON)
      @myJSONToRender = renderJSON
      puts "template : #{templatePart}"
      if(File.exist?(templatePart))
          @myPart = GlobalSettings.changeFilePathToMatchSystem(templatePart)
          @myPartConfig = "#{@myPart}.yaml"
          puts "myPartConfig : #{@myPartConfig}"
          if(File.exist?(@myPartConfig))
              @configProperties = YAML.load_file(@myPartConfig)
          end
          @configPropertiesSecond = Hash.new
      end

    end


    def initialize_4(templateDir, templatePart, renderJSON, pageToRender)
      @myJSONToRender = renderJSON
      @myPageToRender = pageToRender
      puts "template : #{templatePart}"
      if(File.exist?(templatePart))
          @myPart = templatePart
          @myPartConfig = "#{@myPart}.yaml"
          puts "myPartConfig : #{@myPartConfig}"
          if(File.exist?(@myPartConfig))
              @configProperties = YAML.load_file(@myPartConfig)
          end
          @configPropertiesSecond = Hash.new
      end
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

    def setModuleToRender(mod)
      @myModuleToRender = mod
    end
    def setModuleData(modData)
      @moduleData = modData
    end

    def parseTemplate

            if(@configProperties == nil)
                @configProperties = Hash.new
            end
            test = "mytest..."
            parameters = Hash.new
            template = File.read(@myPart)
            if(template == nil)
                template = ""
            end

            if(@moduleData != nil)
              at = 0
              @moduleData.keys.each{ |key|
                #puts "Processing mod data: #{key} ::::::: #{@moduleData[key]}"
                subData = @moduleData[key]
                if subData.is_a? Array
                  #The following is exposed to the ERB template
                  parameters["#{key}"] = subData
                else
                    template = processKey(key, @moduleData[key], template)
                end
              } if @moduleData != nil

            end
            while(template.index("*IF(") != nil)
                start = template.index("*IF(")
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
                    if(start == 0)
                      template = "#{templateTmp[bend+4..templateTmp.size-1]}"
                    else
                      template = "#{templateTmp[0..start-1]}#{templateTmp[bend+4..templateTmp.size-1]}"
                    end
                    #puts "Template:::: #{template}"
                end

            end
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
                puts "Config properties second::::::::::::#{@configPropertiesSecond}"
              end
            end

            #puts "ERBContext parameters:: #{parameters}"
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


    def processIFKey(check)

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
        puts "processKey : #{key} -- #{replace}"
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
        elsif(type == "page_tag" && @myPageToRender != nil)
            #puts "------>>>>>>>>>>>>>>>Processing page tag: ::#{key}::"
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
              elsif(replace == "cache")
                  template = Parser.replaceAll(template, "*#{key}*", "#{@myPageToRender.CACHE}")
            end
          elsif(type == "page_tag" && @myPageToRender == nil)

              if(replace == "title")
                  template = Parser.replaceAll(template, "*#{key}*", "No title given")
              elsif(replace == "author")
                  template = Parser.replaceAll(template, "*#{key}*", "")
              elsif(replace == "description")
                  template = Parser.replaceAll(template, "*#{key}*", "")
              elsif(replace == "keywords")
                  template = Parser.replaceAll(template, "*#{key}*", "")
              elsif(replace == "owner")
                  template = Parser.replaceAll(template, "*#{key}*", "")
                elsif(replace == "cache")
                    template = Parser.replaceAll(template, "*#{key}*", "true")
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
