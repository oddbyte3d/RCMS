#----------------------------------------------------
#      Description:    provides a standardized
#                                  form for saving objects. It is in princip an object
#                                  wrapper that also saves a couple of things about the
#                                  object ie. Object is to be Memory Cached (if possible) for
#                                  faster access, Creation date for comparing to other objects
#                                  for a newer version.
#
#--------------------------------------------------

# Represents an object taken from a Repository
# to make it easier to get the class information
require "date"

class RepositoryObject

    attr_reader :className, :IS_MEMORY_CACHED, :REPOSITORY_OBJ, :CREATION_DATE
    # Object to Be stored in the Repository


    def initialize(obj, memoryCacheEnable)
        #puts "1 Init object...#{obj}"
        initRepositoryObject(obj, memoryCacheEnable)
    end

    def initRepositoryObject(obj, memoryCacheEnable)
      #puts "2 Init object...#{obj}"
      setObject(obj)
      @IS_MEMORY_CACHED = memoryCacheEnable
    end


    # Sets the new Object to be held by RepositoryObject
    # @param newObj Object to be put inside
    def setObject(newObj)
        #puts "Setting Object :#{newObj}"
        @REPOSITORY_OBJ = newObj
        @CLASS_NAME = @REPOSITORY_OBJ.class.name #.split('::').last
        @CREATION_DATE = Date.today
        #puts "Class Name = #{@CLASS_NAME}"
    end

    def getObject
      return @REPOSITORY_OBJ
    end

    def getCreationDate
        return @CREATION_DATE
    end

    def setMemoryCacheEnable(yesNo)
        @IS_MEMORY_CACHED = yesNo
    end
end
