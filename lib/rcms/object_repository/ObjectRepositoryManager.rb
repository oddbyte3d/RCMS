#package de.codefactor.ObjectRepository;
#import java.util.*;

# Manager for Repository's, Can Manage many Repositorys

class ObjectRepositoryManager

    # Creates new ObjectRepositoryManager */
    def initialize
      # This is a list of Repositorys that the manager is managing
      @@REPOSITORY_MANAGER = Hash.new
      # This is the current ObjectRepository chosen
      @CURRENT_REPOSITORY = nil

    end


    # Adds a Repository to the list if not found then attempts to create a new
    # Repository
    # @param repositoryID ID from the repository to be added
    # @param directory Path to the Repository
    # @param safeClass Class Name from the safe

    def addObjectRepository(repositoryID, directory, safeClass)


  		if(!@@REPOSITORY_MANAGER.key?(repositoryID))

  	        newRepos = ObjectRepository.new(safeClass)
  	        #puts "Adding repository:#{directory}"
  	        if newRepos != nil
  	            @CURRENT_REPOSITORY = newRepos
  	            #@CURRENT_REPOSITORY.setSafeClass(safeClass)
  	            @CURRENT_REPOSITORY.setObjectRepository(directory, repositoryID)
  	            @@REPOSITORY_MANAGER[repositoryID] = @CURRENT_REPOSITORY
  	            @CURRENT_REPOSITORY.saveRepository
  	        end
  		end
    end


    #Selects a Repository to work with
    # Using a Repository ID
    # @param repositoryID Id from the repository to select

    def setCurrentRepository(repositoryID)

        if @@REPOSITORY_MANAGER.key?(repositoryID)
            @CURRENT_REPOSITORY = getObjectRepsoitory(repositoryID)
        end
    end

    # Returns the name of the
    # repository that has been
    # selected
    # @return Name of the Repository Currently
    # in use

    def getCurrentRepositoryName
        return @CURRENT_REPOSITORY.getObjectRepsoitory
    end

    # Gets a Repository
    # @param repositoryID ID from the Repository
    # @return Repository

    def getObjectRepsoitory(repositoryID)
        return @@REPOSITORY_MANAGER[repositoryID]
    end


    #Saves an Object to the current Repository using an Unique ID
    # @param objectToSaveName Name(id) from the Object to add to the repository
    # @param objectToSave The Object to save in the Repository

    def addObjectToRepository(objectToSaveName, objectToSave, cacheObjectInMemory)
        @CURRENT_REPOSITORY.commitObject(objectToSaveName,objectToSave, cacheObjectInMemory)
    end

    # Retrievs an Object from the Repository
    # @param objectName Name from the object to retrieve
    # @return Object if found Null if not found

    def getObjectClassNameFromRepository(objectName)
        rpOb = @CURRENT_REPOSITORY.getRepositoryObject(objectName)
        if rpOb != nil
            return rpOb.getClassName
        end
        return nil
    end

    # Returns the Creation Date of the
    # RepositoryObject
    # @param objectName Name of the Object to get
    # @return Creation Date of Object

    def getObjectCreationDate(objectName)
        rpOb = @CURRENT_REPOSITORY.getRepositoryObject(objectName)
        return rpOb.CREATION_DATE
    end

    # Retrievs an Object from the Repository
    # @param objectName Name from the object to retrieve
    # @return Object if found Null if not found
    def getObjectFromRepository(objectName)
        rpOb = @CURRENT_REPOSITORY.getRepositoryObject(objectName)
        if rpOb != nil
            return rpOb.REPOSITORY_OBJ
        end
        return nil
    end

    # Removes an Object from the Repository
    # @param objectName Name of the Object to remove
    def removeObjectFromRepository(objectName)
        @CURRENT_REPOSITORY.removeRepositoryObject(objectName)
    end

    # Returns a list of all Repositorys
    # @return Set with all Objects in the Repository
    def listRepositorys
        return @@REPOSITORY_MANAGER.keys
    end

    # Returns a Set with all ID's in the current Repository
    # @return List of Contents
    def listRepositoryContents
        return @CURRENT_REPOSITORY.keys
    end

    # Returns a Set with all ID's in the current Repository
    # @return List of Contents
    def toString
        returnString = "//------RepositoryContents------//"
        @CURRENT_REPOSITORY.getRepositoryKeys.each do |key|
          returnString.concat(key)
        end
        returnString.concat("\n//----------------------------//")
        return returnString
    end

    # Sets the Class to be used to save the Repository and its contents
    # @param className Name of the class to use
    def setSafeClass(className)
        @CURRENT_REPOSITORY.setSafeClass(className)
    end

    # Returns the name of the Class that is used as the safe
    # @return Name of class used
    def getSafeClass
        return @CURRENT_REPOSITORY.getSafeClass
    end

end
