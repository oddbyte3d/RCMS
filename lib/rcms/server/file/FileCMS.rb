$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), './' ) )
require 'exception/FileAccessDenied'
require 'exception/FileNotFound'
require 'rcms/server/net/HttpSession'
require 'rcms/server/security/AccessControler'
require 'rcms/server/file/versioning/VersionedFile'
require 'rcms/server/file/versioning/FileVersion'
require 'rcms/server/file/versioning/FileVersionInfo'
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
      @ACCESS_CONTROL = AccessControler.new
      @ADMIN_ACCESS_CONTROL = AdminAccessControler.new
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
        adminSessionHash = AdminSession.getSessionHash(@SESSION.sessionId)
        if adminSessionHash != nil
          @ADMIN_SESSION_ID = adminSessionHash["sessionId"]
        else
          @ADMIN_SESSION_ID = nil
        end
        currentArea = GlobalSettings.getCurrentWorkArea(@SESSION)
        #puts "Workarea = #{currentArea}"
        if path.index(File.absolute_path(GlobalSettings.getDocumentDataDirectory())) == nil &&
                path.index(File.absolute_path(GlobalSettings.getDocumentConfigDirectory())) == nil &&
                path.index(File.absolute_path(GlobalSettings.getDocumentWorkAreaDirectory())) == nil
            path = "#{currentArea}#{path}"
            #puts "FileCMS 62 path=#{path}"
        end
        @FILE = path
        @FILE = GlobalSettings.changeFilePathToMatchSystem(@FILE)
        #puts "FileCMS 65 path=#{@FILE}"
        @USER_NAME = GlobalSettings.getUserLoggedIn(@SESSION)
        #puts "User 2 : #{@USER_NAME}"

        #Firstly check if we are dealing with an admin user, if the user can not access the file from a web session then throw an exception
        if @ADMIN_SESSION_ID != nil && !@ADMIN_ACCESS_CONTROL.checkFileAccessRead(@ADMIN_SESSION_ID, @USER_NAME, @FILE)
          raise FileAccessDenied.new("Read access denied to user: #{@USER_NAME} for file: #{getFileURL}")
        elsif @ADMIN_SESSION_ID == nil && !@ACCESS_CONTROL.checkUserFileAccess(@USER_NAME, File.absolute_path(@FILE))
          raise FileAccessDenied.new("Read access denied to user: #{@USER_NAME} for file: #{getFileURL}")
        end


        @VERSIONED_FILE = VersionedFile.new(@USER_NAME, @SESSION, @FILE)
        #TO-DO: create versioned file system and then implement the Following
        if (!File.exist?(@FILE) && @VERSIONED_FILE.getAllVersions() != nil)
          #puts "File does not exist..."
          raise FileNotFound.new("File #{getFileURL} not found...")
            #FileVersion vers[] = myVersionedFile.getAllVersions();
        else

            if !File.exist?(@FILE) && !create
                raise FileNotFound.new("File: #{getFileURL} does not exist!")
            elsif !File.exist?(@FILE)
                file = File.new(@FILE,  "w")
                file.close
            end
        end
    end

    def init_3_user(userName, sessionId, path)
        init_4(userName, sessionId, path, false)
    end


    def init_4(userName, sessionId, path, create)

        @USER_NAME = userName
        @ADMIN_SESSION_ID = sessionId
        @SESSION = GlobalSettings.getSession(sessionId)
        currentArea = GlobalSettings.getCurrentWorkArea(@SESSION)
        if path.index(File.absolute_path(GlobalSettings.getDocumentDataDirectory())) == nil &&
                path.index(File.absolute_path(GlobalSettings.getDocumentConfigDirectory())) == nil &&
                path.index(File.absolute_path(GlobalSettings.getDocumentWorkAreaDirectory())) == nil
            path = "#{currentArea}#{path}"
            #puts "FileCMS 109 path=#{path}"
        end
        @FILE = path
        @FILE = GlobalSettings.changeFilePathToMatchSystem(@FILE)
        #puts "FileCMS 113 path=#{@FILE}"
        #If the user has no read permissions to this file then just throw an exception and do not provide the opportunity for access.
        if !@ADMIN_ACCESS_CONTROL.checkFileAccessRead(@ADMIN_SESSION_ID, @USER_NAME, @FILE)
          raise FileAccessDenied.new("Read access denied to user: #{@USER_NAME} for file: #{getFileURL}")
        end

        @VERSIONED_FILE = VersionedFile.new(@USER_NAME, @SESSION, @FILE)

        if (!File.exist?(@FILE) && @VERSIONED_FILE.getAllVersions() != nil)
          #puts "File does not exist..."
          raise FileNotFound.new("File #{getFileURL} not found...")
        else

          if (!File.exist?(@FILE) && !create)
              raise FileNotFound.new("File: #{getFileURL} does not exist!")
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

    def getFileExtension

        if File.file?(@FILE)
            return File.extname(@FILE)
        else
            return "folder"
        end
    end

    def getFileName
      return File.basename(@FILE)
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

        if @SESSION != nil && @ADMIN_SESSION_ID == nil
            if(@ACCESS_CONTROL.checkUserFileAccess(@USER_NAME, File.absolute_path(@FILE)))
              return File.open(@FILE)
            else
                raise FileAccessDenied.new("Read access denied to user: #{@USER_NAME} for file: #{getFileURL}")
            end
        elsif @ADMIN_SESSION_ID != nil

            if(@ADMIN_ACCESS_CONTROL.checkFileAccessRead(@ADMIN_SESSION_ID, @USER_NAME, @FILE))
                return File.open(@FILE)
            else
                raise FileAccessDenied.new("Read access denied to user: #{@USER_NAME} for file: #{getFileURL}")
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
      #if @SESSION != nil
      #    if(@ADMIN_ACCESS_CONTROL.checkFileAccessWrite(@SESSION.sessionId, @USER_NAME, File.absolute_path(@FILE)))
      #      return open(@FILE)
      #    else
      #        raise FileAccessDenied.new("Write access denied to user: #{@USER_NAME} for file: #{File.absolute_path(@FILE)}")
      #    end
      #elsif @ADMIN_SESSION_ID != nil
      if @ADMIN_SESSION_ID != nil

          if(@ADMIN_ACCESS_CONTROL.checkFileAccessWrite(@ADMIN_SESSION_ID, @USER_NAME, @FILE))
            #puts "Opening to write!!!"
            @VERSIONED_FILE.createVersion(@VERSIONED_FILE.BACKUP_MODIFIED)
            return File.open(@FILE, "w+")
          else
              raise FileAccessDenied.new("Write access denied to user: #{@USER_NAME} for file: #{getFileURL}")
          end
      end
      return nil
    end

    def publishFile
        #System.out.println("Inside FileCMS.publishFile() publish to:"+GlobalSettings.getDocumentDataDirectory().getAbsolutePath()+this.getFileURL());
        puts "\n\n publish 0"
        if(@ADMIN_ACCESS_CONTROL.checkFileAccessPublish(@ADMIN_SESSION_ID, @USER_NAME, @FILE))
            puts "\n\n-------------------\npublish 1"
            if(File.exists?(@FILE))
              puts "publish 2"
              FileUtils.cp_r(@FILE, "#{File.absolute_path(GlobalSettings.getDocumentDataDirectory())}#{getFileURL()}")
              puts "publish 3\n-------------------------"
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
        if(@ADMIN_ACCESS_CONTROL.checkFileAccessPublish(@ADMIN_SESSION_ID, @USER_NAME, @FILE))
            puts " #{version.class.name} == -1 : #{version == -1}"
            if(version == -1)
                return publishFile
            else
              if(!File.exist?(@FILE))   #This case, is when we are to publish a deleted file or better said unpublishing a file
                  return (File.new(GlobalSettings.getDocumentDataDirectory().getAbsolutePath()+this.getFileURL())).delete();
              end
              versions = @VERSIONED_FILE.getAllVersions()
              versions.each { |n_version|
                  #puts ":::: #{n_version.versionNumber} :::: #{version}"
                  if(n_version.versionNumber == version)
                    if(n_version.VTYPE != n_version.TYPE_DELETED)
                        #puts "::::::::::::::::::: cp_r #{n_version.thisVersion} -> #{GlobalSettings.getDocumentDataDirectory+getFileURL}"
                        return FileUtils.cp_r(n_version.thisVersion, GlobalSettings.getDocumentDataDirectory+getFileURL)
                    else
                      return true
                    end
                  end
              }
            end
        end
        return false
    end


    #Enables safe deleting of a file. Checks permissions and makes a backup of the latest version.
    def delete

        if(@ADMIN_SESSION_ID == nil)
            raise FileAccessDenied.new("File Access Denied!")
        end
        if @ADMIN_ACCESS_CONTROL.checkFileAccessWrite(@ADMIN_SESSION_ID, @USER_NAME, @FILE)

            @VERSIONED_FILE.createVersion(@VERSIONED_FILE.BACKUP_DELETED)
            deleted = File.delete(@VERSIONED_FILE.getCurrentVersion)
            return (deleted > 0)
        else
            raise FileAccessDenied.new("Delete access denied to user: #{@USER_NAME} for file: #{@FILE}")
        end
    end

    #Enables safe renaming of a file. Checks permissions and makes a backup of the latest version.
    def renameFile(newPath)
        if(@ADMIN_SESSION_ID == nil)
            raise FileAccessDenied.new("File Access Denied!")
        end
        if(@ADMIN_ACCESS_CONTROL.checkFileAccessWrite(@ADMIN_SESSION_ID, @USER_NAME, @FILE))
            @VERSIONED_FILE.createVersion(@VERSIONED_FILE.BACKUP_RENAMED)
            return File.rename(@VERSIONED_FILE.getCurrentVersion, newPath)
        else
            raise FileAccessDenied.new("Rename access denied to user: #{@USER_NAME} for file: #{getFileURL}")
        end
    end

end
