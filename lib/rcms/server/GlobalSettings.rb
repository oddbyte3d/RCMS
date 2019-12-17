
 # Loads settings required by the RCMS server.
 # @author staylor
require "yaml"
require "date"
require_relative 'net/HttpSession'
require_relative '../util/Parser'
require_relative '../util/PropertyLoader'
require_relative '../object_repository/ObjectRepositoryManager'
require_relative '../object_repository/ObjectRepository'
require_relative '../object_repository/FileSafe'

class GlobalSettings

    @@INITIALIZED = false
    @@CURRENT_USERS = Hash.new

    @@FORMAT_DATE_DAY = 0
    @@FORMAT_DATE_DAY_TIME = 1
    @@FORMAT_DATE_TIME = 2

    @@GLOBALS_FILE = "/home/scott/Development/Ruby/Gems/RCMS/lib/rcms/globals.yaml"
    @@XML_CACHE_REPOSITORY = "XMLModCache.obj"
    @@SETTINGS = nil
    #@@SETTINGS = loadSettingsFile
    #@nextGlobal
    @@FS = File::SEPARATOR

    def initialize

      GlobalSettings.loadSettingsFile
      puts "GlobalSettings initialized...\n\n#{@@SETTINGS}"
      #private static final String repositoryCacheName = "RepositoryCache.obj";
    end

    def self.generate_code(number)
      charset = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9')
      Array.new(number) { charset.sample }.join
    end


    #Loads the Global settings from a properties file
    #@param path Path to the global properties

    def self.loadSettingsFile
      @OBMANAGER = ObjectRepositoryManager.new
      puts "Try to load : #{@@GLOBALS_FILE}"
      @@SETTINGS = YAML.load_file(@@GLOBALS_FILE)
      #puts "Settings\n#{@@SETTINGS}"
      if @@SETTINGS != nil

        for key in @@SETTINGS.keys do

          if @@SETTINGS[key].is_a? String

              value = @@SETTINGS[key]
              if( key.start_with?("LoadDBConnection") && value.index("CONNECT_STRING#") != nil &&
              value.index("DRIVER#") != nil && value.index("USER#") != nil && value.index("PASS#") != nil && value.index("GLOBAL_KEY#") != nil)

                  startConnectString = value.index("CONNECT_STRING#")+15
                  endConnectString = value.index("#",startConnectString)-1
                  startDriver = value.index("DRIVER#")+7
                  endDriver = value.index("#",startDriver)-1
                  startUser = value.index("USER#")+5
                  endUser = value.index("#",startUser)-1
                  startPass = value.index("PASS#")+5
                  endPass = value.index("#",startPass)-1
                  startKey = value.index("GLOBAL_KEY#")+11
                  endKey = value.index("#",startKey)-1


                  connectString = value[startConnectString..endConnectString]
                  driver = value[startDriver..endDriver]
                  user = value[startUser..endUser]
                  pass = value[startPass..endPass]

                  globalKey = value[startKey..endKey]
                  puts "Placeholder-- Load DB Connection: #{connectString} : #{driver} : #{user} : #{pass} : #{globalKey}"
              end
              if(key.start_with?("LoadRepository") && value.index("REPOSITORY#") != nil && value.index("CLASS#") != nil)

                  startConnectString = value.index("REPOSITORY#")+11
                  endConnectString = value.index("#",startConnectString)-1
                  startDriver = value.index("CLASS#")+6
                  endDriver = value.index("#",startDriver)-1

                  repository = value[startConnectString..endConnectString]
                  driver = value[startDriver..endDriver]

                  #puts "Placeholder -- Load Repository - #{repository} #{driver}"
                  @OBMANAGER.addObjectRepository(repository, "#{@@SETTINGS["Server-CachePath"]}#{repository}",driver)

              end
            end
          end #End of loop

          @@INITIALIZED = true;
    	end
    end

    def getVersionRequested(request)

        int version = -1; #req.query["foo"]
        if request.query["version"] != nil
            version = request["version"]
        end
        return version
    end

    def enqueueJavascriptIncludes(session, javaScript)

        javascriptInc = Array.new
        if session["AddJavaScriptInc"] != nil
            javascriptInc = session["AddJavaScriptInc"]
        end
        javascriptInc << javaScript
        session ["AddJavaScriptInc"] = javascriptInc
    end

    def getEnqueuedJavascriptIncludes(session)

        javascripts = session["AddJavaScriptInc"]
        session.delete("AddJavaScriptInc")
        return javascripts
    end

    def includeEnqueuedJavascriptIncludes(session, content)

        #StringBuffer scriptIncludes = new StringBuffer();
        js = getEnqueuedJavascriptIncludes(session);
        if js != nil
            for i in 0..js.size
                if(content.index(js[i]) == nil)
                    scriptIncludes.concat("\t<script type=\"text/javascript\" src=\"#{js[i]}\"></script>\n\t");
                end
            end
        end
        #TO-DO  -- Take parsing functions out of XMLDocument
        content = Parser.replaceAll(content, "</head>", "#{scriptIncludes}\n</head>")
        #content = parser.replaceAllInString(content, "</head>", scriptIncludes.toString()+"\n</head>");
        return content
    end


=begin
    public static TemplateFile getModuleTemplateFile(HttpServletRequest request, String xmlFile, String templateType)
            throws FileNotFoundException, IOException
    {
        String fs = GlobalSettings.getFileSeparator();
        File tempDir = GlobalSettings.getTemplateDirectory(request);

        Properties templateProps = new Properties();
        templateProps.load(new FileInputStream(tempDir+
                fs+"template.properties"));

        System.out.println("----------------------------------\n"+templateProps+"\n----------------------------------\n");

        File newsTemplate = null;
        String workarea = GlobalSettings.getCurrentWorkArea(request.getSession());
        if(templateProps.containsKey(templateType))
            newsTemplate = new File(tempDir.getAbsolutePath()+fs+templateProps.getProperty(templateType));
        else
            newsTemplate = new File(workarea+"system"+fs+"templates"+fs+"Modules"+fs+templateType+".html");


        System.out.println(templateType+" file:"+newsTemplate);

        Page cuppaPage = new Page(new File(workarea+xmlFile), request.getSession());
        TemplateFile tf = new TemplateFile(tempDir, newsTemplate, cuppaPage);
        return tf;

    }
=end

    def getTemplateDirectory(request)
        theme = getTemplate(request);
        templateDir = File.absolute_path(getDocumentDataDirectory())+@@FS+"system"+@@FS+"templates"+@@FS+theme
        return templateDir
    end

    def getTemplate(request)

        baseDocRoot = GlobalSettings.getGlobal("Base-DocRoot")
        baseDocRootLenght = baseDocRoot.size
        baseDocRootInc = GlobalSettings.getGlobal("Base-DocRoot-Include")

        optionReplaceTmp = GlobalSettings.getGlobal("OptionReplace")
        themeBase = GlobalSettings.getGlobal("Theme-Base")

        fileToRender = '/index.xml'#request.getRequestURL().toString().
                #substring(request.getRequestURL().toString().indexOf(baseDocRoot,9)+baseDocRootLenght);

        if optionReplaceTmp != "NO-REPLACE"
            fileToRender = Parser.replaceAll(fileToRender, optionReplaceTmp, "")
        end
        theme = fileToRender
        if fileToRender.index("/") != nil
            theme = fileToRender[0..fileToRender.rindex("/")]
        end
        if !theme.start_with?(themeBase)
            theme = themeBase+theme
        end

        properties = PropertyLoader.new(GlobalSettings.getGlobal("Parent-PropertyFile"))#YAML.load_file(getGlobal("Parent-PropertyFile"))
        #puts "PropertyLoader done...\n#{properties}"

        tmpTheme = theme
        themeFound = false
        while tmpTheme != "" do
          puts "TemplateDirectory : #{properties.getProperties('TemplateDirectory')}"

            if(properties.getProperties("TemplateDirectory")[tmpTheme] != nil)
                theme = properties.getProperties("TemplateDirectory")[tmpTheme]
                themeFound = true
                #break
            else
                tmpTheme = tmpTheme[0..tmpTheme.rindex("/")]
            end
        end
        if !themeFound
            theme = properties.getProperties("TemplateDirectory")["default"]
        end
        return theme
    end


    def getVersion
        return @CUPPAWEB_VERSION
    end


    def getUserCurrentPath(userSession)

        if(userSession["CuppaWEB:CurrentPath"] != nil)
            return FileCMS.new(userSession, userSession["CuppaWEB:CurrentPath"])
        else
            return FileCMS.new(userSession, "/index.xml")
        end
    end

    def removeUserSession(userSession)
        @@CURRENT_USERS.delete(getUserLoggedIn(userSession))
    end

    def addUserSession(userSession)

        if !@@CURRENT_USERS.containsKey?(getUserLoggedIn(userSession))
            @@CURRENT_USERS[getUserLoggedIn(userSession)] = userSession
        else

            @@CURRENT_USERS.delete(getUserLoggedIn(userSession))
            @@CURRENT_USERS[getUserLoggedIn(userSession)] = userSession
        end
    end

    def getUserSession(userName)

        if @@CURRENT_USERS[userName] != nil
          return @@CURRENT_USERS[userName]
        end
        return nil
    end


    def getUsersLoggedIn
        return @@CURRENT_USERS
    end

    #Return repository keys
    def getLoadedRepositoryNames
        return @OBMANAGER.listRepositorys
    end

    def getLoadedRepository(repositoryName)
        return @OBMANAGER.getObjectRepsoitory(repositoryName)
    end
=begin
    public static java.sql.Connection getLoadedDBConnection(String connectionName)
    {
        if(getGlobal(connectionName) != null && getGlobal(connectionName) instanceof java.sql.Connection)
        {
            java.sql.Connection conn = (java.sql.Connection)getGlobal(connectionName);
            try {
                if (!conn.isValid(5)) {
                    Logger.doLog(Logger.INFO, "The database connection:"+connectionName+" was stale, attempt to reload");
                    GlobalSettings.reloadDBConnection(connectionName);
                    Logger.doLog(Logger.INFO, "The database connection:"+connectionName+" was stale, it was reloaded");
                }
            } catch (SQLException ex) {
                Logger.doLog(Logger.FATAL, ex, GlobalSettings.class);
            }
            return (java.sql.Connection)getGlobal(connectionName);
        }
        else
        {
            GlobalSettings.reloadDBConnection(connectionName);
            java.sql.Connection conn = (java.sql.Connection)getGlobal(connectionName);
            try {
                if (!conn.isValid(5)) {
                    Logger.doLog(Logger.INFO, "The database connection:"+connectionName+" was stale, attempt to reload");
                    GlobalSettings.reloadDBConnection(connectionName);
                    Logger.doLog(Logger.INFO, "The database connection:"+connectionName+" was stale, it was reloaded");
                }
            } catch (SQLException ex) {
                Logger.doLog(Logger.FATAL, ex, GlobalSettings.class);
            }
            if(getGlobal(connectionName) != null && getGlobal(connectionName) instanceof java.sql.Connection)
                return (java.sql.Connection)getGlobal(connectionName);
            else
                return null;
        }
    }



     #TO-DO: Need to convert Tasks and implement...
     # Returns tasks assigned to a User(Admin or otherwise)
     # @param userName
     # @return

    public static final ArrayList<Task> getUserAssignedTasks(String userName)
    {
        userName = "User_"+userName;
        return getTasks(userName);
    }


     # Sets User assigned tasks
     # @param userName
     # @param tasks
     # @return

    private static final boolean setUserAssignedTasks(String userName, ArrayList<Task> tasks)
    {
        return setTasks("User_"+userName, tasks);
    }


    /**
     * Returns the pool of tasks assigned to a Group.
     * @param groupName
     * @return
     */
    public static final ArrayList<Task> getGroupAssignedTasks(String groupName)
    {
        groupName = "Group_"+groupName;
        return getTasks(groupName);
    }

    /**
     * Sets the pool of tasks assigned to a Group.
     * @param groupName
     * @param tasks
     * @return
     */
    private static final boolean setGroupAssignedTasks(String groupName, ArrayList<Task> tasks)
    {
        return setTasks("Group_"+groupName, tasks);
    }


    /**
     * Returns all tasks in the Unassigned pool
     * @return
     */
    public static final ArrayList<Task> getUnassignedTasks()
    {
        String poolName = "UnassignedPool";
        return getTasks(poolName);
    }

    /**
     * Sets the pool of unassigned tasks
     * @param tasks
     * @return
     */
    private static final boolean setUnassignedTasks(ArrayList<Task> tasks)
    {
        return setTasks("UnassignedPool", tasks);
    }

    /**
     * Returns tasks in a particular pool name (User/Group/Unassigned)
     * @param poolName
     * @return
     */
    private static final ArrayList<Task> getTasks(String poolName)
    {
        ObjectRepository tasks = GlobalSettings.getLoadedRepository("TaskQueues.obj");
        ArrayList<Task> poolTasks = new ArrayList<Task>();
        if(tasks != null && tasks.getRepositoryObject(poolName) != null)
            poolTasks = (ArrayList<Task>)tasks.getRepositoryObject(poolName).getContentObject();
        return poolTasks;

    }

    /**
     * Sets tasks in an arbitrary task pool
     * @param poolName
     * @param tasks
     * @return
     */
    private static final boolean setTasks(String poolName, ArrayList<Task> tasks)
    {
        ObjectRepository taskRepo = GlobalSettings.getLoadedRepository("TaskQueues.obj");
        System.out.println("Pool :"+poolName);
        System.out.println("Tasks :"+tasks);
        taskRepo.commitObject(poolName, tasks, false);
        return true;
    }


    public static final boolean saveTask(Task task)
    {
        if(task != null)
        {
            if(task.getAssignedUser() != null)
            {
                String userName = task.getAssignedUser();
                ArrayList<Task> userTasks = GlobalSettings.getUserAssignedTasks(userName);
                for(int i = 0; i < userTasks.size(); i++)
                    if(userTasks.get(i).getTaskId() == task.getTaskId())
                    {
                        userTasks.remove(i);
                        userTasks.add(i, task);
                    }

                return setUserAssignedTasks(userName, userTasks);
            }
            else if(task.getAssignedGroup() != null)
            {
                String groupName = task.getAssignedGroup();
                ArrayList<Task> groupTasks = GlobalSettings.getGroupAssignedTasks(groupName);
                for(int i = 0; i < groupTasks.size(); i++)
                    if(groupTasks.get(i).getTaskId() == task.getTaskId())
                    {
                        groupTasks.remove(i);
                        groupTasks.add(i, task);
                    }
                return setGroupAssignedTasks(groupName, groupTasks);
            }
            else
            {
                ArrayList<Task> unassignedTasks = GlobalSettings.getUnassignedTasks();
                for(int i = 0; i < unassignedTasks.size(); i++)
                    if(unassignedTasks.get(i).getTaskId() == task.getTaskId())
                    {
                        unassignedTasks.remove(i);
                        unassignedTasks.add(i, task);
                    }
                return setUnassignedTasks(unassignedTasks);

            }
        }
        return false;
    }


    /**
     * Submits a task to the pools and sorts out which pool to assign to.
     * @param task
     * @return
     */
    public static final boolean submitTask(Task task)
    {
        if(task != null)
        {
            if(task.getAssignedUser() != null)
            {
                String userName = task.getAssignedUser();
                ArrayList<Task> userTasks = GlobalSettings.getUserAssignedTasks(userName);
                userTasks.add(task);
                return setUserAssignedTasks(userName, userTasks);
            }
            else if(task.getAssignedGroup() != null)
            {
                String groupName = task.getAssignedGroup();
                ArrayList<Task> groupTasks = GlobalSettings.getGroupAssignedTasks(groupName);
                groupTasks.add(task);
                return setGroupAssignedTasks(groupName, groupTasks);
            }
            else
            {
                ArrayList<Task> unassignedTasks = GlobalSettings.getUnassignedTasks();
                unassignedTasks.add(task);
                return setUnassignedTasks(unassignedTasks);

            }
        }
        return false;
    }
=end




     # Global function to format dates using a system wide standard configured in CuppaWEB.properties
     # @param formatToUse
     # @param dToFormat
     # @return

    def self.formatDate(formatToUse, dToFormat)


        if(dToFormat == nil)
            dToFormat = Date.today
        end
        if(formatToUse != nil)
          sFormatToUse = "%d/%m/%Y"
        end
        #TO-DO: implement the Following....
        case formatToUse
        when @@FORMAT_DATE_DAY
          sFormatToUse = GlobalSettings.getGlobal("DateFormat_Day")
        when @@FORMAT_DATE_DAY_TIME
          sFormatToUse = GlobalSettings.getGlobal("DateFormat_DayTime")
        when @@FORMAT_DATE_TIME
          sFormatToUse = GlobalSettings.getGlobal("DateFormat_Time")
        end
        return dToFormat.strftime(sFormatToUse)
    end

    def getPageModuleCount(session, pagePath)
        return getPageModuleCount(session, pagePath, -1)
    end


    def getPageModuleCount(session, pagePath, version)

        if(version > -1)
          cmsf = FileCMS.new(session, pagePath)
          vf = cmsf.getVersionedFile()
          fv = vf.getVersionByNumber(version)
          if fv == nil
            version = -1
          else
            pagePath = getWebPath(fv.getThisVersion())
          end
        end
        if(!pagePath.start_with?("/"))
          pagePath = "/"+pagePath
        end
        pagePath = getWorkArea(session)+Parser.replaceAll(pagePath, "/", ".")

        #TO-DO: implement ObjectRepository system
        if(@OBMANAGER.getObjectRepsoitory(@@XML_CACHE_REPOSITORY).getRepositoryObject(pagePath) == nil)
            return -1
        else
            hmPage = @OBMANAGER.getObjectRepsoitory(@@XML_CACHE_REPOSITORY).getRepositoryObject(pagePath).getContentObject
            return hmPage.size
        end

    end

    def getPage(session, pagePath)
        return getPage(session, pagePath, -1)
    end

    def getPage(session, pagePath, version)

        if version > -1
          cmsf = FileCMS.new(session, pagePath)
          vf = cmsf.getVersionedFile()
          fv = vf.getVersionByNumber(version)
          if fv == nil
            version = -1
          else
            pagePath = GlobalSettings.getWebPath(fv.getThisVersion())
          end
        end
        if !pagePath.start_with?("/")
          pagePath = "/"+pagePath
        end
        pagePath = GlobalSettings.getWorkArea(session)+Parser.replaceAll(pagePath, "/", ".")

        #TO-DO: implement ObjectRepository
        #return (obManager.getObjectRepsoitory(xmlCacheRepositoryName).getRepositoryObject(pagePath) != null);
    end


    def getPageModule(session, request, pagePath, index)

        version = -1
        if request.getParameter("version") != nil
            version = request.getParameter("version").to_i
        end
        return getPageModule(session, pagePath, index, version)
    end


    def getPageModule(session, pagePath, index)
        return getPageModule(session, pagePath, index, -1)
    end

    def getPageModule(session, pagePath, index, version)

        if(version > -1)

          cmsf = FileCMS.new(session, pagePath)
          vf = cmsf.getVersionedFile()
          fv = vf.getVersionByNumber(version)
          if fv == nil
              version = -1
          else
              pagePath = GlobalSettings.getWebPath(fv.getThisVersion())
          end
        end
        if !pagePath.start_with?("/")
            pagePath = "/"+pagePath
        end
        pagePath = GlobalSettings.getWorkArea(session)+Parser.replaceAll(pagePath, "/", ".")

        hmPage = nil
        #TO-DO: Implement ObjectRepository system
=begin
        if(obManager.getObjectRepsoitory(xmlCacheRepositoryName).getRepositoryObject(pagePath) == null)
            return null;
        else
        {
            hmPage = ((HashMap)obManager.getObjectRepsoitory(xmlCacheRepositoryName).getRepositoryObject(pagePath).getContentObject());
            if(hmPage.containsKey(new Integer(index)))
            {
                PageModule page = (PageModule)hmPage.get(new Integer(index));
                //System.out.println("Returning page module :"+page);
                if(page.getIndex() != index)
                    page.setIndex(index);
                return page;
            }
            else
                return null;
        }
=end
    end



    def self.clearPageModules(*args)

      if(args.size == 3)
        clearPageModules_3(args[0], args[1], args[2])
      else

          workArea = GlobalSettings.getWorkArea(session)
          repo = @OBMANAGER.getObjectRepsoitory(@@XML_CACHE_REPOSITORY)
          arr = repo.getRepositoryKeys()
          arr.each{ |key|
            if(key.start_with?(workArea))
              repo.removeRepositoryObject(key)
            end

          }
      end
    end

    def self.clearPageModules_3(session, pagePath, version)

        if(version > -1)

            cmsf = FileCMS.new(session, pagePath)
            vf = cmsf.getVersionedFile
            fv = vf.getVersionByNumber(version)
            puts "Version File ::: #{vf.getVersionByNumber(version)}"
            if(fv == nil)
                version = -1
            else
                pagePath = GlobalSettings.getWebPath(fv.getThisVersion)
            end
        end
        workingDir = GlobalSettings.getWorkArea(session)

        dataArea = GlobalSettings.getDocumentDataDirectory()
        workArea = GlobalSettings.getDocumentWorkAreaDirectory()
        puts "DataArea : #{dataArea}"
        if(pagePath.start_with?(workArea))
            pagePath = Parser.replaceAll(pagePath, workArea, "")
            workingDir = "WORKAREA"
        elsif(pagePath.start_with?(dataArea))

            pagePath = Parser.replaceAll(pagePath, dataArea, "")
            workingDir = "LIVE"
        end

        if(!pagePath.start_with?("/"))
            pagePath = "/#{pagePath}"
        end
        origPagePath = pagePath
        pagePath = "#{workingDir}#{Parser.replaceAll(pagePath, "/", ".")}"
        puts "Clearing:: #{pagePath} version :#{version}"

        @OBMANAGER.getObjectRepsoitory(@@XML_CACHE_REPOSITORY).removeRepositoryObject(pagePath)
        if(workingDir == "WORKAREA")

            clear = Parser.replaceAll("#{workArea}#{origPagePath[1..origPagePath.size-1]}", "/", "-")
            puts "Clearing 2:: #{clear}"
            @OBMANAGER.getObjectRepsoitory(@@XML_CACHE_REPOSITORY).removeRepositoryObject(clear)

        else
          puts "OriginalPath:"
          clear = Parser.replaceAll("#{dataArea}#{origPagePath[1..origPagePath.size-1]}", "/", "-")
          puts "Clearing 2:: #{clear}"
          @OBMANAGER.getObjectRepsoitory(@@XML_CACHE_REPOSITORY).removeRepositoryObject(clear)
        end
    end

    def setPageModule(session, pagePath, index, data) #data is a PageModule
        setPageModule(session, pagePath, index, data, -1)
    end

    def setPageModule(session, pagePath, index, data, version) #data is a PageModule
=begin
        if(version > -1)
        {
            try{
                FileCMS cmsf = new FileCMS(session, pagePath);
                VersionedFile vf = cmsf.getVersionedFile();
                FileVersion fv = vf.getVersionByNumber(version);
                if(fv == null)
                    version = -1;
                else
                    pagePath = GlobalSettings.getWebPath(fv.getThisVersion());
            }catch(Exception e)
            {
                Logger.doLog(Logger.ERROR, e, GlobalSettings.class);
            }
        }
        if(!pagePath.startsWith("/"))
            pagePath = "/"+pagePath;

        pagePath = GlobalSettings.getWorkArea(session)+parser.replaceAllInString(pagePath, "/", ".");
        //System.out.println("+++++>"+obManager.getObjectRepsoitory(xmlCacheRepositoryName).getRepositoryObject(pagePath));
        HashMap hmPage = null;
        if(obManager.getObjectRepsoitory(xmlCacheRepositoryName).getRepositoryObject(pagePath) == null)
            hmPage = new HashMap();
        else
            hmPage = ((HashMap)obManager.getObjectRepsoitory(xmlCacheRepositoryName).getRepositoryObject(pagePath).getContentObject());
        data.setIndex(index);
        hmPage.put(new Integer(index), data);
        //System.out.println("Saving XML Cache object :"+pagePath+"\n\tObject type:"+hmPage.getClass().getName()+" and "+data);
        obManager.getObjectRepsoitory(xmlCacheRepositoryName).commitObject(pagePath, hmPage, true);
=end
    end

    def loadFileBytes(loginName, file)
      if sloginName == nil
        loginName = "guest"
      end
      baseDocRoot = GlobalSettings.getGlobal("Base-DocRoot")
      baseDocRootInc = GlobalSettings.getGlobal("Base-DocRoot-Include")
      file = GlobalSettings.changeFilePathToMatchSystem(file)

      if baseDocRoot != "/" && file.index(baseDocRoot) != nil
          file = Parser.replaceAll(file, baseDocRoot, "")
      end
      dataPath = GlobalSettings.getGlobal("Server-DataPath")

      if File.exist?(dataPath+file)
          if !AccessControler.checkUserFileAccess(loginName, dataPath+file)
            return nil
          else
            return File.read(dataPath+file)
          end
      end
      return nil
    end

    def parseLink(path)

        if( !path.downcase.start_with?("http://") && !path.downcase.start_with?("ftp://") &&
            !path.downcase.start_with?("https://") && !path.downcase.start_with?("mailto:") &&
                !path.start_with(GlobalSettings.getBaseDocRoot()) )
            path = GlobalSettings.getBaseDocRoot()+path
        end
        if(path.startsWith("/"))
            path = Parser.replaceAll(path,"//","/")
        end
        return path
    end

=begin
    public static String parseColor(java.awt.Color c)
    {
        String redHex = Integer.toHexString(c.getRGB());
        return "#"+redHex.substring(2);
    }


    public static java.awt.Color parseColorString(String hexToParse)
    {
        try
        {
            int color = Integer.decode(hexToParse).intValue();
            return new java.awt.Color(color);
        }
        catch(NumberFormatException ne)
        {
            Logger.doLog(Logger.ERROR, ne, GlobalSettings.class);
        }
        return new java.awt.Color(255,255,255);

    }
=end

    def saveSettingsFile
        props = Hash.new
        #File settingsFile = new File(globalFile.getFile());
        if File.exist?(@GLOBALS_FILE)

            for key in @@SETTINGS.keys

                if @@SETTINGS[key].is_a?(String)

                    props[key] = @@SETTINGS[key]
                end
            end
            File.write(@GLOBALS_FILE, props.to_yaml)
            return true
        end
        return false
    end

    # Initializes all parameters

    def self.init(reinit)

        if @@SETTINGS == nil || !@@INITIALIZED || reinit

            @@SETTINGS = nil
            GlobalSettings.loadSettingsFile()

        end
        if(@@SETTINGS != nil && !@@SETTINGS.key?("ActiveRepositoryLoader"))
            #@OBMANAGER.addObjectRepository(    repositoryCacheName, settings.get("Server-CachePath")+repositoryCacheName,
            #                    "FileSafe");

            #@OBMANAGER.addObjectRepository(    "FileSafe.obj", settings.get("Server-CachePath")+"FileSafe.obj",
            #                    "de.codefactor.ObjectRepository.FileSafe");

            #@OBMANAGER.addObjectRepository(    "PublishList.obj", settings.get("Server-CachePath")+"PublishList.obj",
            #                    "de.codefactor.ObjectRepository.FileSafe");
            @OBMANAGER.addObjectRepository(@@XML_CACHE_REPOSITORY, "#{@@SETTINGS["Server-CachePath"]}#{@@XML_CACHE_REPOSITORY}",
                                "FileSafe")


            @@SETTINGS["ActiveRepositoryLoader"] = @OBMANAGER
          testH = true
        end


    end
=begin
    def addPublishSchedule(myPubSched)

        String name = com.cuppait.util.RandomPassword.generatePasswordString(20, new char[]{'0','1','2','3','4','5','6','7','8','9'});
        ObjectRepository publishRepo = GlobalSettings.getLoadedRepository("PublishSchedules.obj");

        while(publishRepo.getRepositoryObject(name) != null)
            name = com.cuppait.util.RandomPassword.generatePasswordString(20, new char[]{'0','1','2','3','4','5','6','7','8','9'});
        if(publishRepo.getRepositoryObject(name) == null)
        {
            publishRepo.commitObject(name, myPubSched, false);
            return true;
        }
        return false;
    end

    public static void removePublishSchedule(String key)
    {
        ObjectRepository publishRepo = GlobalSettings.getLoadedRepository("PublishSchedules.obj");
        ;
        if(publishRepo.getRepositoryObject(key) != null)
        {
            publishRepo.removeRepositoryObject(key);
            publishRepo.saveRepository();
        }

    }

    public static PublishSchedule getPublishSchedule(String key)
    {
        ObjectRepository publishRepo = GlobalSettings.getLoadedRepository("PublishSchedules.obj");
        return (PublishSchedule)publishRepo.getRepositoryObject(key).getContentObject();
    }

    public static Object[] getPublishScheduleKeys()
    {
        ObjectRepository publishRepo = GlobalSettings.getLoadedRepository("PublishSchedules.obj");
        return publishRepo.getRepositoryKeys().toArray();
    }
=end

    #Changes a path to fit local settings ie from Unix to Win etc...
    #@param path The path to convert
    #@return Converted path

    def self.getWebPath(*args)
      case args.size
      when 1
        toGet = args[0]
        path = File.absolute_path(toGet)

        dataDir = File.absolute_path(self.getDocumentDataDirectory())
        workDir = File.absolute_path(self.getDocumentWorkAreaDirectory())

        #puts "Path #{path}"
        #puts "Workdir #{workDir}"
        if(path.upcase.start_with? (workDir.upcase) )
          dataDir = workDir
        end
        if(path.upcase.start_with? (dataDir.upcase))
            path = path[dataDir.size..path.size]
            if(@@FS == "\\" || path.index("\\") != nil)
                path = Parser.replaceAll(path,"\\","/")
            end
            if(path.start_with?("/"))
                return path
            else
                return "/#{path}"
            end
        end
        puts "returning nil"
        return nil


      when 2
        session = args[0]
        toGet = args[1]

        path = File.absolute_path(toGet)
        dataDir = GlobalSettings.changeFilePathToMatchSystem(getCurrentWorkArea(session))

        if path.start_with(dataDir)

            path = path[dataDir.size]
            if @@FS == "\\"
                path = Parser.replaceAll(path,@@FS,"/")
            end
            return "/"+path
        end
        return nil
      end
    end


    def self.getConfigPath(toGet)

        path = File.absolute_path(toGet)
        dataDir = GlobalSettings.getDocumentConfigDirectory()
        if(path.toUpperCase().startsWith(dataDir.toUpperCase()))

            path = path[dataDir.size]
            if @@FS == "\\" || path.index("\\") != nil
                path = Parser.replaceAll(path,"\\","/")
            end
            if path.start_with("/")
                return path
            else
                return "/"+path
            end
        end
        return nil
    end

    #Changes a path to fit local settings ie from Unix to Win etc...
    #@param path The path to convert
    #@return Converted path

    def self.changeFilePathToMatchSystem(path)

        if path.index('/') != nil && @@FS == "\\"
            path = Parser.replaceAll(path,"//",@@FS)
            path = Parser.replaceAll(path,"/",@@FS)
        elsif path.index('\\') != nil && @@FS == "/"
            path = Parser.replaceAll(path,"\\\\",@@FS)
            path = Parser.replaceAll(path,"\\",@@FS)
        end
        if path.index(@@FS+@@FS) != nil
            path = Parser.replaceAll(path,@@FS+@@FS,@@FS)
        end
        return path
    end

    #public static CuppaUser getUser(HttpSession session)
    #{
    #    return new CuppaUser(GlobalSettings.getUserLoggedIn(session));
    #}

    def self.getUserLoggedIn(session)
        #puts "Retrieving User: #{session}"
        if(session.instance_of?String)
          currentUser = @@CURRENT_USERS.containsKey?(session)
          if(AccessControler.new.userExists(session))
            return currentUser
          else
            return false
          end
        else

          if session["loginName"] != nil
              #puts "\n\nUser : #{session["loginName"]}\n\n"
              user = session["loginName"]
              if(AccessControler.new.userExists(user))
                return user
              end
          else
              return "guest"
          end
        end
    end

    def self.getModuleXMLFile(request)

        myXmlFile = request["xmlFile"]
        if request["contentBlockXML"] != nil
            myXmlFile = request["contentBlockXML"]
        elsif request["pageLoaded"] != nil
            myXmlFile = request["pageLoaded"]
        end
        return myXmlFile
    end


     # Returns the workarea name, either WORKAREA or LIVE
     # @param session
     # @return

    def self.getWorkArea(session)

        if session != nil && session["WORKAREA"] != nil
            return session["WORKAREA"]
        else
            return "LIVE"
        end
    end



     # Returns the full path to a user's current workarea
     # @param session
     # @return

    def self.getCurrentWorkArea(session)

        if session["WORKAREA"]!=nil && session["WORKAREA"] == "WORK"
            return File.absolute_path(GlobalSettings.getDocumentWorkAreaDirectory())+@@FS
        else
            return File.absolute_path(GlobalSettings.getDocumentDataDirectory())+@@FS
        end
    end



    def getModuleData(session, request, response)
        return getModuleData(session, request, response, -1)
    end


    def getModuleData(session, request, response, version)

        myXmlFile = getModuleXMLFile(request)
        if(version > -1)
          myXmlFile = (FileCMS.new(session, myXmlFile)).getVersionedFile().getVersionByNumber(version).getThisVersion()
        end
        #System.out.println("Trying to get data for:"+myXmlFile);
        if session[request["id"]] == nil

            if request["contentBlockXML"] != nil
                myXmlFile = request["contentBlockXML"]
            elsif request["pageLoaded"] != nil
                myXmlFile = request["pageLoaded"]
            end
            #TO-DO: Implement OutputRenderers
            #com.cuppait.cuppaweb.outputrenderers.ModuleDataMiner miner = new com.cuppait.cuppaweb.outputrenderers.ModuleDataMiner();
            #miner.mineGlobalData(request,response,session,myXmlFile);
        end

        data = Hash.new#((java.util.Hashtable)GlobalSettings.getGlobal(myXmlFile)).get(request.getParameter("id"))
        return data

    end

    #TO-DO: Implement CuppaUser... although a different name would be good
    def canCommentPage(session)

        #CuppaUser user = GlobalSettings.getUser(session);
        #return (user != null && user.userIsAdmin());
    end

    def canEditPage(session, request)

        if request["PREVIEW"] != nil && request["PREVIEW"] == "true"
            return false
        end
        if(session["CAN_EDIT"] != nil && session["CAN_EDIT"] == "true" &&
           request["EDIT_MODE"] != nil && request["EDIT_MODE"] == "true")

            dataPath = GlobalSettings.getDocumentWorkAreaDirectory()+@@FS
            return AccessControler.checkFileAccessWrite("default/", GlobalSettings.getUserLoggedIn(session), dataPath+request["xmlFile"])
        end
        return false
    end

    def hasEditPermissions(session, request)

        if(request["PREVIEW"] != nil && request["PREVIEW"] == "true")
            return false
        end
        if(session["CAN_EDIT"] != nil && session["CAN_EDIT"] == "true")

            dataPath = GlobalSettings.getDocumentWorkAreaDirectory()+@@FS
            return AccessControler.checkFileAccessWrite("default/", GlobalSettings.getUserLoggedIn(session), dataPath+request["xmlFile"])
        end
        return false
    end


    def isEditMode(session, request)

        if(request["PREVIEW"] != nil && request["PREVIEW"] == "true")
            return false
        else
            return (session["CAN_EDIT"] != nil && session["CAN_EDIT"] == "true" &&
                request["EDIT_MODE"] != nil && request["EDIT_MODE"] == "true")
        end
    end


    def canViewFileInWeb(session, check, fileFilter)

      return true
      #TO-DO: when time permits implement this....
      #  com.cuppait.file.DynamicFileFilter filter = new com.cuppait.file.DynamicFileFilter(fileFilter);
      #  if(check.isDirectory() && !check.getName().equals("BACKUP") && !check.getName().equals("CVS") && !GlobalSettings.getWebPath(check).equals("/system"))
      #  {
      #          for(int j = 0; j < fileFilter.length;j++)
      #              if(check.getName().equals(fileFilter[j]) || fileFilter[j].equals("*"))
      #                  return AccessControler.checkUserDirectoryAccess(GlobalSettings.getUserLoggedIn(session),check.getAbsolutePath());
      #  }
      #  else if(!check.isDirectory())
      #  {
      #      if(!check.getName().endsWith(".access") &&  !check.getName().endsWith("~"))
      #      {
      #          if(filter.accept(check))
      #              return AccessControler.checkUserFileAccess(GlobalSettings.getUserLoggedIn(session),check.getAbsolutePath());
      #      }
      #      else
      #          return false;
      #  }
      #  return false;
    end




    def getUserProperties(session)

        if session["loginName"] != nil
            return AccessControler.getUserProperties(session["loginName"])
        else
            return nil
        end
    end

    def getUserProperty(session, key)

        if session["loginName"] != nil
            return AccessControler.getUserField(session["loginName"], key)
        else
            return nil
        end
    end

    def setUserProperty(session, key, value)
        if session["loginName"] != nil
            AccessControler.setUserField(session["loginName"], key, value)
        end
    end

    #TO-DO: implement FileMetaData system, but the ObjectRepository system has priority
=begin
    public static void setFileMetaData(FileMetaData meta, String webPath)
    {
        if(!webPath.startsWith("/"))
            webPath = "/"+webPath;
        ObjectRepository obRep = GlobalSettings.getLoadedRepository("FileMetaData.obj");
        webPath = parser.replaceAllInString(webPath, "/", "_");
        obRep.commitObject(webPath, meta, false);
        obRep.saveRepository();
    }

    public static FileMetaData getFileMetaData(String webPath)
    {
        if(!webPath.startsWith("/"))
            webPath = "/"+webPath;
        ObjectRepository obRep = GlobalSettings.getLoadedRepository("FileMetaData.obj");
        webPath = parser.replaceAllInString(webPath, "/", "_");
        if(obRep.getRepositoryObject(webPath) == null)
            return new FileMetaData(webPath, new Properties());
        return (FileMetaData)obRep.getRepositoryObject(webPath).getContentObject();
    }
=end

    def getFileSeparator
        return @@FS
    end


    # Sets a global parameter which is kept in memory
     #  until the server is restarted.
     # @param key global hashMap Element
     # @param value new Object

    def putGlobal(key, value)
        if !@@INITIALIZED
            init(false)
        end
        @@SETTINGS[key] = value
    end

    def clearAllStartingWith(keyStart)

        hashGl = GlobalSettings.getAllGlobals()
        for key in hashGl
            if key.start_with(keyStart)
                GlobalSettings.removeGlobal(key)
            end
        end

    end

    # Retrieves a global parameter
     # @param key Hashtable Identifier
     # @return Object found, or null

    def self.getConfigPath()
        return props["Server-ConfigPath"]
    end

    # Retrieves a global parameter
     # @param key Hashtable Identifier
     # @return Object found, or null

    def self.getDocumentDataDirectory()
        return GlobalSettings.getGlobal("Server-DataPath")
    end

    def self.getDocumentWorkAreaDirectory()
        return GlobalSettings.getGlobal("Server-WorkAreaPath")
    end

    def self.getDocumentConfigDirectory()
        return GlobalSettings.getGlobal("Server-ConfigPath")
    end

    def self.getDocumentCacheDirectory()
        return GlobalSettings.getGlobal("Server-CachePath")
    end

    def self.getDocumentTempDirectory()
        return GlobalSettings.getGlobal("Server-TmpPath")
    end

    def self.getDocumentStatisticsDirectory()
        return GlobalSettings.getGlobal("Server-StatisticPath")
    end

    def self.getDocumentApplicationHomeDirectory()
        return GlobalSettings.getGlobal("Application-Home")
    end


    def self.getServerDocumentRoot()
        return GlobalSettings.getGlobal("Server-DocRootPath")
    end

    def self.getServerRoot()
        return GlobalSettings.getGlobal("Server-RootPath")
    end

    def self.getBaseDocRoot()
        return GlobalSettings.getGlobal("Base-DocRoot")
    end

    def self.getBaseDocRootInclude()
        return GlobalSettings.getGlobal("Base-DocRoot-Include")
    end

    def self.getCopyright()
        return GlobalSettings.getGlobal("copyright")
    end


    def self.setCuppaAdminSessionId(session, sessionId)

        session["CuppaADMIN.sessionId"] = sessionId
    end

    def self.getCuppaAdminSessionid(session)
        return session["CuppaADMIN.sessionId"]
    end

    # Retrieves a global parameter
     # @param key Hashtable Identifier
     # @return Object found, or null

    def self.getGlobal(key)

        if(!@@INITIALIZED)
            GlobalSettings.init(false)
        end

        if(@@SETTINGS.key?(key))
            return @@SETTINGS[key]
        else
            properties = PropertyLoader.new(GlobalSettings.getGlobal("Parent-PropertyFile"))
            cuppaWEBConfig = properties.getProperties("CuppaWEBConfig")

            if(cuppaWEBConfig == nil)
                return nil
            elsif(cuppaWEBConfig[key] == nil)
              return nil
            else
              return cuppaWEBConfig[key]
            end
        end

        return nil
    end

    # Retrieves all global parameters in a hashtable
     # @return Hashtable

    def getAllGlobals
        if(!@@INITIALIZED)
            init(false)
        end
        return @@SETTINGS
    end

    # Removes an object from the Globals and returns it to the caller
    # @param key global to remove
    # @return Object removed

    def removeGlobal(key)
      if(!@@INITIALIZED)
          init(false)
      end
      return @@SETTINGS.delete[key]
    end

end
