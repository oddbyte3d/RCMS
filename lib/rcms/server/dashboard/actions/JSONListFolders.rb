require_relative '../../file/FileCMS'
require_relative '../../GlobalSettings'
require_relative '../../security/AdminAccessControler'


class JSONListFolders

  def initialize(session, sub_dir)
    @sub_dir = sub_dir
    @session = session
    @FS = File::SEPARATOR
    @ACCESS_CONTROLER = AdminAccessControler.new
    @userName = GlobalSettings.getUserLoggedIn(@session)
  end

  def listFiles

    cWorkArea = GlobalSettings.getCurrentWorkArea(@session)
    myPage = nil
    cWorkArea = GlobalSettings.changeFilePathToMatchSystem(cWorkArea+@sub_dir)
    Dir.chdir(cWorkArea)

    filtered = Dir.glob('*').select {|f| File.directory? f}
    #puts "All Folders: #{filtered}"
    json = "{\"files\": {"
    accessable = Array.new
    filtered.each{ |file|
      begin

        myPage = FileCMS.new(@session, "#{cWorkArea}#{@FS}#{file}")
        #puts "----------:: #{myPage.getFileURL} "
        if @ACCESS_CONTROLER.checkDirectoryAccessRead(@session.sessionId, @userName, myPage.getFileURL)
          #page = Page.new(myPage, -1, @session, myPage.getFileURL)
          accessable << myPage
        end

      rescue
        puts "Not allowed to access: #{file}"
      end

    }
    at = 0
    accessable.each{ |nfile|
      at = at.next
      json.concat("\"#{nfile.getFileURL}\": \"#{nfile.getFileName}\"")
      json.concat(",") if at < accessable.size
    }

    json.concat("}}")
    return json


  end


end
