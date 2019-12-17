require "yaml"
require_relative "../GlobalSettings"

class MimeTypes

    def initialize
    end


    def self.getFileMimeType(fileName)

      @@MIMES = YAML.load_file(GlobalSettings.getGlobal("Server-ConfigPath")+GlobalSettings.getGlobal("mimetypes"))
      if @@MIMES != nil
          extension = ""

          #In case we have a File passed as the argument then replace it with its path
          if fileName.instance_of? File
            fileName = fileName.path
          end
          if fileName.index('.') != nil
              extension = fileName[fileName.rindex(".")+1..fileName.size].downcase
          else
              return "application/octet-stream"
          end
          if(@@MIMES.key?(extension))
              puts "Returning for Extension:#{extension} Mime type:#{@@MIMES[extension]}"
              return @@MIMES[extension]
          else

              puts "Mime type does not include #{extension}"
              return "application/octet-stream"
          end
      else
          return "application/octet-stream";
      end

    end

    def self.getFileType(f)
        fileName = File.path.downcase
        extension = ""
        if fileName.index('.') != nil
            extension = fileName[fileName.rindex(".")+1..fileName.size].downcase
            return extension
        else
            puts "No . in filename"
            return nil
        end

    end
end
