require_relative "./FileSafe"
require_relative "./ObjectRepositoryTimer"

class ObjectRepository

    attr_reader :REPOSITORY_ID
    # This is the Repository list it holds the keys between
    # the Object ID and the Object itself

    def initialize(safeClass)
      @SAFE_CLASS = safeClass
      @MY_SAFE = Object::const_get(@SAFE_CLASS).new
      @REFRESH_RATE = 30
      self.initRepository
    end

    def setRefresh (refreshRate)
      @REFRESH_RATE = refreshRate
      #initRepository
    end

    def initRepository
      @REPOSITORY = Hash.new
      @REPOSITORY_MEMORY = Hash.new
      @REPOSITORY_ID = String.new

      @MY_SAFE = Object::const_get(@SAFE_CLASS).new


        @TIMER = ObjectRepositoryTimer.new
        if !@TIMER.IS_RUNNING
        	@TIMER.setRefresh(@REFRESH_RATE)
        end
    end

    # Saves the Repository to file or DB or whatever is done in the
    # implementation of ObjectSafe

    def saveRepository
	     @MY_SAFE.saveRepository(@REPOSITORY)
    end

    #------------------------------------------------------------------
    # Sets the path and file for the Repository (Can be done at runtime)
    # @param pathORSelect This Parameter is the Path to the specific Repository or a table name in a DB etc...(Use your Imagination)
    # @param fileORField This is the file that represents the Repository(Could also be in a Table in a DB etc...)

    def setObjectRepository(pathORSelect, fileORField)

    	@MY_SAFE.setRepositoryFile(fileORField)
    	@MY_SAFE.setRepositoryPath(pathORSelect)
      loadRepository
      if !@REPOSITORY.key?("repositoryID")
          #puts "Setting repositoryID : #{fileORField}"
          @REPOSITORY_ID = fileORField
          @REPOSITORY["repositoryID"] = @REPOSITORY_ID
          @MY_SAFE.setRepositoryFile(fileORField)

      else

          @REPOSITORY_ID = @REPOSITORY["repositoryID"]
          @MY_SAFE.setRepositoryFile(@REPOSITORY_ID)
      end
    end


    # Returns the full path or select that represents where the repository is to be found
    # @return Full path to the repository

    def getObjectRepsoitory
	     return "#{@MY_SAFE.getRepositoryPath}#{@MY_SAFE.getRepositoryFile}"
    end


    # Saves an Object to the Object Repository
    # using a unique ID to identify the Object
    # @param objectToSaveName unique name to represent the Object
    # @param objectToSave Object to save

    def commitObject(objectToSaveName, objectToSave, cache)

        if(objectToSave != nil && objectToSaveName != nil)

            repOb = RepositoryObject.new(objectToSave,cache)
            if(cache)
                @REPOSITORY_MEMORY[objectToSaveName] = repOb
            end
            path = @MY_SAFE.saveRepositoryObject(objectToSaveName,repOb)
            @REPOSITORY[objectToSaveName] = path
	          @MY_SAFE.saveRepository(@REPOSITORY)
        end
    end


    # Loads the repository on hand from the information
    # provided from the creator

    def loadRepository
        @REPOSITORY = @MY_SAFE.loadRepository
        validateCache
    end

    # Returns a list(Set) of ID's that are in the repository
    # @return List of Object ID's within the repositoy

    def getRepositoryKeys
        return @REPOSITORY.keys
    end

    # Removes an Object from the Repository using the ID
    # @param objectID Object ID

    def removeRepositoryObject(objectID)
        if(@REPOSITORY.key?(objectID))

            @REPOSITORY_MEMORY.delete(objectID)
	          @MY_SAFE.deleteRepositoryObject(@REPOSITORY[objectID])
            @REPOSITORY.delete(objectID)
	          @MY_SAFE.saveRepository(@REPOSITORY)
        end
    end

    def hasKey(objectID)
      return @REPOSITORY.key? objectID
    end

    # Returns an object from the Repository
    # if found if not then returns null
    # @param objectID Id from the object to get out of the Repository
    # @return Object from the Repository

    def getRepositoryObject(objectID)
        if(!checkMemoryCacheForObject(objectID))

            objectFileName = @REPOSITORY[objectID]
            return @MY_SAFE.loadRepositoryObject(objectFileName)
        else
            return @REPOSITORY_MEMORY[objectID]
        end
    end


    #private
    def getRepositoryObjectNoCache(objectID)
        return @MY_SAFE.loadRepositoryObject(@REPOSITORY[objectID])
    end

    def addToMemoryCache(objName, obj)
        @REPOSITORY_MEMORY[objName] = obj
    end

    def removeFromMemoryCache(objName)
        @REPOSITORY_MEMORY.delete(objName)
    end

    def checkMemoryCacheForObject(objName)
        return @REPOSITORY_MEMORY.key?(objName)
    end

    def getObjectFromMemoryCache(objName)
        return @REPOSITORY_MEMORY[objName]
    end
    #end private

    def refreshObjectInMemoryCache(objName)
        @REPOSITORY_MEMORY.delete(objName)
        @REPOSITORY_MEMORY[objName] = getRepositoryObjectNoCache(objName)
    end

    def refreshMemoryCache

        memKeys = @REPOSITORY_MEMORY.keys
        @REPOSITORY_MEMORY.clear
        memKeys.each{ |key|
          refreshObjectInMemoryCache(key)
        }
    end

    def listObjectsCached
        return @REPOSITORY_MEMORY.keys
    end

    def run
    	validateCache()
    end

    #private
    def validateCache

        if @REPOSITORY != nil
            keySet = @REPOSITORY.keys

            keySet.each { |key|
              repToCheck = getRepositoryObjectNoCache(key)
              if(repToCheck != nil && repToCheck.IS_MEMORY_CACHED)
                if(@REPOSITORY_MEMORY != nil && @REPOSITORY_MEMORY.key?(key))
                     repToCheckAgainst = @REPOSITORY_MEMORY[key]
                     if repToCheckAgainst.getCreationDate != repToCheck.getCreationDate
                         refreshObjectInMemoryCache(key)
                     end
                elsif(@REPOSITORY_MEMORY != nil)
                    @REPOSITORY_MEMORY[key] = repToCheck
                end
              end
            }

        end
        #puts "Done Validating Cache."
    end
    #end private

end
