require_relative "./TemplateFile"
require_relative "../../Page"
require_relative "../GlobalSettings"
require_relative "../user/RCMSUser"
require_relative "../../util/Parser"
require_relative "./JSONTemplateFile"
require "yaml"

class JSONTemplate

    @@FS = File::SEPARATOR

    def initialize(templateDir, renderJSON, page)
        @myPage = page
        @configName = "template.yaml"
        @myConfig = Hash.new
        @myFileList = Array.new
        @myParsedTemplate = ""
        @myModuleTemplates = Hash.new

        @myTemplateDir = templateDir
        #@myPageToRender = renderPage
        @myJSONToRender = renderJSON
        @myRenderer = nil

        if(File.exist?(@myTemplateDir) && File.directory?(@myTemplateDir))

            config = "#{@myTemplateDir}#{@@FS}#{@configName}"
            #puts "---------------------------------------Config : #{config}"
            if(File.exist?(config))

                @myConfig = YAML.load_file(config)
                #puts "@myConfig : #{@myConfig}"
                if(@myConfig.key?("module_templates"))

                    modConf = Hash.new
                    modConfPath = GlobalSettings.changeFilePathToMatchSystem(
                            "#{@myTemplateDir}#{@@FS}#{@myConfig["module_templates"]}")
                    #puts "\n---------Check Module Path----------------\n#{modConfPath}\n-------------------------------------"
                    if(File.exist?(modConfPath) && !File.directory?(modConfPath))

                        modConf = YAML.load_file(modConfPath)
                        mainPath = modConfPath[0..modConfPath.rindex(@@FS)]
                        #puts "Main Path: #{mainPath}"
                        #puts "\n-------keys-------\n#{modConf.keys}\n------------------"
                        modConf.keys.each{ |key|
                            #puts "Next key : #{key}"
                            val = modConf[key]
                            tempTempl = "#{mainPath}#{val}"
                            #puts "module template path: #{tempTempl}"
                            if(File.exist?(tempTempl))
                                modTmp = JSONTemplateFile.new(@myTemplateDir, tempTempl, @myJSONToRender, @myPage)
                                modTmp.setAdditionalParameters(@params) if @params != nil
                                @myModuleTemplates[key] = modTmp
                            end
                        }
                        puts "----------------------------------------------\nloaded module templates: \n#{@myModuleTemplates.keys}\n-------------------------------------------------------------------"
                    end
                end
            end
        end

    end

    def setAdditionalParameters(params)
      @params = params
    end


    def getRenderer
      return @myRenderer
    end

    def setRenderer(render)
      @myRenderer = render
    end

    def hasModuleTemplates
        return (@myModuleTemplates != nil && @myModuleTemplates.size > 0)
    end

    def containsModuleTemplate(moduleName)
        return (@myModuleTemplates != nil && @myModuleTemplates.key?(moduleName))
    end

    def getModuleTemplate(moduleName)
        if(@myModuleTemplates != nil && @myModuleTemplates.key?(moduleName))
            return @myModuleTemplates[moduleName]
        else
            return nil
        end
    end

    def getParsedTemplate

        if(File.exist?(@myTemplateDir) && File.directory?(@myTemplateDir))

            if(@myConfig != nil)

                start = 0
                while(@myConfig.key?("_#{start}"))

                    tf = JSONTemplateFile.new(@myTemplateDir,
                        "#{@myTemplateDir}#{@@FS}#{@myConfig["_#{start}"]}",
                        @myPageToRender, @myPage)
                    tf.setAdditionalParameters(@params) if @params != nil
                    tf.setTemplate(self)
                    parsed = tf.parseTemplate
                    #puts "Parsed Template : #{parsed}"
                    if(parsed != nil)
                        @myParsedTemplate.concat(parsed)
                    end
                    start = start.next
                end

            end
        end

        @myParsedTemplate = JSONTemplate.filterOutput(nil, @params, @myParsedTemplate)

        return @myParsedTemplate
    end


     # Parses the input and replaces instances of specific tags.
     # @param input
     # @return
    def self.filterOutput(user, otherFields, input)

      #puts "Filteroutput :::: #{otherFields}"
        globals = GlobalSettings.getAllGlobals
        globals.each{ |key|
            if(key.is_a?(String))

                if(globals[key].is_a?(String))

                    if(input.index("*#{nextKey}*") != nil)
                        input = Parser.replaceAll(input, "*#{nextKey}*", globals[key])
                    end
                end
            end
        }
        if(otherFields != nil)
            otherFields.keys.each{ |key|
                while( input.index("*#{key}*") != nil)
                    input = Parser.replaceAll(input, "*#{key}*", otherFields[key])
                end
            }
        end

        if(user != nil && user.getUserName() != "guest")

            if(input.index("*USER_NAME*") != nil)
                input = Parser.replaceAll(input, "*USER_NAME*", "#{user.getUserFName()} #{user.getUserLName()}")
            end
            if(input.index("*USER_EMAIL*") != nil)
                input = Parser.replaceAll(input, "*USER_EMAIL*", user.getUserEmail())
            end
            while(input.index("*USER_FIELD:") != nil)

                beg = input.index("*USER_FIELD:")
                bend = input.index(":*", beg+11)+1
                replace = input[beg..bend]
                field = input[beg+11, bend-1]
                #puts "Template 144 replace :#{replace}: field :#{field}:"

                field = user.getUserField(field)
                if(field == nil)
                    field = ""
                end
                input = Parser.replaceAll(input, replace, field)
            end
        else

            if(input.index("*USER_NAME*") != nil)
                input = Parser.replaceAll(input, "*USER_NAME*", "Guest")
            end
            if(input.index("*USER_EMAIL*") != nil)
                input = Parser.replaceAll(input, "*USER_EMAIL*", "");
            end
            while(input.index("*USER_FIELD:") != nil)
                beg = input.index("*USER_FIELD:")
                bend = input.index(":*", beg+11)+1
                replace = input.substring(beg, bend);
                field = input[beg+11, bend-1]
                #puts "Template 177 replace :#{replace}: field :#{field}:"

                input = Parser.replaceAll(input, replace, "")
            end

        end

        if(input.index("*DATE(") != nil)
            while(input.indexOf("*DATE(") > -1)
                start = input.index("*DATE(")+5
                send = input.index(")*",start)
                format = input[start..send]
                #puts "Template 189 Date Format to use: #{format}"
                full = input[start-5,send+1]
                input = Parser.replaceAll(input, full, GlobalSettings.formatDate(format, nil))
            end
        end
        if(input.index("*DATE*") != nil)
            input = Parser.replaceAll(input, "*DATE*", GlobalSettings.formatDate(GlobalSettings.FORMAT_DATE_DAY, nil))
        end
        if(input.index("*DATE_TIME*") != nil)
            input = Parser.replaceAll(input, "*DATE_TIME*", GlobalSettings.formatDate(GlobalSettings.FORMAT_DATE_DAY_TIME, nil))
        end
        if(input.index("*TIME*") != nil)
            input = Parser.replaceAll(input, "*TIME*", GlobalSettings.formatDate(GlobalSettings.FORMAT_DATE_TIME, nil))
        end



        return input
    end


end
