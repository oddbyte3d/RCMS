$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), './' ) )
require 'exception/FileAccessDenied'
require 'exception/FileNotFound'
require 'rcms/server/net/HttpSession'
require 'rcms/server/security/AccessControler'
require 'fileutils'
require 'open-uri'
# FileCMS controls user access to files within the CMS
# @author staylor

class FileCMS

    attr_reader :SESSION, :FILE, :ADMIN_SESSION_ID, :VERSIONED_FILE
    #private File myFile;
    #private VersionedFile myVersionedFile;

    #private String userName;
    #private String adminSessionId;
    #private HttpSession session;
    def initialize(*args)
      case args.size
      when 2
        init_2(args[0], args[1])
      when 3
        if args[0].instance_of? HttpSession
          init_3(args[0], args[1], args[2])
        elsif args[0].instance_of? String
          init_3_user(args[0], args[1], args[2])
        end
      when 4
        init_4(args[0], args[1], args[2], args[3])
      end

    end


    def init_2( sess, path)
        init_3(sess,path,false)
    end


    def init_3(sess, path, create)

        @SESSION = sess
        @ACCESS_CONTROL = AccessControler.new
        @ADMIN_ACCESS_CONTROL = nil#AdminAccessControler.new
        @ADMIN_SESSION_ID = nil#GlobalSettings.getCuppaAdminSessionid(@SESSION)
        currentArea = GlobalSettings.getCurrentWorkArea(@SESSION)
        #puts "Workarea = #{currentArea}"
        if path.index(File.absolute_path(GlobalSettings.getDocumentDataDirectory())) == nil &&
                path.index(File.absolute_path(GlobalSettings.getDocumentConfigDirectory())) == nil &&
                path.index(File.absolute_path(GlobalSettings.getDocumentWorkAreaDirectory())) == nil
            path = "#{currentArea}#{path}"
            #puts "FileCMS 54 path=#{@FILE}"
        end
        @FILE = path
        #puts "FileCMS 57 path=#{@FILE}"
        @USER_NAME = GlobalSettings.getUserLoggedIn(@SESSION)
        #puts "User : #{@USER_NAME}"

        #Firstly check if we are dealing with an admin user, if the user can not access the file from a web session then throw an exception
        if @ADMIN_SESSION_ID != nil# && @ADMIN_ACCESS_CONTROL.checkFileAccessRead(@ADMIN_SESSION_ID, @USER_NAME, @FILE)
          raise FileAccessDenied.new("Read access denied to user: #{@USER_NAME} for file: #{File.absolute_path(@FILE)}")
        elsif @ADMIN_SESSION_ID == nil && !@ACCESS_CONTROL.checkUserFileAccess(@USER_NAME, File.absolute_path(@FILE))
          raise FileAccessDenied.new("Read access denied to user: #{@USER_NAME} for file: #{File.absolute_path(@FILE)}")
        end


        @VERSIONED_FILE = VersionedFile.new(@USER_NAME, @SESSION, @FILE)
        #TO-DO: create versioned file system and then implement the Following
        if (!File.exist?(@FILE) && @VERSIONED_FILE.getAllVersions() != nil)
          #puts "File does not exist..."
          raise FileNotFound.new("File #{@FILE} not found...")
            #FileVersion vers[] = myVersionedFile.getAllVersions();
        else

            if !File.exist?(@FILE) && !create
                raise FileNotFound.new("File: #{@FILE} does not exist!")
            elsif !File.exist?(@FILE)
                File.new(@FILE,  "w+")
            end
        end
    end

    def init_3_user(userName, sessionId, path)
        init_4(userName, sessionId, path, false)
    end


    def init_4(userName, sessionId, path, create)

        @USER_NAME = userName
        @ADMIN_SESSION_ID = sessionId
        @FILE = File.absolute_path(path)
        @ACCESS_CONTROL = AccessControler.new

        #If the user has no read permissions to this file then just throw an exception and do not provide the opportunity for access.
        if !@ADMIN_ACCESS_CONTROL.checkFileAccessRead(@ADMIN_SESSION_ID, @USER_NAME, @FILE)
          raise FileAccessDenied.new("Read access denied to user: #{@USER_NAME} for file: #{@FILE}")
        end

        @VERSIONED_FILE = VersionedFile.new(@USER_NAME, @SESSION, @FILE)

        if (!File.exist?(@FILE) && @VERSIONED_FILE.getAllVersions() != nil)
          #puts "File does not exist..."
          raise FileNotFound.new("File #{@FILE} not found...")
        else

          if (!File.exist?(@FILE) && !create)
              raise FileNotFound("File: #{@FILE} does not exist!");
          elsif (!File.exist?(@FILE) && create)
              File.new(@FILE,  "w+")
          end
        end

    end

    def exist?
      return File.exist?(@FILE)
    end


    def createCopy(copy, replaceIfExist)
      if !File.exist?(copy) || (File.exist?(copy) && replaceIfExist)
        return FileUtils.cp(@FILE, copy)
      end
    end

    def getMimeType

        return MimeTypes.getFileMimeType(@FILE)
    end

    def getFileExtension()

        if File.file?(@FILE)
            return File.extname(@FILE)
        else
            return "folder"
        end
    end



    def getFileURL
        return GlobalSettings.getWebPath(@FILE)
    end

    def canRead?
        return @ADMIN_ACCESS_CONTROL.checkFileAccessRead(@ADMIN_SESSION_ID, @USER_NAME, @FILE)
    end

    def canWrite?
      return @ADMIN_ACCESS_CONTROL.checkFileAccessWrite(@ADMIN_SESSION_ID, @USER_NAME, @FILE)
    end

    def canPublish?
      return @ADMIN_ACCESS_CONTROL.checkFileAccessPublish(@ADMIN_SESSION_ID, @USER_NAME, @FILE)
    end


     #Get a FileInputStream for the file resource based on type of FileCMS construction.
     #
     # @param sessionId
     # @param userName
     # @return
     # @throws java.io.FileNotFoundException
     # @throws com.cuppait.cuppaweb.file.FileAccessDenied

    def getFileForRead

        if @SESSION != nil
            if(@ACCESS_CONTROL.checkUserFileAccess(@USER_NAME, File.absolute_path(@FILE)))
              return open(@FILE)
            else
                raise FileAccessDenied.new("Read access denied to user: #{@USER_NAME} for file: #{File.absolute_path(@FILE)}")
            end
        elsif @ADMIN_SESSION_ID != nil

            if(@ACCESS_CONTROL.checkFileAccessRead(@ADMIN_SESSION_ID, @USER_NAME, @FILE))
                return open(@FILE)
            else
                throw new FileAccessDenied("Read access denied to user: #{@USER_NAME} for file: #{File.absolute_path(@FILE)}")
            end
        end
        return nil
    end


     # @param sessionId
     # @param userName
     # @return
     # @throws java.io.FileNotFoundException
     # @throws com.cuppait.cuppaweb.file.FileAccessDenied

    def getFileForWrite
      if @SESSION != nil
          if(@ACCESS_CONTROL.checkFileAccessWrite(@USER_NAME, File.absolute_path(@FILE)))
            return open(@FILE)
          else
              raise FileAccessDenied.new("Write access denied to user: #{@USER_NAME} for file: #{File.absolute_path(@FILE)}")
          end
      elsif @ADMIN_SESSION_ID != nil

          if(@ACCESS_CONTROL.checkFileAccessWrite(@ADMIN_SESSION_ID, @USER_NAME, @FILE))
              return open(@FILE)
          else
              throw new FileAccessDenied("Write access denied to user: #{@USER_NAME} for file: #{File.absolute_path(@FILE)}")
          end
      end
      return nil
    end

    def publishFile
        #System.out.println("Inside FileCMS.publishFile() publish to:"+GlobalSettings.getDocumentDataDirectory().getAbsolutePath()+this.getFileURL());
        if(AccessControler.checkFileAccessPublish("default/", @USER_NAME, File.absolute_path(@FILE)))

            if(File.exists?(@FILE))
              FileUtils.cp_r(@FILE, "#{File.absolute_path(GlobalSettings.getDocumentDataDirectory())}#{getFileURL()}")
              return true
            else   #This case, is when we are to publish a deleted file or better said unpublishing a file
              File.delete("#{File.absolute_path(GlobalSettings.getDocumentDataDirectory())}#{getFileURL()}")
              return true
            end
        else
            return false
        end
    end

    def publishVersion(version)
        if(@ADMIN_ACCESS_CONTROL.checkFileAccessPublish("default/", @USER_NAME, File.absolute_path(@FILE)))

            if(version == -1)
                return publishFile()
            end
            if(!File.exist?(@FILE))   #This case, is when we are to publish a deleted file or better said unpublishing a file
                return (new File(GlobalSettings.getDocumentDataDirectory().getAbsolutePath()+this.getFileURL())).delete();
            end
            versions = @VERSIONED_FILE.getAllVersions()
            versions.each { |n_version|
                if(version.getVersionNumber(n_version) == version)
                  if(n_version.getVersionType != FileVersion.TYPE_DELETED)
                      #return FileUtils.cp_r(n_version.thisVersion,
                      #          new File(GlobalSettings.getDocumentDataDirectory().getAbsolutePath()+this.getFileURL()), true);

                  else
                    return true
                  end
                end
            }
        end
        return false
    end


     #Enables safe deleting of a file. Checks permissions and makes a backup of the latest version.
     #
     # @return
     # @throws java.io.FileNotFoundException
     # @throws com.cuppait.cuppaweb.file.exception.FileAccessDenied
     # @throws java.io.IOException
=begin
    public boolean deleteFile()
            throws FileNotFoundException, FileAccessDenied, IOException
    {
        if(adminSessionId == null)
            throw new FileAccessDenied("File Access Denied!");
        if(de.codefactor.web.admin.security.AccessControler.checkFileAccessWrite(this.adminSessionId, this.userName, this.myFile))
        {
            this.myVersionedFile.createVersion(VersionedFile.BACKUP_DELETED);
            return this.myVersionedFile.getCurrentVersion().delete();
        }
        else
            throw new FileAccessDenied("Delete access denied to user: "+this.userName+" for file: "+this.myFile.getAbsolutePath());
    }
=end

    #Enables safe renaming of a file. Checks permissions and makes a backup of the latest version.
    #
     # @param newPath
     # @return
     # @throws java.io.FileNotFoundException
     # @throws com.cuppait.cuppaweb.file.exception.FileAccessDenied
     # @throws java.io.IOException
=begin
    public boolean renameFile(File newPath)
            throws FileNotFoundException, FileAccessDenied, IOException
    {
        if(adminSessionId == null)
            throw new FileAccessDenied("File Access Denied!");
        if(de.codefactor.web.admin.security.AccessControler.checkFileAccessWrite(this.adminSessionId, this.userName, this.myFile))
        {
            this.myVersionedFile.createVersion(VersionedFile.BACKUP_RENAMED);
            return this.myVersionedFile.getCurrentVersion().renameTo(newPath);
        }
        else
            throw new FileAccessDenied("Rename access denied to user: "+this.userName+" for file: "+this.myFile.getAbsolutePath());
    }
=end
end
