
 # AccessControler.rb
 #
 # Created on 17 September 2004, 15:04
require "yaml"
require "encrypted_strings"
require_relative "../net/HttpSession"
require_relative "../GlobalSettings"


class AccessControler




    # Creates a new instance of AccessControler
    def initialize
      #puts "new AccessControler initialized"
      @CONFIG_ROOT = GlobalSettings.getGlobal("Server-ConfigPath")
      @CONFIG_REST_PATH = "users/"
      @GROUPSFILE = @CONFIG_ROOT+@CONFIG_REST_PATH+"groups.properties"
      @FS = File::SEPARATOR
    end



     # Changes a user's password
     # @param userName
     # @param oldPass
     # @param newPass
     # @param newPassConfirm
     # @return

    def changeUserPassword(userName, oldPass, newPass, newPassConfirm)

        newPassEncrypt = newPass.encrypt
        newPassConfirmEncrypt = newPassConfirm.encrypt
        oldPassEncrypt = oldPass.encrypt

        if newPassEncrypt == newPassConfirmEncrypt

            if checkUserLogin(userName, oldPass)

                if userName == nil
                    return false
                end
                user = loadUser(userName)
                user["password"] = newPassEncrypt
                saveUser(userName, user)
                return true
            else
                return false
            end
        else
            return false
        end
    end




     # Checks a file for a users access rights.
     # @param userName
     # @param filePath
     # @return

    def checkUserFileAccess(userName, filePath)
        return false if filePath.end_with?(".access")
        if(userExists(userName))

          fAccess = filePath+".access"
          if File.exist?(fAccess)
            return checkFileAccess(userName, filePath, fAccess)
          else
              return checkUserDirectoryAccess(userName,filePath[0..filePath.rindex(@FS)])
          end
        end
        return false

    end


     # Checks a file for a group's access
     # @param groupName
     # @param filePath
     # @return

    def checkGroupFileAccess(groupName, filePath)

        #filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)
        fAccess = filePath+".access"
        if File.exist?(fAccess)

            return checkGroupFileAccess(groupName, filePath, fAccess)
        end
        return false
    end



     # Checks for permissions on a file/folder
     # @param filePath
     # @return

    def permissionsExist(filePath)

        #filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)
        fAccess = filePath+".access"
        return !File.exist?(fAccess)
    end



     # Checks for permissions on a file/folder
     # @param file
     # @return

    def permissionsExist(file)

        fAccess = File.absolute_path(file)+".access"
        return !File.exist?(fAccess)
    end



     # Sets a group's access to a file/folder
     # @param adminSettingPerms
     # @param groupName
     # @param filePath
     # @param grantAccess

    def setGroupFileAccess(adminSettingPerms, groupName, filePath, grantAccess)

        #filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)
        fAccess = filePath+".access"

        access = Hash.new
        if !File.exist?(fAccess)

          if grantAccess
            access["groups"] = ";#{groupName}"
          else
            access["groups"] = ""
          end

          #access["groups"] <= ";#{(grantAccess?groupName+";":"")}"
          access["users"] = ";guest;"
          access["adminUsers"] = ";root(rwp);#{adminSettingPerms}(rw);"
          access["adminGroups"] = ""
        else
            access = YAML.load_file(fAccess)
            groups = access["groups"]
            if groups.index(groupName) == nil && grantAccess
                groups.concat( groupName+";" )
            elsif groups.index(groupName) != nil && !grantAccess

                beginning = groups[0..groups.index(groupName)]
                gend = groups[groups.index(";", groups.index(groupName)+groupName.size())+1]
                groups = beginning+gend;
            end
            access["groups"] <= groups
        end
        File.write(fAccess, access.to_yaml)

    end


     # Sets a user's access to a file/folder
     # @param adminSettingPerms
     # @param userName
     # @param filePath
     # @param grantAccess

    def setUserFileAccess(adminSettingPerms, userName, filePath, grantAccess)

        #filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)
        fAccess = filePath.concat ".access"
        access = Hash.new {}
        if !File.exist?(fAccess)
          if grantAccess
            access["users"] = ";#{userName};"
          else
            access["users"] = ""
          end
          access["groups"] = ""
          if(adminSettingPerms == "root")
              access["adminUsers"] = ";root(rwp);"
          else
            access["adminUsers"] = ";root(rwp);"+adminSettingPerms+"(rw);"
          end
          access["adminGroups"] = ""
        else
            access = YAML.load_file(fAccess)
            users = access["users"]
            if users.index(userName) == nil && grantAccess
                users.concat( userName+";")
            elsif users.index(userName) != nil && !grantAccess

                beginning = users[0..users.index(userName)]
                gend = users[users.index(";", users.index(userName)+userName.size)]
                users = beginning.concat gend
            end
            access["users"] = users
        end
        File.write(fAccess, access.to_yaml)

    end


     # @deprecated
     # @param userName
     # @param filePath
     # @return

    def checkUserDirectoryAccess(userName, filePath)
      return false if filePath.end_with?(".access")
      if(userExists(userName) || userName == "guest")
        #filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)
        if(filePath.end_with?(@FS))
          filePath = filePath[0..filePath.rindex(@FS)]
        elsif (filePath.strip == "")
          filePath = GlobalSettings.getGlobal("Server-DataPath")
        end

        fAccess = filePath+".access"
        if File.exist?(fAccess)
          return checkFileAccess(userName, filePath, fAccess)
        elsif(GlobalSettings.getGlobal("RecursivePermissions") != nil &&
            GlobalSettings.getGlobal("RecursivePermissions"))

            noRecursivePast = nil
            if(filePath.index(File.absolute_path(GlobalSettings.getDocumentDataDirectory)) != nil)
                    noRecursivePast = GlobalSettings.getDocumentDataDirectory
            elsif(filePath.index(File.absolute_path(GlobalSettings.getDocumentWorkAreaDirectory)) != nil)
                    noRecursivePast = GlobalSettings.getDocumentWorkAreaDirectory
            elsif(filePath.index(File.absolute_path(GlobalSettings.getDocumentConfigDirectory)) != nil)
                    noRecursivePast = GlobalSettings.getDocumentConfigDirectory
            end
            #puts "No recursive past: #{noRecursivePast}"
            if(noRecursivePast == nil)
              return true #TO-DO: Need to check if this is correct????
            end
            if(!noRecursivePast.end_with?(@FS))
              noRecursivePast.concat(@FS)
            end
            if(File.exist?(fAccess) && noRecursivePast != nil)
                if(File.absolute_path(fAccess)[0..fAccess.rindex(@FS)] == File.absolute_path(noRecursivePast))
                    rootAccess = File.absolute_path(fAccess)+@FS+".access"
                    if File.exist?(rootAccess)
                      return checkFileAccess(userName, fAccess, rootAccess)
                    else
                      return true
                    end
                end
              else
                  #puts "#{filePath} ::: #{noRecursivePast}"
                  if(filePath == noRecursivePast)
                      return true
                  end
                  myParent = File.absolute_path(filePath)[0..File.absolute_path(filePath).rindex(@FS)]
                  if(myParent != nil && File.exist?(myParent))
                      return checkUserDirectoryAccess(userName, File.absolute_path(myParent)+@FS)
                  end
              end
        end
        return true
      end
      return false
    end


     # Returns wether or not access was granted to a user from the guest user
     # @param userName
     # @param fToAccess
     # @return

    def accessInheritedFromGuestUser(userName, fToAccess)

        fAccess = File.absolute_path(fToAccess)+".access"

        if File.exist?(fAccess)
          fileProps = YAML.load_file(fAccess)

          fileUsers = fileProps["users"]
          if(fileUsers.index(userName) != nil)
              return false
          end
          if(fileUsers.index("guest") != nil)
              return true
          end
        end
        return false
    end


     # Returns wether or not access was granted to a user from a group
     # @param userName
     # @param fToAccess
     # @return

    def accessInheritedFromGroup(userName, fToAccess)
      fAccess = File.absolute_path(fToAccess)+".access"

      if File.exist?(fAccess)
        fileProps = YAML.load_file(fAccess)

        fileUsers = fileProps["users"]
        if(fileUsers.index(userName) != nil)
            return false
        end
        fileGroups = fileProps["groups"]
        if(fileGroups.index(";guests;") != nil)
            return true
        end
        user = YAML.load_file(@CONFIG_ROOT+@CONFIG_REST_PATH+userName+"Profile.properties")

        groups = Array.new
        groupFound = true
        groupAt = 0
        while groupFound do

            if(user.key?("group#{groupAt}"))

                groupTmp = user["group#{groupAt}"]
                groups << groupTmp
                groupAt = groupAt.next
            else
                groupFound= false
            end
        end

        for i in 0..groups.size
            if(fileGroups.index(";#{groups.get(i)};") != nil)
                return true
            end
        end
        return false
      end
      return false
    end




     # Checks a file for user access
     # @param userName
     # @param fToAccess
     # @param fAccess
     # @return

    def checkFileAccess(userName, fToAccess, fAccess)

        #return false if fAccess.end_with?(".access")
        if File.exist?(fAccess) && userExists(userName)

          fileProps = YAML.load_file(fAccess)
          fileUsers = fileProps["users"]
          fileGroups = fileProps["groups"]
          if fileGroups.index(";guests;") != nil
              return true
          end

          if userName == nil
              return false
          end

          user = loadUser(userName)
          groups = Array.new
          groupFound = true
          groupAt = 0
          while groupFound

              if user.key?("group#{groupAt}")
                  groupTmp = user["group#{groupAt}"]
                  groups << groupTmp
                  groupAt = groupAt.next
              else
                  groupFound = false
              end
          end

          if(fileUsers.index(";#{userName};") != nil || fileUsers.index(";guest;") != nil)
              return true
          end
          if fileGroups.index(";guests;") != nil
              return true
          end
          for i in 0..groups.size

              if(fileGroups.index(";#{groups[i]};") != nil)
                  return true
              end
          end
          return false
        end
        return false
    end


     # Checks a group's access to a file
     # @param groupName
     # @param fToAccess
     # @param fAccess
     # @return

    def checkGroupFileAccess(groupName, fToAccess, fAccess)

        if File.exist?(fAccess)

          fileProps = YAML.load_file(fAccess)

          fileGroups = fileProps["groups"]
          if(fileGroups.index(";guests;") != nil || fileGroups.index(";#{groupName};") != nil)
              return true
          else
              return false
          end
        end
        return false
    end



     # Checks for the existance of a user
     # @param userName
     # @return

    def userExists(userName)
      user = loadUser(userName)
      #puts "User::::#{user}"
      if(user != nil && (!user.key?("BLOCKED") || user["BLOCKED"] == false))
          return true
      end
      return false
    end



     # Checks a users credentials
     # @param userName
     # @param userPass
     # @return

    def checkUserLogin(userName, userPass)
      userPass = userPass.encrypt
      user = loadUser(userName)
      if(user == nil)
        return false
      end
      userPassLoaded = user["password"]
      #puts "----------------------\nPass1: [#{userPass}]\nPass2: [#{userPassLoaded}]\n-----------------------------------"

      blocked = user["BLOCKED"]
      if userPassLoaded == userPass  && (blocked == nil || !blocked)
          return true
      else
          return false
      end
    end

    #Load the user Hash
    #TO-DO: Make this a private member....
    def loadUser(userName)
      if(userName == nil)
          return nil
      end
      userFile = @CONFIG_ROOT+@CONFIG_REST_PATH+userName+".yaml"
      if File.exist?(userFile)
        user = YAML.load_file(userFile)
        #puts "User: #{user}"
        return user
      end
      return nil
    end

    def saveUser(userName, userconf)
      userFile = @CONFIG_ROOT+@CONFIG_REST_PATH+userName+"Profile.properties"
      File.write(userFile, userconf.to_yaml)
    end

     # Checks a user for the status Blocked
     # @param userName
     # @return

    def userBlocked(userName)

      user = loadUser(userName)
      blocked = user["BLOCKED"]
      if(blocked != nil && blocked)
          return true
      else
          return false
      end
    end



     # Deletes a user
     # @param userName
     # @return

    def deleteUser(userName)

      if(userName == nil)
          return false
      else
        File.delete(@CONFIG_ROOT+@CONFIG_REST_PATH+userName+"Profile.properties")
        return true
      end
    end





     # Checks a HttpSession for user logged in
     # @param session
     # @return

    def isUserLoggedIn(session)

        if(session["loggedIn"] != nil && session["loggedIn"] == "true")
            return true
        end
        return false
    end



     # Returns the user name of a user logged in.
     # @param session
     # @return

    def getUserName(session)

        if(isUserLoggedIn(session))
            return session["loginName"]
        end
        return nil
    end


     # Returns the "Human" readable user name ie. "John Smith"
     # @param userName
     # @return

    def getUserName(userName)
        if(userName != nil)
          user = loadUser(userName)
          return user["fname"]+" "+user["lname"]
        end
        return "User not Found!"
    end


     # Returns all groups associated with a user.
     # @param userName
     # @return

    def getUserGroups(userName)

        if(userName == nil)
            return nil
        end
        user = loadUser(userName)
        at = 0
        groupsV = []
        while user["group#{at}"] != nil do
            groupsV <= user["group#{at}"]
            at = at.next
        end
        return groupsV

    end



     # Adds a group name
     # @param groupName
     # @return

    def addGroup(groupName)

        groups = YAML.load_file(@GROUPSFILE)
        groups[groups.size.next] = groupName
        File.write(@GROUPSFILE, groups.to_yaml)
        return true
    end



     # Returns a list of group names
     # @return

    def getGroups()

        groups = YAML.load_file(@GROUPSFILE)
        groupsS = []
        for i in 0..groups.size
            groupsS <= groups[i]
        end
        return groupsS

    end

    def groupExists(groupName)

        groups = YAML.load_file(@GROUPSFILE)
        return groups.value?(groupName)

    end


     # Returns a users email address
     # @param userName
     # @return

    def getUserEmail(userName)

      if(userName == nil)
          return "User not Found!"
      end
      user = loadUser(userName)
      if user == nil
        return "User not Found!"
      end
      return user["email"]

    end



     # Sets a user's Email address
     # @param userName
     # @param email

    def setUserEmail(userName, email)

        if(userName == nil)
            return
        else
          user = loadUser(userName)
          if user != nil
            user["email"] = email
            saveUser(userName, user)
          end
        end
    end


     # Returns a specific user field
     # @param userName
     # @param fieldName
     # @return

    def getUserField(userName, fieldName)

      if userName == nil
        return "User not Found!"
      end
      if fieldName == "password"
        return "Access denied!"
      else
        user = loadUser(userName)
        if(user.key?(fieldName))
            return user[fieldName]
        else
            return "Field not found!"
        end
      end
    end


     # Used to create a new user.
     # @param userName
     # @param initialGroup
     # @param userEmail
     # @param fname
     # @param lname
     # @param password

    def createNewUser(userName, initialGroup, userEmail, fname, lname, password)

        password = password.encrypt
        user = {"login" => userName,
                "group0" => initialGroup,
                "email" => userEmail,
                "fname" => fname,
                "lname" => lname,
                "password" => password,
                "orga" => "0"}
        saveUser(userName, user)
    end


     # Lists all users.
     # @return

    def listUsers

        #File userDir = new File(@CONFIG_ROOT+@CONFIG_REST_PATH);
        #File fUsers[] = userDir.listFiles(new DynamicFileFilter(new String[]{"Profile.properties"}));

        #String toRet[] = new String[fUsers.length];
        #for(int i = 0; i < toRet.length; i++)
        #    toRet[i] = fUsers[i].getName().substring(0, fUsers[i].getName().indexOf("Profile.properties"));
        #return toRet;
    end



     # Used to sets a user field.
     # @param userName
     # @param fieldName
     # @param fieldValue

    def setUserField(userName, fieldName, fieldValue)

        if userName != nil && fieldName != "password"
          user = loadUser(userName)
          user[fieldName] = fieldValue
          saveUser(userName, user)
        end
    end



     # Returns all user fields
     # @param userName
     # @return

    def getUserProperties(userName)

        if userName != nil
          user = loadUser(userName)
          user.delete("password")
          return user
        else
          return nil
        end
    end

end
