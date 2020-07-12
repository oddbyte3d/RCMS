require_relative "../file/FileCMS"

class FileAction

    attr_accessor :ACTION_EDIT, :ACTION_DELETE, :ACTION_RENAME

    def initialize(filecms, actionType)
      @ACTION_EDIT = 0
      @ACTION_DELETE = 1
      @ACTION_RENAME = 2
      @relatedFile = filecms
      @myType = actionType
    end


    def getRelatedFile
        return @relatedFile
    end

    def getActionType
        return @myType
    end

end
