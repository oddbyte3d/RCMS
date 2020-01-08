require "yaml"
require "encrypted_strings"
require_relative "../user/RCMSUser"
require_relative "../user/RCMSGroup"
require_relative "../GlobalSettings"
require_relative "./AdminSession"

#import com.cuppait.file.DynamicFileFilter;
#import de.codefactor.web.admin.session.adminSession;

class AdminAccessControler


    def initialize
      @APPLICATION_HOME = GlobalSettings.getGlobal("Server-ConfigPath")
      #@CONFIG_ROOT = GlobalSettings.getGlobal("Server-ConfigPath")
      #@CONFIG_REST_PATH = "de/codefactor/instantsite/properties/users/"
      @FS = File::SEPARATOR
      @ACCESS_NONE = 0
      @ACCESS_READ = 1
      @ACCESS_READWRITE = 2
      @ACCESS_READPUBLISH = 3
      @ACCESS_FULL = 4

    end


    # Not sure what this is for...
    def checkUserPageAccess(user, pagePath)
        return false
    end

    def userExists(userName)

        if(userName == "root")
            return true
        end
        fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml"
        if(userName == nil || !File.exist?(fullPath))
            return false
        else
          user = YAML.load_file(fullPath)
          #puts "Admin User: #{user}"
          if(user != nil)
              return true
          else
            return false
          end
        end
        return false
    end


    def listUsers

        userDir = "#{@APPLICATION_HOME}/dashboard/default/.profiles/"
        Dir.chdir(userDir)
        filtered = Dir.glob("*.yaml")
        users = Array.new
        at = 0
        filtered.each{ |user|

          users[at] = user[0..(user.index(".yaml")-1)]
          #puts "Username : #{users[at]}"
          at = at.next
        }

        return users
    end


    def groupExists(groupName)
        return File.exist?("#{@APPLICATION_HOME}/dashboard/.profiles/#{groupName}Mods.yaml" )
    end

    def createNewGroup(groupName)
      group = Hash.new
      File.write("#{@APPLICATION_HOME}/dashboard/default/.profiles/#{groupName}Mods.yaml", group.to_yaml)
    end

    def createNewUser(userName, initialGroup, userEmail, fname, lname, password)
        password = password.encrypt
        user = Hash.new;
        user["login"] = userName
        user["adminGroup0"] = initialGroup
        user["email"] = userEmail
        user["fname"] = fname
        user["lname"] = lname
        user["password"] = password
        File.write("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml", user.to_yaml)
    end

    def getModuleActions(sessionId, moduleName)
      fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/Modules/#{moduleName}Actions.yaml"
      return YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath) )
    end

    def getPossibleModuleActions(sessionId, moduleName)

        return getModuleActions.keys
    end

    def getModuleActionLongDescription(sessionId, moduleName, actionName)
        return getModuleActions[actionName]
    end

    def getModuleActionDescription(sessionId, moduleName, actionName)
        return getModuleActions[actionName]
    end


    def canUseModuleAction(user, moduleName, moduleAction)

        if(user.USER_NAME == "root")
            return true
        end
        if(!userHasModuleAction("", user.USER_NAME, moduleName, moduleAction))
            user.getAdminGroups.each{ |ngroup|
              return groupHasModuleAction("", ngroup, moduleName, moduleAction)
            }
        else
            return true
        end
    end

    def canUseModuleAction(group, moduleName, moduleAction)
        return groupHasModuleAction("", group.GROUP_NAME, moduleName, moduleAction)
    end

    #Return the user parameters from profile
    def getUser(sessionId, userName)
      fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml"
      if(userName != nil)

        return YAML.load_file(fullPath)
      end
    end

    def setUserGroupAccess(sessionId, userName, groupName, access)
        fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml"
        if(userName != nil)

          user = YAML.load_file(fullPath)
          groups = Array.new
          at = 0
          while user.key?("adminGroup#{at}")

              if(!user["adminGroup#{at}"] == groupName)
                  groups << user["adminGroup#{at}"]
                  user.delete("adminGroup#{at}")
              else
                  user.delete("adminGroup#{at}")
              end
              at = at.next
          end
          if access
              groups << groupName
          end
          at = 0
          groups.each{ |group|
            user["adminGroup#{at}"] = group
          }
          File.write(GlobalSettings.changeFilePathToMatchSystem(fullPath), user.to_yaml)
        end
    end

    def userBelongsToGroup(sessionId, userName, groupName)

      user = getUser
      if user.has_value?(groupName)
        return user.key(groupName).start_with?("adminGroup")
      end
      return false
    end


    def getModule(sessionId, moduleName)
      fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/Modules/#{moduleName}.yaml"
      if(userName != nil)

        return YAML.load_file(fullPath)
      end
    end

    def saveModule(sessionId, moduleName, mod)
      fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/Modules/#{moduleName}.yaml"
      if(userName != nil)
        File.write(fullPath, mod.to_yaml)
      end
    end



    def getGroupModule(sessionId, groupName)
      groupPath = "#{@APPLICATION_HOME}/dashboard/.profiles/#{groupName}Mods.yaml"
      return YAML.load_file(groupPath)
    end

    def saveGroupModule(sessionId, groupName, group)
      groupPath = "#{@APPLICATION_HOME}/dashboard/.profiles/#{groupName}Mods.yaml"
      File.write(groupPath, group.to_yaml)
    end


    def setGroupModuleAccess(sessionId, groupName, moduleName, access)

      group = getGroupModule(sessionId, groupName)
      group[moduleName] = access
      saveGroupModule(sessionId, groupName, group)
    end

    def setGroupModuleActionAccess(sessionId, groupName, moduleName, moduleAction, access)

        fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/Modules/#{moduleName}.yaml"

        if(groupName != nil)
          #Make sure that the group has appropriate access to the Module
          groupPath = "#{@APPLICATION_HOME}/dashboard/.profiles/#{groupName}Mods.yaml"
          gr = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(groupPath))


          if(access && (!gr.key?(moduleName) || gr[moduleName] == "false"))
              gr[moduleName] = "true"
          end
          File.write(GlobalSettings.changeFilePathToMatchSystem(groupPath), gr.to_yaml)

          mod = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath))
          userAccess = mod[groupName+"(group)"]
          if(userAccess == nil && access)
              userAccess = ";"
          end
          if(userAccess != nil && access && userAccess.index(moduleAction) != nil)
              userAccess.concat("#{moduleAction};")
          elsif(userAccess != nil && !access && userAccess.index(moduleAction) == nil)

              len = (moduleAction+";").size
              userAccess = userAccess[0..userAccess.index("#{moduleAction};")].concat(userAccess[userAccess.index("#{moduleAction};")+len])
          end
          mod[groupName+"(group)"] = userAccess
          File.write(GlobalSettings.changeFilePathToMatchSystem(fullPath), mod.to_yaml)
          #module.store(new FileOutputStream(), "Module access priviliges, do not edit!");
        end
    end

    def setUserModuleAccess(sessionId, userName, moduleName, moduleAction, access)

        fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/Modules/#{moduleName}.yaml"

        if(userName != nil)

          mod = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath))
          userAccess = mod["#{userName}(user)"]
          if(userAccess == nil && access)
              userAccess = ";"
          end
          if(userAccess != null && access && !userAccess.contains(moduleAction))
              userAccess.concat("#{moduleAction};")
          elsif(userAccess != nil && !access && userAccess.index(moduleAction) != nil)

              len = ("#{moduleAction};").size
              userAccess = userAccess[0..userAccess.index("#{moduleAction};")].concat(userAccess[userAccess.index("#{moduleAction};")+len])
          end
          mod["#{userName}(user)"] = userAccess
          File.write(GlobalSettings.changeFilePathToMatchSystem(fullPath), mod.to_yaml)
        end
    end

    def userHasModuleAction(sessionId, userName, moduleName, moduleAction)

        if userName == "root"
            return true
        end

        fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/Modules/#{moduleName}.yaml"
        if(userName == nil)
            return false
        end

        mod = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath))
        access = mod["#{userName}(user)"]
        if(access != nil && access.key(moduleAction))
            return true
        else
            return false
        end

    end

    def getModules(sessionId)


        fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/Modules/LoadModules.yaml"
        mod = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath))
        return mod
    end


    def groupHasModuleAction(sessionId, group, moduleName, moduleAction)


        fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/Modules/#{moduleName}.yaml"
        if(group == nil)
            return false
        end

        mod = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath) )
        access = mod[group+"(group)"]
        if(access != nil && access.index(moduleAction) != nil)
            return true
        else
            return false
        end
    end


    def checkUserLogin(sessionId, userName, userPass)

        userPass = userPass.encrypt
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml")
        if(userName == nil)
            return false
        end
        if(File.exist?(fullPath))
          user = YAML.load_file(fullPath)
          userPassLoaded = user["password"]
          blocked = user["BLOCKED"]
          if(blocked == nil)
            blocked = false
          end
          if(userPassLoaded == userPass && !blocked)
            return true
          else
            return false
          end
        end
        return false
    end

    def userBlocked(sessionId, userName)


        fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml"
        if(userName == nil)
            return false
        end
        user = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath))
        blocked = user["BLOCKED"]
        if(blocked == nil || blocked)
            return true
        else
            return false
        end
    end

    def deleteUser(sessionId, userName)


        fullPath = "#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml"
        if(userName == nil)
            return false
        end
        return File.delete(fullPath)
    end

    def setUserFilePermissions(userName, filePath, permissions)

        if(userName == "root" && (permissions != @ACCESS_FULL || permissions != @ACCESS_READWRITE))
            return false
        end
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/default/.profiles/#{userName}.yaml")

        perms = ""
        case permissions

        when @ACCESS_READ
          perms = "(r)"
        when @ACCESS_READWRITE
          perms = "(rw)"
        when @ACCESS_READPUBLISH
          perms = "(rp)"
        when @ACCESS_FULL
          perms = "(rwp)"
        end

        fAccess = GlobalSettings.changeFilePathToMatchSystem(filePath+".access")
        fileProps = Hash.new
        if(!File.exist?(fAccess))

            fileProps["users"] = ";guest;#{userName};"
            fileProps["groups"] = ""
            fileProps["adminUsers"] = ";#{userName}#{perms};root(rwp);"
            fileProps["adminGroups"] = ""

        else

            fileProps = YAML.load_file(fAccess)
            fileUsers = fileProps["adminUsers"]
            if(fileUsers.index(userName) > -1)

              beginning = fileUsers[0..fileUsers.index(userName)]

              nend = fileUsers[fileUsers.index(";", fileUsers.index(userName)+userName.size)]
              #String end = fileUsers.substring(fileUsers.indexOf(";", fileUsers.indexOf(userName)+userName.length()));
              fileUsers = "#{beginning}#{userName}#{perms}#{nend}"

            else
                fileUsers.concat("#{userName}#{perms};")
            end
            fileProps["adminUsers"] = fileUsers
        end
        File.write(fAccess, fileProps.to_yaml)
        return true
    end


    def setGroupFilePermissions(groupName, filePath, permissions)

        perms = ""
        case permissions

        when @ACCESS_READ
          perms = "(r)"
        when @ACCESS_READWRITE
          perms = "(rw)"
        when @ACCESS_READPUBLISH
          perms = "(rp)"
        when @ACCESS_FULL
          perms = "(rwp)"
        end
        fAccess = GlobalSettings.changeFilePathToMatchSystem("#{filePath}.access")
        fileProps = Hash.new
        if(!File.exist?(fAccess))

            fileProps["users"] = ";guest;"
            fileProps["groups"] = ""
            fileProps["adminUsers"] = ";root(rwp);"
            fileProps["adminGroups"] = ";#{groupName}#{perms};"

        else

            fileProps = YAML.load_file(fAccess)
            fileUsers = fileProps["adminGroups"]
            if(fileUsers.index(groupName) != nil)

                beginning = fileUsers[0..fileUsers.index(groupName)-1]
                nend = fileUsers[fileUsers.index(";", fileUsers.index(groupName)+groupName.size)..fileUsers.size]
                fileUsers = "#{beginning}#{groupName}#{perms}#{nend}"

            else
                fileUsers.concat("#{groupName}#{perms};")
            end
            fileProps["adminGroups"] = fileUsers
        end
        File.write(fAccess, fileProps.to_yaml)

        return true
    end


    def changeUserPassword(sessionId, userName, oldPass, newPass, newPassConfirm)

        oldPassEncrypt = oldPass.encrypt
        newPassEncrypt = newPass.encrypt
        newPassConfirmEncrypt = newPassConfirm.encrypt

        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml")
        if(newPassEncrypt == newPassConfirmEncrypt)

            if(checkUserLogin(sessionId, userName, oldPass))

                if(userName == nil)
                    return false
                end
                user = YAML.load_file(fullPath)
                user["password"] = newPassEncrypt
                File.write(fullPath, user.to_yaml)
                return true
            else
                return false
            end
        else
            return false
        end
    end


    def checkFileAccessRead(sessionId, userName, filePath)

        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml")
        #puts "UserPath: #{fullPath}"
        fAccess = "#{filePath}.access"
        #puts "#{fAccess} :::: #{File.exist?(fAccess)}"
        if(File.exist?(fAccess))

            fileProps = YAML.load_file(fAccess)
            fileUsers = fileProps["adminUsers"]
            fileGroups = fileProps["adminGroups"]
            if(userName == nil)
                return false
            end



            user = YAML.load_file(fullPath)
            #puts "=========================\nCheck 1: #{fileUsers != nil && fileUsers.index(";#{userName}(r") != nil || fileUsers.index(";everyone(r") != nil}\n====================================="
            if(fileUsers != nil && fileUsers.index(";#{userName}(r") != nil || fileUsers.index(";everyone(r") != nil)
              #puts "++++++++++++++++++++++++++++++++++++++++Returning true++++++++++++++++++++++++"
                return true
            end
            at = 0
            while(user["adminGroup#{at}"] != nil)

                group = user["adminGroup#{at}"]#.concat("#{at}")
                #puts "User Group : #{group}"
                at = at.next
                if(fileGroups != nil && fileGroups.index(";#{group}(r") != nil ||
                  fileGroups.index(";everyone(r;") != nil)
                    return true
                end
            end
            return false

        elsif(!checkDirectoryAccessRead(sessionId, userName,filePath[0..filePath.rindex(@FS)+1]))
            #puts "Returning false at checkDirectoryAccessRead"
            return false
        else
            #puts "Returning true......??????"
            return true
        end

        return true
    end


    def checkGroupFileAccessRead(groupName, filePath)

        fAccess = GlobalSettings.changeFilePathToMatchSystem("#{filePath}.access")
        if(File.exist?(fAccess))

            fileProps = YAML.load_file(fAccess)
            fileGroups = fileProps["adminGroups"]

            if(groupName == nil)
                return false
            end
            return (fileGroups.index(";#{groupName}(r") != nil)
        end
        return false
    end

    def checkGroupFileAccessWrite(groupName, filePath)

        fAccess = GlobalSettings.changeFilePathToMatchSystem("#{filePath}.access")
        if(File.exist?(fAccess))

            fileProps = File.load_file(fAccess)
            fileGroups = fileProps["adminGroups"]

            if(groupName == nil)
                return false
            end
            return (fileGroups.index(";#{groupName}(rw") != nil)
        end
        return false
    end

    def checkGroupFileAccessPublish(groupName, filePath)

        fAccess = GlobalSettings.changeFilePathToMatchSystem("#{filePath}.access")
        if(File.exist?(fAccess))

            fileProps = YAML.load_file(fAccess)
            fileGroups = fileProps["adminGroups"]

            if(groupName == nil)
                return false
            end
            return (fileGroups.index(";#{groupName}(rp") != nil || fileGroups.index(";#{groupName}(rwp") != nil)
        else
          return false
        end
    end


    def checkDirectoryAccessRead(sessionId, userName, accessCheck)
        #puts "AdminSession ::::::::: #{AdminSession.getSessionHash(sessionId)}"
        if(AdminSession.getSessionHash(sessionId)== nil)
            return false
        end

        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml")
        filePath = GlobalSettings.changeFilePathToMatchSystem(accessCheck)

        if(!(File.directory?(filePath)) && filePath.rindex(@FS) != nil)
            filePath = filePath[0..filePath.rindex(@FS)]
        end
        if(filePath.end_with?(@FS))
            filePath = filePath[0..filePath.rindex(@FS)]
        end
        fileAccess = "#{filePath}.access"
        if(File.exist?(fileAccess))

            fileProps = YAML.load_file(fAccess);
            fileUsers = fileProps["adminUsers"]
            fileGroups = fileProps["adminGroups"]

            if(userName == nil)
                return false
            end
            user = YAML.load_file(fullPath)


            if(fileUsers != nil && fileUsers.index(";#{userName}(r") != nil || fileUsers.index(";everyone(r") != nil)
                return true
            end

            at = 0
            while(user["adminGroup#{at}"] != nil)

                group = user["adminGroup#{at}"]
                at = at.next
                if(fileGroups != nil && fileGroups.index(";#{group}(r") != nil ||
                  fileGroups.index(";everyone(r;") != nil)
                    return true
                end
            end
            return false

        else
            return true
        end
    end


    def checkFileAccessWrite(sessionId, userName, filePath)
        #puts "+++++++++++++++++++++++++++++++++++++checkFileAccessWrite++++++++++++++++++++++++++"
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml")
        filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)
        fAccess = "#{filePath}.access"
        #puts fAccess
        if(File.exist?(fAccess))

            fileProps = YAML.load_file(fAccess)
            fileUsers = fileProps["adminUsers"]
            fileGroups = fileProps["adminGroups"]

            if(userName == nil)
              #puts "Returning false...."
                return false
            end
            user = YAML.load_file(fullPath)
            #puts "Checking :: #{fileUsers.index(";#{userName}(rw")}"
            if(fileUsers.index(";#{userName}(rw") != nil || fileUsers.index(";everyone(rw") != nil)
              #puts "+++++++++++Returning true 1"
                return true
            end
            at = 0
            while(user["adminGroup#{at}"] != nil)

                group = user["adminGroup#{at}"]
                at = at.next
                if(fileGroups.index(";#{group}(rw") != nil || fileGroups.index(";everyone(rw") != nil)
                  #puts "+++++++++++Returning true 2"
                    return true
                end
            end
            #puts "Returning false 1"
            return false

        elsif(checkDirectoryAccessWrite(sessionId, userName,filePath[0..filePath.rindex(@FS)+1]))
            return true
        else
            return false
        end
        return false
    end


    def checkDirectoryAccessWrite(sessionId, userName, accessCheck)

        if(AdminSession.getSessionHash(sessionId)== nil)
            return false
        else
          #return checkDirectoryAccessWrite( userName, File.absolute_path(accessCheck));
          if(userName == nil)
              return false
          end
          userPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml")
          filePath = GlobalSettings.changeFilePathToMatchSystem(accessCheck)

          if(!File.directory?(filePath) && filePath.index(@FS) != nil)
              filePath = filePath[0..filePath.rindex(@FS)-1]
          end
          if(filePath.end_with?(@FS))
              filePath = filePath[0..filePath.rindex(@FS)-1]
          end
          fAccess = filePath.concat(".access")
          if(File.exist?(fAccess))

              fileProps = YAML.load_file(fAccess)
              fileUsers = fileProps["adminUsers"]
              fileGroups = fileProps["adminGroups"]

              user = YAML.load_file(userPath)


              if(fileUsers.index(";#{userName}(rw") != nil || fileUsers.index(";everyone(rw") != nil)
                  return true
              end
              at = 0
              while(user["adminGroup#{at}"] != nil)

                  group = user["adminGroup#{at}"]
                  at = at.next
                  if(fileGroups.index(";#{group}(rw") != nil || fileGroups.index(";everyone(rw") != nil)
                      return true
                  end
              end
              return false

          else
              return true
          end
        end
    end


    def checkDirectoryAccessPublish(sessionId, userName, accessCheck)

        if(AdminSession.getSessionHash(sessionId)== nil)
            return false
        end

        return checkDirectoryAccessPublish( userName, File.absolute_path(accessCheck))

    end


    def checkDirectoryAccessPublish( userName, filePath)

        if(userName == nil)
            return false
        end


        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml")
        filePath = GlobalSettings.changeFilePathToMatchSystem(filePath);

        if(!File.directory?(filePath) && filePath.index(@FS) != nil)
            filePath = filePath[0..filePath.rindex(@FS)]
        end
        if(filePath.end_with("/"))
            filePath = filePath[0..filePath.rindex('/')]
        end
        fAccess = "#{filePath}.access"
        if(File.exist?(fAccess))

            fileProps = YAML.load_file(fAccess)
            fileUsers = fileProps["adminUsers"]
            fileGroups = fileProps["adminGroups"]

            user = YAML.load_file(fullPath)
            if(fileUsers.index(";#{userName}(rp") != nil || fileUsers.index(";#{userName}(rwp") != nil ||
                    fileUsers.index(";everyone(rp") != nil || fileUsers.index(";everyone(rwp") != nil)
                return true
            end
            at = 0
            while(user["adminGroup#{at}"] != nil)

                group = user["adminGroup#{at}"]
                at = at.next
                if(fileGroups.index(";#{group}(rp") != nil || fileGroups.index(";#{group}(rwp") != nil ||
                        fileGroups.index(";everyone(rp") != nil || fileGroups.index(";everyone(rwp") != nil)
                    return true
                end
            end
            return false

        else
            return true
        end
    end



    def checkFileAccessPublish(sessionId, userName, filePath)

        if(userName == nil)
            return false
        end
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml")
        filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)

        fAccess = "#{filePath}.access"
        if(File.exist?(fAccess))

            fileProps = YAML.load_file(fAccess)
            fileUsers = fileProps["adminUsers"]
            fileGroups = fileProps["adminGroups"]

            user = YAML.load_file(fullPath)

            if(fileUsers.index(";#{userName}(rp") != nil || fileUsers.index(";#{userName}(rwp") != nil ||
                    fileUsers.index(";everyone(rp") != nil || fileUsers.index(";everyone(rwp") != nil)
                return true
            end
            at = 0
            while(user["adminGroup#{at}"] != nil)

                group = user["adminGroup#{at}"]
                at = at.next
                if(fileGroups.index(";#{group}(rp") != nil || fileGroups.index(";#{group}(rwp") != nil ||
                        fileGroups.index(";everyone(rp") != nil || fileGroups.index(";everyone(rwp") != nil)
                    return true
                end
            end
            return false

        elsif(!checkDirectoryAccessPublish(userName,filePath[0..filePath.rindex(@FS)]))
            return false
        else
            return true
        end
    end

    def getUserProps(sessionId, userName)
      if(userName == nil || sessionId == nil)
          return nil
      end

      return YAML.load_file(GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{userName}.yaml"))
    end
    #private :getUserProps

    def getUserName(sessionId, userName)

        if(userName == nil)
            return "Username was nil!"
        end
        user = getUserProps(sessionId, userName)
        if(user != nil)
          return "#{user["fname"]} #{user["lname"]}"
        else
          return "User not Found!"
        end
    end

    def getUserEmail(*args)
      userName = nil
      sessionId = ""
      if(args.size == 1)
        userName = args[0]
      elsif(args.size == 2)
        sessionId = args[0]
        userName = args[1]
      end
      if(userName == nil)
          return "Username was nil!"
      end
      user = getUserProps(sessionId, userName)
      if(user != nil)
        return user["email"]
      else
        return "User not Found!"
      end

    end

    def getUserField(*args)

      sessionId = ""
      userName = nil
      field = ""
      if(args.size == 2)
        userName = args[0]
        field = args[1]
      elsif(args.size == 3)
        sessionId = args[0]
        userName = args[1]
        field = args[2]
      end


      if(userName == nil)
          return "Username was nil!"
      end
      if(field == "password")
        return "Passwords are secret...."
      end
      user = getUserProps(sessionId, userName)
      if(user != nil)
        return user[field]
      else
        return "User not Found!"
      end

    end

    def getUserFields(*args)
      userName = nil
      sessionId = ""
      if(args.size == 1)
        userName = args[0]
      elsif(args.size == 2)
        sessionId = args[0]
        userName = args[1]
      end

      if(userName == nil)
          return "Username was nil!"
      end

      if(userName != nil)
        #puts "AdminAccessControler 913: #{sessionId} #{userName}"
        user = getUserProps(sessionId, userName)
        #puts "User: #{user}"
        #puts "From delete: #{user.delete("Sassword")}"
        user.delete("password")
        return user
      else
        return "User not Found!"
      end
    end


    def checkModuleAccess(userName, sessionId, moduleName)
        user = getUserProps(sessionId, userName)
        at = 0
        while(user["adminGroup#{at}"] != nil)

            group = user["adminGroup#{at}"]
            at = at.next
            allModsLoadFile = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{group}Mods.yaml")
            if(File.exist?(allModsLoadFile))

                allMods = YAML.load_file(allModsLoadFile)
                if (allMods.key?(moduleName) && allMods[moduleName] == "true")
                    return true
                end
            end
        end
        return false

    end

    def checkGroupModuleAccess(groupName, sessionId, moduleName)


        allModsLoadFile = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/#{groupName}Mods.yaml")
        if(File.exist?(allModsLoadFile))

            allMods = YAML.load_file(allModsLoadFile)
            if (allMods.key?(moduleName) && allMods[moduleName] == "true")
                return true
            end
        end
        return false
    end



    def getAllGroups(sessionId)



        allGroupsDir = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/.profiles/")
        if(File.directory?(dir))
          Dir.chdir(dir)
          filtered = Dir.glob("*Mods.yaml")
          groups = Array.new
          at = 0
          filtered.each{ |group|
            groups[at] = group[0..group.index("Mods.yaml")-1]
            at = at.next
          }
        end
        return Array.new
    end




    def setUserField(userName, field, value)

      if(userName == nil)
          return false
      end
      user = getUserProps("", userName)
      user[field] = value
      File.write(GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/dashboard/default/.profiles/#{userName}.yaml"), user.to_yaml)
      return true

    end


end
