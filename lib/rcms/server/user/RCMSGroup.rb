

class CuppaGroup
  attr_reader :IS_ADMIN, :GROUP_NAME

    def initialize(groupName, isAdmin)
        @GROUP_NAME = groupName
        @IS_ADMIN = isAdmin
    end


    def match(searchText)

        if(getGroupName().downcase.index(searchText.downcase) > -1)
            return true
        else
            return false
        end
    end

    def ==(other)
      if(other.instance_of RCMSGroup)
        return other.GROUP_NAME == @GROUP_NAME
      else
        return false
      end
    end

end
