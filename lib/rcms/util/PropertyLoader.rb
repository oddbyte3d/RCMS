require_relative './Parser'
# this class loads property files based on a parent property file

class PropertyLoader < Hash


#    def initialize
#      puts "Config Path: #{GlobalSettings.getGlobal('Server-ConfigPath')}"

#        @CONFIG_ROOT = GlobalSettings.changeFilePathToMatchSystem(GlobalSettings.getGlobal("Server-ConfigPath"))
#        @MY_ORIGINAL_PROPS = Hash.new
#        @FS = File::SEPARATOR
#    end

    # The Parent Property file contains the paths for the child property files
    # @param parentPropertyFile Parent-Property File

    def initialize(parentPropertyFile)
      @CONFIG_ROOT = GlobalSettings.changeFilePathToMatchSystem(GlobalSettings.getGlobal("Server-ConfigPath"))
      @MY_ORIGINAL_PROPS = Hash.new
      @dirsChecked = Array.new
      @FS = File::SEPARATOR
      #puts "Parent to load: #{parentPropertyFile}"
      setParentPropertyFile(parentPropertyFile)

    end

    def loadDirectoryContents(dirContents)
        if(!dirContents.end_with?(@FS))
          dirContents.concat(@FS)
        end
        if(@dirsChecked.any? { |s| s == dirContents })
          #puts "Already done: #{dirContents}"
          return
        end


        #puts "load from : #{dirContents}"
        Dir.chdir(dirContents)
        contents = Dir.glob("*")
        @dirsChecked << dirContents
        #puts "Contents: #{contents}"
        Dir.chdir("..")
        #java.util.Arrays.sort(contents);
        if contents != nil
            for i in 0..contents.size
                #puts "Check: #{dirContents}#{contents[i]}"
                if File.directory?("#{dirContents}#{contents[i]}")

                    loadDirectoryContents("#{dirContents}#{contents[i]}")

                elsif(File.file?("#{dirContents}#{contents[i]}") && File.basename("#{dirContents}#{contents[i]}").end_with?(".yaml"))

                    fullModName = File.basename("#{dirContents}#{contents[i]}")
                    modName = fullModName[0..fullModName.index(".yaml")-1]
                    #fullPath = File.absolute_path(contents[i])
                    #fullPath = Parser.replaceAll(fullPath, @CONFIG_ROOT, "")
                    self.store(modName, "#{dirContents}#{contents[i]}")
                end
            end
          end
    end


    # Setzt das Parent-Property File und laedt die Child-Propery Files
    # @param parentPropertyFile Parent-Property File

    def setParentPropertyFile(parentPropertyFile)

        @PARENT_PROPERTY_FILE = @CONFIG_ROOT+GlobalSettings.changeFilePathToMatchSystem(parentPropertyFile)
        #puts "--Try to load: #{@PARENT_PROPERTY_FILE}"
        #java.io.File fileToLoad = new java.io.File(configRoot+this.parentPropertyFile);

        if File.exist?(@PARENT_PROPERTY_FILE)

            if File.directory?(@PARENT_PROPERTY_FILE)
                loadDirectoryContents(@PARENT_PROPERTY_FILE)
            else
              tmpHash = YAML.load_file(@PARENT_PROPERTY_FILE)
              #puts "\n\nParent Hash: #{tmpHash}\n\n"

              tmpHash.keys.each{ |key|
                self[key] = tmpHash[key]
              }

              #puts "After merge......#{self}"
            end

            tmpPath = nil

            for key in self.keys
                nextPath = self[key]
                loadPath = ""
                properties = Hash.new
                if File.exist?(nextPath)
                    loadPath = File.absolute_path(nextPath)
                    @MY_ORIGINAL_PROPS[key] = loadPath
                else
                    loadPath = self[key]

                    @MY_ORIGINAL_PROPS[key] = loadPath
                    if loadPath.index('/') != nil && @FS == "\\"
                        loadPath = Parser.replaceAll(loadPath,"/",@FS)
                    elsif loadPath.index('\\') != nil && @FS == "/"
                        loadPath = Parser.replaceAll(loadPath,"\\",@FS)
                    end
                    tmpPath = loadPath
                    loadPath = @CONFIG_ROOT+loadPath
                end
                if loadPath != nil
                    #File loading = new File(loadPath);

                    properties = YAML.load_file(loadPath)
                    parentDir = File.dirname(loadPath)
                    if File.directory?(parentDir)
                      #puts "#{properties} setting ParentDirectory -- #{File.basename(parentDir)}"
                      properties["ParentDirectory"] = File.basename(parentDir)
                    end
                    self[key] = properties
                end
            end
        end
    end

    # Gibt das Parent-Property File als String zurueck
    # @return String des Parent-Property Files

    def getProperties(name)
        if self[name].is_a? String
          #puts "going to try to load : #{name}"
          properties = loadPropertyFile(name)
          self[name] = properties

        elsif(self[name].is_a? Hash)
            return self[name]
        end
        puts "Error loading properties file from #{@PARENT_PROPERTY_FILE} : #{name}"
        return nil
    end

     # Gibt das Parent-Property File als String zurueck
     # @return String des Parent-Property Files

    def getParentPropertyFile
	     return @PARENT_PROPERTY_FILE
    end


    def loadPropertyFile(name)

      if self[name].is_a? String
        properties = Hash.new
        nextPath = self[name]
        @MY_ORIGINAL_PROPS[name] = nextPath
        if nextPath.index('/') != nil && @FS == "\\"
          nextPath = Parser.replaceAll(nextPath,"/",@FS)
        elsif nextPath.index('\\') != nil && @FS == "/"
          nextPath = Parser.replaceAll(nextPath,"\\",@FS)
        end
        tmpHash = YAML.load_file(@CONFIG_ROOT + nextPath)
        puts "\n\nloaded: #{tmpHash}\n\n"
        properties.merge(tmpHash)
        return properties
      end
      return nil
    end

     # Liefert den gesuchten Wert des Properties zurueck
     # @param parentKey Key des gesuchten Child-Property Files
     # @param childKey Key des Properties im Child-Property File
     # @return gesuchte Property als String

    def getProperty(parentKey, childKey)
        name = parentKey
        if self[name].is_a? String
          properties = loadPropertyFile(name)
          self[name] = properties
        end
        if self[parentKey] != nil && self[parentKey].is_a?(Hash)
          tmpp = self[parentKey]

          return tmpp[childKey]
        else
          return nil
        end
    end

     # Setzt den Wert innerhalb eines Child-Property Files unter dem childKey
     # @param parentKey Key in welches Child-Property File geschrieben werden soll
     # @param childKey Key unter dem der Wert innerhalb des Child-Property Files gespeichert wird
     # @param childValue Wert, der gespeichert werden soll

    def setProperty(parentKey, childKey, childValue)
      if self[parentKey].is_a? Hash
        tmpp = self[parentKey]
        tmpp[childKey] = childValue
       end
    end

    def getOriginalValue(name)
        return @MY_ORIGINAL_PROPS[name]
    end
end
