require "yaml"
require_relative "../user/RCMSUser"
require_relative "../user/RCMSGroup"
require_relative "../GlobalSettings"
require_relative "./AdminSession"

#import com.cuppait.file.DynamicFileFilter;
#import de.codefactor.web.admin.session.adminSession;

class AdminAccessControler

    @APPLICATION_HOME = GlobalSettings.getGlobal("Application-Home")
    @CONFIG_ROOT = GlobalSettings.getGlobal("Server-ConfigPath")
    @CONFIG_REST_PATH = "de/codefactor/instantsite/properties/users/"
    @FS = File::SEPARATOR
    @ACCESS_NONE = 0
    @ACCESS_READ = 1
    @ACCESS_READWRITE = 2
    @ACCESS_READPUBLISH = 3
    @ACCESS_FULL = 4

    def initialize

    end


    # Not sure what this is for...
    def checkUserPageAccess(user, pagePath)
        return false
    end

    def self.userExists(userName)

        if(userName == "root")
            return true
        end
        serverRoot = "default/"
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties"
        if(userName == nil)
            return false
        else
          user = YAML.load_file(fullPath)
          puts "Admin User: #{user}"
          if(user != nil)
              return true
          else
            return false
          end
        end
        return false
    end


    def self.listUsers

        userDir = "#{@APPLICATION_HOME}/webAdmin/servers/default/.profiles/"
        Dir.chdir(userDir)
        filtered = Dir.glob("*Profile.properties")
        users = Array.new
        at = 0
        filtered.each{ |user|

          users[at] = user[0..(user.index("Profile.properties")-1)]
          puts "Username : #{users[at]}"
          at = at.next
        }

        return users
    end

    def self.getServerRoot(sessionId)
      serverRoot = AdminSession.getFromSession(sessionId,"serverRoot");
      if(serverRoot == nil)
          serverRoot="default/"
      end
      return serverRoot
    end

    def self.groupExists(groupName)
        return File.exist?("#{@APPLICATION_HOME}/webAdmin/servers/default/.profiles/#{groupName}Mods.properties" )
    end

    def self.createNewGroup(groupName)
      group = Hash.new
      File.write("#{@APPLICATION_HOME}/webAdmin/servers/default/.profiles/#{groupName}Mods.properties", group.to_yaml)
    end

    def self.createNewUser(userName, initialGroup, userEmail, fname, lname, password)
        user = Hash.new;
        user["login"] = userName
        user["adminGroup0"] = initialGroup
        user["email"] = userEmail
        user["fname"] = fname
        user["lname"] = lname
        user["password"] = password
        File.write("#{@APPLICATION_HOME}/webAdmin/servers/default/.profiles/#{userName}Profile.properties", user.to_yaml)
    end

    def self.getModuleActions(sessionId, moduleName)
      serverRoot = AdminAccessControler.getServerRoot(sessionId)
      fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/Modules/#{moduleName}Actions.properties"
      return YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath) )
    end

    def self.getPossibleModuleActions(sessionId, moduleName)

        return AdminAccessControler.getModuleActions.keys
    end

    def self.getModuleActionLongDescription(sessionId, moduleName, actionName)
        return AdminAccessControler.getModuleActions[actionName]
    end

    def self.getModuleActionDescription(sessionId, moduleName, actionName)
        return AdminAccessControler.getModuleActions[actionName]
    end


    def self.canUseModuleAction(user, moduleName, moduleAction)

        if(user.USER_NAME == "root")
            return true
        end
        if(!AdminAccessControler.userHasModuleAction("", user.USER_NAME, moduleName, moduleAction))
            user.getAdminGroups.each{ |ngroup|
              return AdminAccessControler.groupHasModuleAction("", ngroup, moduleName, moduleAction)
            }
        else
            return true
        end
    end

    def self.canUseModuleAction(group, moduleName, moduleAction)
        return AdminAccessControler.groupHasModuleAction("", group.GROUP_NAME, moduleName, moduleAction)
    end

    #Return the user parameters from profile
    def self.getUser(sessionId, userName)
      serverRoot = AdminAccessControler.getServerRoot(sessionId)
      fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties"
      if(userName != nil)

        return YAML.load_file(fullPath)
      end
    end

    def self.setUserGroupAccess(sessionId, userName, groupName, access)
        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties"
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

    def self.userBelongsToGroup(sessionId, userName, groupName)

      user = AdminAccessControler.getUser
      if user.has_value?(groupName)
        return user.key(groupName).start_with?("adminGroup")
      end
      return false
    end


    def self.getModule(sessionId, moduleName)
      serverRoot = AdminAccessControler.getServerRoot(sessionId)
      fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/Modules/#{moduleName}.properties"
      if(userName != nil)

        return YAML.load_file(fullPath)
      end
    end

    def self.saveModule(sessionId, moduleName, mod)
      serverRoot = AdminAccessControler.getServerRoot(sessionId)
      fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/Modules/#{moduleName}.properties"
      if(userName != nil)

        File.write(fullPath, mod.to_yaml)
      end
    end



    def self.getGroupModule(sessionId, groupName)
      serverRoot = AdminAccessControler.getServerRoot(sessionId)
      groupPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{groupName}Mods.properties"
      return YAML.load_file(groupPath)
    end

    def self.saveGroupModule(sessionId, groupName, group)
      serverRoot = AdminAccessControler.getServerRoot(sessionId)
      groupPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{groupName}Mods.properties"
      File.write(groupPath, group.to_yaml)
    end


    def self.setGroupModuleAccess(sessionId, groupName, moduleName, access)

      group = AdminAccessControler.getGroupModule(sessionId, groupName)
      group[moduleName] = access
      AdminAccessControler.saveGroupModule(sessionId, groupName, group)
    end

    def self.setGroupModuleActionAccess(sessionId, groupName, moduleName, moduleAction, access)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/Modules/#{moduleName}.properties"

        if(groupName != nil)
          #Make sure that the group has appropriate access to the Module
          groupPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{groupName}Mods.properties"
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

    def self.setUserModuleAccess(sessionId, userName, moduleName, moduleAction, access)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/Modules/#{moduleName}.properties"

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

    def self.userHasModuleAction(sessionId, userName, moduleName, moduleAction)

        if userName == "root"
            return true
        end
        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/Modules/#{moduleName}.properties"
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

    def self.getModules(sessionId)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/Modules/LoadModules.properties"
        mod = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath))
        return mod
    end


    def self.groupHasModuleAction(sessionId, group, moduleName, moduleAction)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/Modules/#{moduleName}.properties"
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


    def self.checkUserLogin(sessionId, userName, userPass)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties"
        if(userName == nil)
            return false
        end
        user = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath) )
        userPassLoaded = user["password"]
        blocked = user["BLOCKED"]
        if(blocked == nil)
          blocked = "false"
        end
        if(userPassLoaded == userPass && blocked == "false")
          return true
        else
          return false
        end
    end

    def self.userBlocked(sessionId, userName)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties"
        if(userName == nil)
            return false
        end
        user = YAML.load_file(GlobalSettings.changeFilePathToMatchSystem(fullPath))
        blocked = user["BLOCKED"]
        if(blocked == nil || blocked == "true")
            return true
        else
            return false
        end
    end

    def self.deleteUser(sessionId, userName)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = "#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties"
        if(userName == nil)
            return false
        end
        return File.delete(fullPath)
    end

    def self.setUserFilePermissions(userName, filePath, permissions)

        if(userName == "root" && (permissions != @ACCESS_FULL || permissions != @ACCESS_READWRITE))
            return false
        end
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/default/.profiles/#{userName}Profile.properties")

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


    def self.setGroupFilePermissions(groupName, filePath, permissions)

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


    def self.changeUserPassword(sessionId, userName, oldPass, newPass, newPassConfirm)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties")
        if(newPass == newPassConfirm)

            if(AdminAccessControler.checkUserLogin(sessionId, userName, oldPass))

                if(userName == nil)
                    return false
                end
                user = YAML.load_file(fullPath)
                user["password"] = newPass
                File.write(fullPath, user.to_yaml)
                return true
            else
                return false
            end
        else
            return false
        end
    end


    def self.checkFileAccessRead(sessionId, userName, accessCheck)

        serverRoot = sessionId
        if(sessionId != nil && sessionId != "default/")
            if(adminSession.getSessionHash(sessionId)!= null)
                serverRoot = AdminSession.getFromSession(sessionId,"serverRoot")
            end
        end
        if(serverRoot == nil)
            serverRoot="default/"
        end
        return AdminAccessControler.checkFileAccessRead(serverRoot, userName, accessCheck.getAbsolutePath())

    end

    def self.checkFileAccessRead(serverRoot, userName, filePath)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        #if(serverRoot == null || serverRoot.trim().equals(""))
        #    serverRoot = "default/";

        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties")
        fAccess = "#{filePath}.access"

        if(File.exist?(fAccess))

            fileProps = YAML.load_file(fAccess)
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
            while(user.getProperty("adminGroup#{at}") != nil)

                group = user["adminGroup"].concat("#{at}")
                at = at.next
                if(fileGroups != nil && fileGroups.index(";#{group}(r") != nil ||
                  fileGroups.index(";everyone(r;") != nil)
                    return true
                end
            end
            return false

        elsif(!checkDirectoryAccessRead(serverRoot,userName,filePath[0..filePath.rindex(@FS)+1]))
            return false
        else
            return true
        end

        return false;
    end


    def self.checkGroupFileAccessRead(groupName, filePath)

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

    def self.checkGroupFileAccessWrite(groupName, filePath)

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

    def self.checkGroupFileAccessPublish(groupName, filePath)

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


    def self.checkDirectoryAccessRead(sessionId, userName, accessCheck)

        if(AdminSession.getSessionHash(sessionId)== nil)
            return false
        end
        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        return AdminAccessControler.checkDirectoryAccessRead(serverRoot, userName, File.absolute_path(accessCheck))

    end


    def self.checkDirectoryAccessRead(serverRoot, userName, filePath)

        if(serverRoot == nil || serverRoot.strip == "")
            serverRoot = "default/"
        end
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties")
        filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)

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



    def self.checkFileAccessWrite(sessionId, userName, accessCheck)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        return AdminAccessControler.checkFileAccessWrite(serverRoot, userName, File.absolute_path(accessCheck))

    end


    def self.checkFileAccessWrite(serverRoot, userName, filePath)

        if(serverRoot == nil || serverRoot.strip == "")
            serverRoot = "default/"
        end
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties")
        filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)
        fAccess = "#{filePath}.access"
        if(File.exist?(fAccess))

            fileProps = YAML.load_file(fAccess)
            fileUsers = fileProps["adminUsers"]
            fileGroups = fileProps["adminGroups"]

            if(userName == nil)
                return false
            end
            user = YAML.load_file(fullPath)

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

        elsif(!AdminAccessControler.checkDirectoryAccessWrite(serverRoot,userName,filePath[0..filePath.rindex(@FS)+1]))
            return false
        else
            return true
        end
        return false
    end


    def self.checkDirectoryAccessWrite(sessionId, userName, accessCheck)

        if(AdminSession.getSessionHash(sessionId)== nil)
            return false
        else
          serverRoot = AdminAccessControler.getServerRoot(sessionId)
          return AdminAccessControler.checkDirectoryAccessWrite(serverRoot, userName, File.absolute_path(accessCheck));
        end
    end


    def self.checkDirectoryAccessWrite(serverRoot, userName, filePath)

        if(userName == nil)
            return false
        end
        if(serverRoot == nil || serverRoot.strip =="")
            serverRoot = "default/"
        end
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties")
        filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)

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

            user = YAML.load_file(fullPath)


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


    def self.checkDirectoryAccessPublish(sessionId, userName, accessCheck)

        if(AdminSession.getSessionHash(sessionId)== nil)
            return false
        end
        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        return AdminAccessControler.checkDirectoryAccessPublish(serverRoot, userName, File.absolute_path(accessCheck))

    end


    def self.checkDirectoryAccessPublish(serverRoot, userName, filePath)

        if(userName == nil)
            return false
        end


        if(serverRoot == nil || serverRoot.strip == " ")
            serverRoot = "default/"
        end
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties")
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


    def self.checkFileAccessPublish(sessionId, userName, accessCheck)

        if(AdminSession.getSessionHash(sessionId) == nil)
            return false
        end
        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        return AdminAccessControler.checkFileAccessPublish(serverRoot, userName, File.absolute_path(accessCheck))

    end


    def self.checkFileAccessPublish(serverRoot, userName, filePath)

        if(userName == nil)
            return false
        end
        if(serverRoot == nil || serverRoot.strip == "")
            serverRoot = "default/"
        end
        fullPath = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties")
        filePath = GlobalSettings.changeFilePathToMatchSystem(filePath)

        fAccess = "#{filePath}.access"
        if(File.exist?(fAccess))

            fileProps = File.load_file(new FileInputStream(fAccess))
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

        elsif(!AdminAccessControler.checkDirectoryAccessPublish(serverRoot,userName,filePath[0..filePath.rindex(@FS)]))
            return false
        else
            return true
        end
    end

    def self.getUserProps(sessionId, userName)
            if(userName == nil || sessionId == nil ||sessionId == "")
                return nil
            end
            serverRoot = AdminAccessControler.getServerRoot(sessionId)
            return YAML.load_file(GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{userName}Profile.properties"))
    end
    #private :getUserProps

    def self.getUserName(sessionId, userName)

        if(userName == nil)
            return "Username was nil!"
        end
        user = self.getUserProps(sessionId, userName)
        if(user != nil)
          return "#{user["fname"]} #{user["lname"]}"
        else
          return "User not Found!"
        end
    end

    def self.getUserEmail(*args)
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
      user = self.getUserProps(sessionId, userName)
      if(user != nil)
        return user["email"]
      else
        return "User not Found!"
      end

    end

    def self.getUserField(*args)

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
      user = self.getUserProps(sessionId, userName)
      if(user != nil)
        return user[field]
      else
        return "User not Found!"
      end

    end

    def self.getUserFields(*args)
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
        user = self.getUserProps(sessionId, userName)
        #puts "User: #{user.class.name}"
        #puts "From delete: #{user.delete("Sassword")}"
        user.delete("password")
        return user
      else
        return "User not Found!"
      end
    end


    def self.checkModuleAccess(userName, sessionId, moduleName)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)

        user = AdminAccessControler.getUserProps("", userName)
        at = 0
        while(user["adminGroup#{at}"] != nil)

            group = user["adminGroup#{at}"]
            at = at.next
            allModsLoadFile = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{group}Mods.properties")
            if(File.exist?(allModsLoadFile))

                allMods = YAML.load_file(allModsLoadFile)
                if (allMods.key?(moduleName) && allMods[moduleName] == "true")
                    return true
                end
            end
        end
        return false

    end

    def self.checkGroupModuleAccess(groupName, sessionId, moduleName)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)
        allModsLoadFile = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/#{groupName}Mods.properties")
        if(File.exist?(allModsLoadFile))

            allMods = YAML.load_file(allModsLoadFile)
            if (allMods.key?(moduleName) && allMods[moduleName] == "true")
                return true
            end
        end
        return false
    end



    def self.getAllGroups(sessionId)

        serverRoot = AdminAccessControler.getServerRoot(sessionId)

        allGroupsDir = GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/#{serverRoot}.profiles/")
        if(File.directory?(dir))
          Dir.chdir(dir)
          filtered = Dir.glob("*Mods.properties")
          groups = Array.new
          at = 0
          filtered.each{ |group|
            groups[at] = group[0..group.index("Mods.properties")-1]
            at = at.next
          }
        end
        return Array.new
    end




    def self.setUserField(userName, field, value)

      if(userName == nil)
          return false
      end
      user = getUserProps("", userName)
      user[field] = value
      File.write(GlobalSettings.changeFilePathToMatchSystem("#{@APPLICATION_HOME}/webAdmin/servers/default/.profiles/#{userName}Profile.properties"), user.to_yaml)
      return true

    end


end
