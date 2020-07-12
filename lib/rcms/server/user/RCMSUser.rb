require_relative "../security/AccessControler"
require_relative "../security/AdminAccessControler"

class RCMSUser

    attr_accessor :WEB_GROUPS, :ADMIN_GROUPS, :USER_NAME, :IS_ADMIN, :IS_WEB

    @@F_NAME = "fname"
    @@L_NAME = "lname"
    @@EMAIL = "email"
    @@COMMENTS = "comments"
    @@USER_ICON = "userIcon"


    def initialize(userName)

      @ADMIN_ACCESS_CONTROL = AdminAccessControler.new
      @ACCESS_CONTROL = AccessControler.new
      @ADMIN_GROUPS = Array.new
      @WEB_GROUPS = Array.new

      @USER_NAME = userName
      @IS_ADMIN = @ADMIN_ACCESS_CONTROL.userExists(@USER_NAME)
      #puts "User is admin: #{@USER_NAME} ?#{@IS_ADMIN}"
      @IS_WEB = @ACCESS_CONTROL.userExists(@USER_NAME)
      if(@IS_ADMIN)
          @ADMIN_PROPS = @ADMIN_ACCESS_CONTROL.getUserFields(@USER_NAME)
          at = 0
          @ADMIN_PROPS.each { |nprop|
            if(@ADMIN_PROPS.key?("adminGroup#{at}"))
              @ADMIN_GROUPS << @ADMIN_PROPS["adminGroup#{at}"]
            end
            at = at.next
          }
      end
      if(@IS_WEB)

          @WEB_PROPS = @ACCESS_CONTROL.getUserProperties(@USER_NAME)
          at = 0
          @WEB_PROPS.each { |nprop|
            if(@WEB_PROPS.key?("group#{at}"))
              @WEB_GROUPS << @WEB_PROPS["group#{at}"]
            end
            at = at.next
          }
      end


    end

    def getEmail(userId)
        return EmailUser.new(userId, getUserFName(), getUserLName(), getUserEmail(), "", nil, "", @WEB_PROPS, true)
    end

    def setGroups(groups)
      at = 0

      groups.each { |group|
        @WEB_PROPS["group#{at}"] = groups[at]
        @ACCESS_CONTROL.setUserField(@USER_NAME, "group#{at}", groups[at])
        at = at.next
      }
    end

    def match(searchText)
        keys = getUserFields
        keys.each{ |key|
            if(@WEB_PROPS[key].downcase.index(searchText.downcase) > -1)
              return true
            end
        }
        return false
    end

    def getUserFields
        return @WEB_PROPS.keys
    end


    def getUserIcon

        if(@WEB_PROPS.key?(@@USER_ICON))
            return @WEB_PROPS[@@USER_ICON]
        else
            return "/rcms/ui/icons/nopic_user.gif"
        end
    end

    def setUserIcon(iconPath)
        @WEB_PROPS[@@USER_ICON] = iconPath
        @ACCESS_CONTROL.setUserField(@USER_NAME, @@USER_ICON, iconPath)
    end


    #Blocks a user from logging in to web instance
    #@param block
    def setUserWebBlocked(block)
        @WEB_PROPS["BLOCKED"] = block
        @ACCESS_CONTROL.setUserField(@USER_NAME, "BLOCKED", block)
    end


    # Checks the users web instance login status
    # @return
    def isUserWebBlocked
        if(@WEB_PROPS != nil)
            amblocked = @WEB_PROPS["BLOCKED"]
            return (amblocked == nil && amblocked == "true")
        else
            return false
        end
    end


    # Blocks an admin from logging into the admin console
    # @param block
    def setUserAdminBlocked(block)
        @ADMIN_PROPS["BLOCKED"] = block
        @ADMIN_ACCESS_CONTROL.setUserField(@USER_NAME, "BLOCKED", block)
    end

    # Checks the users admin instance login status
    # @return
    def isUserAdminBlocked
        if(@ADMIN_PROPS != nil)
          amblocked = @ADMIN_PROPS["BLOCKED"]
          return (amblocked == nil && amblocked == "true")
        else
          return false
        end
    end


    def getUserField(field)
        if(field == "password")
            return "Passwords are secret!"
        end
        return @WEB_PROPS[field]
    end

    def setUserField(field, value)
        if(@IS_WEB)
            @ACCESS_CONTROL.setUserField(@USER_NAME, field, value)
            @WEB_PROPS[field] = value
        end
        if(@IS_ADMIN)
            @ADMIN_ACCESS_CONTROL.setUserField(@USER_NAME, field, value)
            @ADMIN_PROPS[field] = value
        end
    end

    def getUserComment
        return @WEB_PROPS[@@COMMENTS]
    end

    def setUserComment(comment)
        setUserField(@@COMMENTS, comment)
    end

    def getUserEmail
        return @WEB_PROPS[@@EMAIL]
    end

    def setUserEmail(newEmail)
        setUserField(@@EMAIL, newEmail)
    end

    def getUserLName
        return @WEB_PROPS[@@L_NAME]
    end

    def setUserLName(newUserLName)
        setUserField(@@L_NAME, newUserLName)
    end

    def getUserFName
        return @WEB_PROPS[@@F_NAME]
    end

    def setUserFName(newUserFName)
        setUserField(@@F_NAME, newUserFName)
    end


#    public static boolean createUser(String userName, String password,
#            boolean isAdminUser, String webGroups[], String adminGroup,
#            String fName, String lName, String email, Properties additionalUserInformation)
    def createUser(userName, password, isAdminUser, webGroups, adminGroup, fName, lName, email, additionalUserInformation)

        @ACCESS_CONTROL.createNewUser(userName, webGroups[0], email, fName, lName, password)
        at = 0
        webGroups.each{ |group|
          @ACCESS_CONTROL.setUserField(userName, "group#{at}", webGroups[at])
          at = at.next
        }
        additionalUserInformation.keys.each{ |key|
          @ACCESS_CONTROL.setUserField(userName, key, additionalUserInformation[key])
        }
        if(isAdminUser)
            @ADMIN_ACCESS_CONTROL.createNewUser(userName, adminGroup, email, fName, lName, password)
            additionalUserInformation.keys.each{ |key|
              @ADMIN_ACCESS_CONTROL.setUserField(userName, key, additionalUserInformation[key])
            }
        end
        return true
    end



    def compareTo(compare)

        if(compare.instance_of RCMSUser)

            #return (this.getUserFName()+" "+this.getUserLName()).compareTo(comp.getUserFName()+" "+comp.getUserLName());

        else
            return -1
        end
    end
end
