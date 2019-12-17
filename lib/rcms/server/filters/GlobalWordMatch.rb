require_relative "./OutputFilter"
require_relative "../../util/Parser"
require "yaml"

class GlobalWordMatch < OutputFilter

  def initialize(session)
    @session = session
    @configFile = YAML.load(FileCMS.new(session, "#{GlobalSettings.getDocumentConfigDirectory()}#{@@FS}Filters/GlobalWordMatch.yaml").getFileForRead.read)
    puts "GlobalWordMatch settings: #{@configFile}"
  end

  def filterOutput(request, response, session, input)
    @configFile.keys.each{ |key|
      input = Parser.replaceAll(input, key, @configFile[key])
    }

    return input #"Filtered ;P"
  end
  def getFilterDescription
    return "GlobalWordMatch, replaces instances of strings with others"
  end
  def getConfigurationFile
    return @configFile
  end


end
