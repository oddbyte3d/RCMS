$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), './lib/' ) )

#require 'rcms/server/file/FileCMS'
require "rcms/server/security/AccessControler"
require "rcms/server/security/AdminAccessControler"
require "rcms/object_repository/RepositoryObject"
require "rcms/object_repository/ObjectRepositoryTimer"
require "rcms/object_repository/ObjectRepository"
require "rcms/object_repository/RepositoryObject"
require "rcms/object_repository/ObjectRepositoryManager"
require "rcms/server/GlobalSettings"
require "rcms/server/file/MimeTypes"
require "rcms/server/file/versioning/VersionedFile"
require "rcms/xml/XMLDocumentHash"
require "rcms/xml/XMLDocument"
require "rcms/xml/XMLSmart"
#require "rcms/server/file/FileCMS"
require 'rcms/server/net/HttpSession'
require "rcms/PageModule"
require "rcms/Page"
require "rcms/server/file/MimeTypes"
require "require_all"

require_all 'lib/rcms/server/renderers/'


class Application

  def call(env)
    @REQUEST = env
    #puts "\n-------------REQUEST-----------------\n\n#{@REQUEST}\n\n---------------------------------------"
    handle_request(@REQUEST['REQUEST_METHOD'], @REQUEST['PATH_INFO'])
  end

  private

    def handle_request(method, path)
      if method == "GET"
        get(path)
      else
        method_not_allowed(method)
      end
    end

    def get(path)

      sessionId = AdminSession.createSessionID
      session = HttpSession.new(sessionId)
      session["loggedIn"] = true
      session["loginName"] = "scott"
      baseDocRoot = GlobalSettings.getGlobal("Base-DocRoot")
      baseDocRootInc = GlobalSettings.getGlobal("Base-DocRoot-Include")

      parentProperyFile = GlobalSettings.getGlobal("Parent-PropertyFile")
      properties = PropertyLoader.new(parentProperyFile)
      renderers = properties.getProperties("OutputRenderers")
      #puts "----------------------\nPath 1: #{path}\n---------------------------------------"
      if (path == nil || path.strip == ""|| path.strip == "/")
        path = "/index.xml"
      end
      #puts "----------------------\nPath 2: #{path}\n---------------------------------------"
      fileEnding = path[path.index(".")..path.size]
      out = ""
      #puts "File ending : #{fileEnding}"
      renderClass = renderers["default"]
      renderClass = renderers[fileEnding] if renderers.key?(fileEnding)

      #puts "Found Renderer : #{renderers[fileEnding]}"

      #html = XML_HTMLRenderer.new
      render = Kernel.const_get(renderClass).new
      mimeTypePath = path
      if(render.SOURCE_IS_XML && fileEnding != ".xml")
        path = path[0..path.index(".")-1]+".xml"
        #puts "-------------------------------------\nPath ended in #{fileEnding} but is now #{path}\n-----------------------------------------------"
      end

      #Need to determine the required theme
      theme = "default"
      availableThemes = properties.getProperties("TemplateDirectory")
      puts "---------------------------------------\n\nAvailable Themes: #{availableThemes}\n\n----------------------------------------------"
      if(availableThemes.key?(fileEnding) != nil)
        theme = availableThemes[fileEnding]

        puts "Using theme: #{theme}\n-----------------------------------------------"
      end
      out = render.renderOutput( Hash.new, Hash.new, session, properties, path, theme, baseDocRoot,
                        baseDocRootInc, false)

      status  = 200

      #Access-Control-Allow-Origin: * is probably a bad idea but it works for now....
      headers = { "Content-Type" => MimeTypes.getFileMimeType(mimeTypePath), "Access-Control-Allow-Origin" => "*" }
      #puts "Headers: #{headers}"

      body    = [out]

      [status, headers, body]
    end

    def method_not_allowed(method)
      [405, {}, ["Method not allowed: #{method}"]]
    end
end

run Application.new
