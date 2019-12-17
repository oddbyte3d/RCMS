
 # VersionedFile.rb
 #
 #
 # @author  scott ryan-taylor
 #
require "date"
require "fileutils"
require 'yaml'
require_relative './FileVersion'

class VersionedFile

  attr_accessor :USER_NAME, :VERSIONED_FILE
    #private FileVersion versions[] = new FileVersion[0];
    #private FileVersionInfo versionInfo[];
    #private static final String fs = System.getProperty("file.separator");


    # @param userName
    # @param session
    # @param vFile

    def initialize(userName, session, vFile)
        @USER_NAME = userName
        @SESSION = session
        @VERSIONED_FILE = vFile

        @WRITE_SUCCESS = 1
        @WRITE_OVERWRITTEN = 10
        @WRITE_BACKUP_DONE = 100
        @WRITE_BACKUP_FAILED = 1000
        @WRITE_FAILED = 10000
        @WRITE_NOT_OVERWRITTEN = 100000

        @BACKUP_MODIFIED = 0
        @BACKUP_ROLLBACK = 1
        @BACKUP_DELETED = 2
        @BACKUP_RENAMED = 3

        @FS = File::SEPARATOR

        @RANDOM_FILE_NAME =
        [
            'a','b','c','d','e','f','g','h','i','j','h','i','j','k','l',
            'm','n','o','p','q','r','s','t','u','v','w','x','y','z','A',
            'B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
            'Q','R','S','T','U','V','W','X','Y','Z','_','-','1','2','3','4',
            '5','6','7','8','9','0'
        ]

        self.listFileVersions()
    end

    # @param type
    # @return

    def createVersion(type)

        return self.createVersion(type, "auto-generated-version", "")
    end


    def getNextId

        highest = 0;
        for i in 0..versions.size

            if versions[i].getVersionNumber()>=highest
                highest = versions[i].getVersionNumber().next
            end
        end
        return highest
    end

    # => Creates a new File version of this versioned file: type can be one of
    # => BACKUP_MODIFIED/BACKUP_ROLLBACK/BACKUP_DELETED/BACKUP_RENAMED
    #
    # @param type
    # @param versionName
    # @param versionDescription
    # @return
    # @throws java.io.IOException

    def createVersion(type, versionName, versionDescription)
        return self.createVersion(type, versionName, versionDescription, false)
    end

    def createVersion(type, versionName, versionDescription, editable)

        versionId = getNextId()
        backup = File.absolute_path(@VERSIONED_FILE)
        backupDir  = backup[0.."#{backup.rindex(@FS)+1})BACKUP#{@FS}#{File.basename(@VERSIONED_FILE)}#{@FS}"]

        backup = backup[0.."#{backup.rindex(@FS)+1}BACKUP#{@FS}#{backup[backup.rindex(@FS)+1..backup.size]}"]
        #backup = FileUtils.changeFilePathToMatchSystem(backup);
        #backupDir = FileUtils.changeFilePathToMatchSystem(backupDir);

        if File.exist?(@VERSIONED_FILE)

            randomFileName = "#{@RANDOM_FILE_NAME.sample(12)}#{File.extname(@VERSIONED_FILE)}"

            #java.util.Date dNow = new java.util.Date();
            #backupDir = File.new(backupDir)
            if !File.exist?(backupDir)
                response = FileUtils.mkdir_p(backupDir)
            end
            myversions = backupDir+"files"
            if !File.exist?(myversions)
                FileUtils.mkdir_p(myversions)
            end
            backupType = "MODIFIED"
            case type
              when @BACKUP_DELETED
                backupType = "DELETED"
              when @BACKUP_RENAMED
                backupType = "RENAMED"
              when @BACKUP_ROLLBACK
                    backupType = "ROLLBACK"
              end

            #Do the backup of the file to a random file name
            backupFile = File.absolute_path("#{myversions}#{@FS}#{randomFileName}")
            if File.directory?(@VERSIONED_FILE)
                FileUtils.cp_r File.absolute_path(@VERSIONED_FILE), backupFile
            elsif File.file?(@VERSIONED_FILE)
                puts "\n\tCopy: #{@VERSIONED_FILE}\n\tTo: #{backupFile}\n"
                FileUtils.cp( @VERSIONED_FILE, backupFile )
            end

            #Create and save the version information for this version being created.
            newVersionInfo = backupDir+@FS+"v"+versionId+".rfs"
            versionProps = {"user" => @USER_NAME,
                            "date" => Date.today.jd,
                            "type" => backupType,
                            "file" => Backup.getName(),
                            "version" => versionId,
                            "versionName" => versionName,
                            "versionDescription" => versionDescription,
                            "editable" => editable}

            if type == @BACKUP_RENAMED
                versionProps["renamedto"] = "Put new file name here..."
            end
            File.write(newVersionInfo, versionProps.to_yaml)
        else
            raise IOException.new("Version creation failed; File does not exist: #{@VERSIONED_FILE}")
        end
        self.listFileVersions
        return versionId
    end

    def getCurrentVersion
        return @VERSIONED_FILE
    end

    def deleteVersion(toDelete)

            return toDelete.getThisVersion().delete()
    end


     # @param toRollBack
     # @return
     # @throws java.io.IOException

    def rollbackVersion(toRollBack)

        toRollBackFile = toRollBack.getThisVersion()
        #puts "File to rollback :#{File.basename(toRollBackFile)} Exists :#{File.exist?(toRollBackFile)}"
        versionId = this.getNextId() -1
        if myVersionedFile.exists()
            versionId = this.createVersion(@BACKUP_ROLLBACK)
        end
        if FileUtils.cp(toRollBackFile, @VERSIONED_FILE)#toRollBack.getCurrentVersion().getAbsolutePath()
            return versionId
        else
            raise IOException.new("Rollback of version #{toRollBack.getVersionNumber} for file #{toRollBack.getCurrentVersion} failed!")
        end
    end

    def getWebPath
        return GlobalSettings.getWebPath(@VERSIONED_FILE)
    end


    def getVersionCount()
        return @versions.size
    end

    def getVersionByNumber(versionNumber)

        for i in 0..@versions.size
            if(@versions[i].getVersionNumber() == versionNumber)
                return @versions[i]
            end
        end
        return nil
    end

    def getAllVersions
        return @versions
    end

    def getAllVersionInfo

        return @versionInfo
    end

    def getVersion(index)

      return @versions[index]
    end


    def listFileVersions

        if(@SESSION == nil || @VERSIONED_FILE == nil || File.absolute_path(@VERSIONED_FILE) == nil)
            return
        else
          versFile = File.absolute_path(@VERSIONED_FILE)

          dirPath = "#{versFile[0..versFile.rindex(@FS)]}BACKUP#{@FS}#{File.basename(@VERSIONED_FILE)}#{@FS}"

          #puts "VersionedFile: listFileVersions; #{dirPath} exists: #{File.exist?(dirPath)}"

          if(File.exist?(dirPath) && File.directory?(dirPath))

            Dir.chdir(dirPath)
            filtered = Dir.glob("*.properties") #TO-DO: need to sort this...
            @versions = Array.new
            @versionInfo = Array.new
            i = 0
            filtered.each {|fnext|
              #puts "Reading file version: #{i} : #{fnext}"
              @versions << FileVersion.new(
                      self,
                      @USER_NAME,
                      @SESSION,
                      fnext,
                      @VERSIONED_FILE)
              @versionInfo << @versions[i].getSerialisedVersion()
              i = i.next
            }

            #versions.sort_by{|c| File.stat(c).ctime}
            #versionInfo.sort_by{|c| File.stat(c).ctime}
          end
      end
    end

    def ==(o)
        #if(o instanceof File)
        #    return this.myVersionedFile.compareTo((File)o);
        #elsif(o instanceof VersionedFile)
        #    return this.myVersionedFile.compareTo(((VersionedFile)o).getCurrentVersion());
        #elsif(o instanceof FileVersion)
        #    return this.myVersionedFile.compareTo(((FileVersion)o).getThisVersion());
        #else
        #    return -1;
        return -1
    end



end
