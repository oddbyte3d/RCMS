 #  Description:     module for saving Objects to a Flat file System

require "yaml"
require "fileutils"
require_relative '../util/Parser'
require_relative './RepositoryObject'
require_relative "../xml/Tag"

# Implementation of a Safe that provides the
 # Functionality that a ObjectRepository needs
 # to save, retrieve, delete information from
 # a Repository that is implemented on the
 # FileSystem, It also provides methods to
 # save the Repository file itself.

class FileSafe

    @@FS = File::SEPARATOR
    @REPOSITORYPATHORSELECT = ""
    @DIR_NAME = ""
    @FILE_NAME = ""

    def initialize
    end


    def setRepositoryFile(fileOrField)

        @REPOSITORYFILEORFIELD = fileOrField
    end


    # Sets the path needed to retrieve the Repository
    # @param pathORSelect Path to Repository

    def setRepositoryPath(pathORSelect)
      @REPOSITORYPATHORSELECT = pathORSelect
      @FILE_NAME = @REPOSITORYPATHORSELECT[@REPOSITORYPATHORSELECT.rindex("/"),@REPOSITORYPATHORSELECT.size]
      #puts "FileSafe DIR: #{@DIR_NAME}"
      #puts "FileSafe FILE: #{@FILE_NAME}"
  end

    # Returns the path to the Repository
    # @return Path to the Repository

    def getRepositoryPath
        return @REPOSITORYPATHORSELECT
    end

    # Returns the name of the Repository file
    # @return name of the file

    def getRepositoryFile
        return @REPOSITORYFILEORFIELD
    end



    # Gets the Repository file from the
    # filesystem and returns it as a
    # HashMap that is needed by the
    # ObjectRepository which uses
    # this HashMap to link the Repository
    # ID's with the Repository files
    # @return HashMap that represents the Repository File

    def loadRepository

        @DIR_NAME = @REPOSITORYPATHORSELECT

        #puts "#{@DIR_NAME}  Index is... #{@DIR_NAME.index("/")}  : #{@@FS}"

    		if (@DIR_NAME.index("/") != nil && @@FS == "\\" )
    			@DIR_NAME = Parser.replaceAll(@DIR_NAME,"/",@@FS)
    		elsif( @DIR_NAME.index("\\") != nil && @@FS == "/")
    			@DIR_NAME = Parser.replaceAll(@DIR_NAME,"\\",@@FS)
        end

        #puts "1 dirname... #{@DIR_NAME}"

        @DIR_NAME = @DIR_NAME[0..@DIR_NAME.rindex(@@FS)]
        #puts "2 dirname... #{@DIR_NAME}"
    		@FILE_NAME = @REPOSITORYPATHORSELECT
        #puts "1 filename... #{@FILE_NAME}"
    		if( @FILE_NAME.index("/") != nil && @@FS == "\\")
    			@FILE_NAME = Parser.replaceAll(@FILE_NAME,"/",@@FS)
    		elsif( @FILE_NAME.index("\\") != nil && @@FS == "/")
    			@FILE_NAME = Parser.replaceAll(@FILE_NAME,"\\",@@FS)
        end
        #puts "2 filename... #{@FILE_NAME}"
        @FILE_NAME = @FILE_NAME[@FILE_NAME.rindex(@@FS)+1,@FILE_NAME.size]
        #puts "3 filename... #{@FILE_NAME}"

        #puts "loadRepository : #{@DIR_NAME}"
        if !File.exist?(@DIR_NAME)
          FileUtils.mkdir_p(@DIR_NAME)
        end
        if File.exist?(@DIR_NAME+@FILE_NAME)
          loadeOb = File.open(@DIR_NAME+@FILE_NAME).read
          @REPOSITORY = YAML::load(loadeOb)
        else
          @REPOSITORY = Hash.new
        end
        return @REPOSITORY
    end

    # Saves an object to the Repository
    # (in this case to the fileSystem)
    # @param objectName Unique Name of the Object to be saved to
    # the Repository
    # @param toSave Object to be saved to the Repository
    # @return String defining the
    # Object (here it is the
    # FilePath)

    def saveRepositoryObject(objectName, toSave)

      #puts "saveRepositoryObject : #{@DIR_NAME}#{@FILE_NAME}_Contents#{@@FS}"
      if !File.exist? ("#{@DIR_NAME}#{@FILE_NAME}_Contents#{@@FS}")
        FileUtils.mkdir_p("#{@DIR_NAME}#{@FILE_NAME}_Contents#{@@FS}")
      end
      saveFile("#{@DIR_NAME}#{@FILE_NAME}_Contents#{@@FS}#{objectName}.obj", toSave)
      return "#{@DIR_NAME}#{@FILE_NAME}_Contents#{@@FS}#{objectName}"

    end

    # Attempts to delete the Object described
    # in the Parameter path
    # @param path Path of the Object to remove

    def deleteRepositoryObject(path)
      begin
        File.delete(path+".obj")
      rescue DefaultException => e
        puts "Failed to delete repository object : #{path}"
      end
    end

    # Attempts to find, load and
    # Return the Object Described
    # by path
    # @param path Path of the object to load
    # @return Loaded Object
    def loadRepositoryObject(path)
      #puts "loadRepositoryObject :: #{path}"
      if File.exist?("#{path}.obj")
        loadeOb = File.open("#{path}.obj").read
        repObj = YAML::load(loadeOb)
        return repObj
      else
        return nil
      end
    end

    def compareObject(toCompare, pathToCompareWith)
        return true
    end


    # Saves the ObjectRepository file to
    # the filesystem
    # @param Repository HashMap that represents the ObjectRepository
    def saveRepository(repository)
        saveFile("#{@DIR_NAME}#{@FILE_NAME}", repository)
    end

    # Attempts to save an Object to
    # the filesystem
private
    def saveFile(path, toSave)
      begin
        content = YAML::dump(toSave)
        File.write(path, content)
      rescue DefaultException => e
        puts "Failed to save repository file : #{toSave}"
      end

    end

    # Returns the inhalt of a file
    # as a byte array that can be
    # then Deserialized to an Object

    def readFile(fileName)
      begin
        fContent = File.open(fileName).read
      rescue DefaultException => e
        puts "Reading repository file failed :#{fileName}"
      end
    end

end
