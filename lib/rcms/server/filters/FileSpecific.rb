require_relative "./OutputFilter"
require_relative "../GlobalSettings"
require_relative "../file/FileCMS"
require "yaml"

class FileSpecific < OutputFilter

  def initialize(session)
    @session = session
    #@configFile = YAML.load(FileCMS.new(session, "#{GlobalSettings.getDocumentConfigDirectory()}#{@@FS}Filters/FileSpecific.yaml").getFileForRead.read)
    #puts "GlobalWordMatch settings: #{@configFile}"
  end

  def filterOutput(request, response, session, input)


    if(request["requested_path"] != nil)
      #puts "\n\n__________________________________________________\n#{request}\n________________________________________________"
      begin
        fileConfig = GlobalSettings.getCurrentWorkArea(session)+request["requested_path"]+".specific.yaml"
        fileConfig = GlobalSettings.changeFilePathToMatchSystem(fileConfig)
        fcms = FileCMS.new(session, fileConfig)
        @configFile = YAML.load(fcms.getFileForRead.read)
        #puts "\n\n========FileSpecific filter===========\n#{@configFile}\n=============================="
        @configFile.keys.each{ |key|
          input = processKey(key, @configFile[key], input)
          #input = Parser.replaceAll(input, key, @configFile[key])
        }
      rescue
        #Don't need to do anything...
      end
    end
    return input #"Filtered ;P"
  end
  def getFilterDescription
    return "FileSpecific, replaces instances of strings with others"
  end
  def getConfigurationFile
    return @configFile
  end

  # Need to expand the possibilities
  def processKey(key, replace, template)

      #puts "processKey : #{key} -- #{replace}"
      if(!replace.start_with?("page;") && !replace.start_with?("string;") &&
              !replace.start_with?("file;") && !replace.start_with?("class;") &&
              !replace.start_with?("page_tag;") && !replace.start_with?("global;") &&
              !replace.start_with?("user;"))

          replace = "string;#{replace}"
      end
      type = replace[0..replace.index(';')-1]
      replace = replace[replace.index(';')+1..replace.size-1]
      #puts "---------\nType: #{type}\nReplace: #{replace}\n-----------------"
      if(type == "string")
          template = Parser.replaceAll(template, "#{key}", replace)
      elsif(type == "global")
          template = Parser.replaceAll(template, "#{key}", GlobalSettings.getGlobal(replace))
      elsif(type == "user")
        begin
          user = RCMSUser.new(GlobalSettings.getUserLoggedIn(@session))
          template = Parser.replaceAll(template, "#{key}", user.getUserField(replace))
        rescue
          puts "No user: #{user}"
        end
      end
      #TODO: add code to handle getting values from myPageToRender so that these values may be used to replace things in the template
      return template
  end


end
