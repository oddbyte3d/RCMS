require_relative '../../file/FileCMS'
require_relative '../../GlobalSettings'
require_relative '../../security/AdminAccessControler'


class JSONListFiles

  def initialize(session, sub_dir, file_type)
    @file_type = file_type
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
    filtered = Dir.glob("*.#{@file_type}")
    json = "{\"files\": {"
    accessable = Array.new
    filtered.each{ |file|
      begin

        myPage = FileCMS.new(@session, "#{cWorkArea}#{@FS}#{file}")
        if @ACCESS_CONTROLER.checkFileAccessRead(@session.sessionId, @userName, myPage.FILE)
          #page = Page.new(myPage, -1, @session, myPage.getFileURL)
          #puts "Can access : #{myPage.getFileURL}"
          accessable << myPage
        end

      rescue
        puts "Not allowed to access: #{file}"
      end

    }
    at = 0
    accessable.each{ |nfile|
      at = at.next

      nurl = nfile.getFileURL
      title = nfile.getFileName
      if nurl.end_with?(".xml")
        nurl = nurl[0..nurl.rindex(".xml")]+"admin"
        title = Page.new(nfile, -1, @session, nfile.getFileURL).title
      end

      json.concat("\"#{nurl}\": \"#{nfile.getFileName}(#{title})\"")
      json.concat(",") if at < accessable.size
    }

    json.concat("}}")
    #puts "Returning : #{json}"
    return json


  end


end
