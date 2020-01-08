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
require "rcms/server/security/AdminSession"
#require "rcms/server/file/FileCMS"
require 'rcms/server/net/HttpSession'
require "rcms/PageModule"
require "rcms/Page"
require "rcms/server/file/MimeTypes"
require "require_all"
#require "encrypted_strings"

require_all 'lib/rcms/server/renderers/'
require_all 'lib/rcms/server/dashboard/actions/'
require 'sinatra'
enable :sessions

set :bind, '0.0.0.0'
set :port, 9999

post '/login' do

    out = "{\"status\": \"error\", \"message\": \"Login failed\"}"
    sessionId = nil
    if session["sessionId"] == nil
      sessionId = AdminSession.createSessionID
      my_session = HttpSession.new(sessionId)
      session["sessionId"] = sessionId
      GlobalSettings.trackSession(my_session)
    else
      sessionId = session["sessionId"]
      my_session = GlobalSettings.getSession(sessionId)
    end


    #Apparently Sinatra doesnt process form parameters if JSON properly
    #So the following hack is required....
    form_params = JSON.parse(params["request"])

    password = form_params["record"]["user_pass"]
    user_name = form_params["record"]["user_name"]
    #puts "Password: #{encrypted_password}"

    #accessControl = AccessControler.new
    if GlobalSettings.loginUser(my_session, user_name, password)
      #puts "User Logged In... #{user_name} sessionId: #{sessionId}"
      out = "{\"status\": \"success\"}"
    end

    status  = 200
    headers \
      "Content-Type" => MimeTypes.getFileMimeType("index.json")
    body    = [out]

    return [status, headers, body]

end

post '/admin/actions/:action' do

  status = 200
  #form_params = JSON.parse(params)
  #puts "POST Parameters: #{params["file_contents"]}"
  out = ""
  sessionId = session["sessionId"]
  my_session = GlobalSettings.getSession(sessionId)
  userName = GlobalSettings.getUserLoggedIn(my_session)
  parentProperyFile = GlobalSettings.getGlobal("Parent-PropertyFile")
  propertyLoader = PropertyLoader.new(parentProperyFile)

  if userName != "guest"
    #puts "Form parameters: #{form_params}"

    case params["action"]
    when "save_xml"
      begin
        #saver = AdminSaveXML.new(my_session, RCMSUser.new(userName), params["file"], params["file_contents"])
        puts params["file_contents"]
        #out = saver.doSave
        jsonRenderer = JSON_XMLRenderer.new
        out = jsonRenderer.renderOutput(params, response, my_session, propertyLoader, params["file"], "json_to_xml")
        #puts "Out:::::::::: #{out}"
      rescue FileAccessDenied => fae
        #status = 403
        out  = "{\"error\": \"#{fae.message}\"}"
      rescue FileNotFound => fne
        out  = "{\"error\": \"#{fne.message}\"}"
      end
    end
  else
    status  = 403
  end
  # Need to modify the following to support other things....

  headers \
    "Content-Type" => MimeTypes.getFileMimeType("index.json")
  body    = [out]

  return [status, headers, body]
end

get '/system/admin/:admin_file' do
  #{}"Admin Area...#{params["admin_file"]}"
  doAllGet
end

get '/admin/actions/:action' do
  #"Admin Action: #{params["action"]}"
  out = ""
  sessionId = session["sessionId"]
  my_session = GlobalSettings.getSession(sessionId)
  #adminSessionId = AdminSession.createSessionID
  #AdminSession.addNewSession(sessionId)

  sub_dir = "/"
  sub_dir = params["sub_dir"] if params["sub_dir"] != nil
  file_type = "xml"
  file_type = params["file_type"] if params["file_type"] != nil
  case params["action"]
  when "list_files"
    #puts "About to load from: #{sub_dir} #{file_type}"
    out = JSONListFiles.new(my_session, sub_dir, file_type).listFiles
  when "list_folders"
    out = JSONListFolders.new(my_session, sub_dir).listFiles
  when "save_xml"
    file_contents = params["file_contents"]
    puts "Save XML: #{params["file"]}  :::: #{file_contents}"
  end

  # Need to modify the following to support other things....
  status  = 200
  headers \
    "Content-Type" => MimeTypes.getFileMimeType("index.json")
  body    = [out]

  return [status, headers, body]



end

get '/*.woff' do
  doAllGet
end

get '/*.woff2' do
  doAllGet
end

get '/*.css' do
  doAllGet
end

get '/*.gif' do
  doAllGet
end

get '/*.ttf' do
  doAllGet
end

get '/*.jpg' do
  doAllGet
end

get '/*.png' do
  doAllGet
end

get '/*.js' do
  doAllGet
end

get '/*.json' do
  doAllGet
end

get '/*.admin' do
  # Make sure user is logged in and is also an admin
  if session["sessionId"] != nil && AdminSession.getSessionHash(session["sessionId"]) != nil
    doAllGet
  else
    redirect GlobalSettings.getGlobal("LoginPage")
  end
end
get '/*.xml' do
  doAllGet
end

def doAllGet
  #puts "===============================\nRequest Parameters: #{params}\n*****************************************"

  path = env['PATH_INFO']
  sessionId = ""
  my_session = nil
  if session["sessionId"] == nil
    sessionId = AdminSession.createSessionID
    my_session = HttpSession.new(sessionId)
    session["sessionId"] = sessionId
    GlobalSettings.trackSession(my_session)
    #puts "++++++++++++++++++++++++++++++++++++++\nCreating new session\n+++++++++++++++++++++++++++++++++++++++"
  else
    sessionId = session["sessionId"]
    my_session = GlobalSettings.getSession(sessionId)
    #puts "++++++++++++++++++++++++++++++++++++++\nRetrieved session: #{my_session}\n+++++++++++++++++++++++++++++++++++++++"
  end


  #session["loggedIn"] = true
  #session["loginName"] = "scott"
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
  theme = params["theme"] if params.key?("theme")
  availableThemes = properties.getProperties("TemplateDirectory")
  #puts "---------------------------------------\n\nAvailable Themes: #{availableThemes}\n\n----------------------------------------------"
  if(availableThemes.key?(fileEnding) != nil)
    theme = availableThemes[fileEnding]
  end
  begin
    render.setAdditionalParameters(params)
    out = render.render( params, Hash.new, my_session, properties, path, theme, baseDocRoot,
                    baseDocRootInc, false)
  rescue FileAccessDenied => e  #Catch any AccessDenied errors
    redirect GlobalSettings.getGlobal("LoginPage")
    #out = e.message
  rescue FileNotFound => e
    #notFoundPath = GlobalSettings.getGlobal("FileNotFound")

    redirect GlobalSettings.getGlobal("FileNotFound")+fileEnding+"?FileNotFound=#{e.message}"
  end
  status  = 200
  headers \
    "Content-Type" => MimeTypes.getFileMimeType(mimeTypePath),
    "Access-Control-Allow-Origin" => "*"
  #puts "Headers: #{headers}"

  body    = [out]

  return [status, headers, body]


end
