$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), './lib/' ) )

require 'rcms/server/file/FileCMS'
require 'rcms/server/GlobalSettings'
require 'rcms/server/security/AdminAccessControler'
require 'rcms/server/net/HttpSession'
require 'rcms/server/security/AdminSession'
require 'rcms/server/workflow/Task'
require 'rcms/server/workflow/FileAction'
require 'rcms/server/user/RCMSUser'
require 'rcms/server/file/FileCMS'
require 'rcms/server/GlobalSettings'

require 'rcms/server/renderers/JSON_XMLRenderer'
require 'rcms/server/template/JSONTemplate'
require 'rcms/server/template/JSONTemplateFile'
require 'rcms/util/PropertyLoader'
require 'rcms/PageMenu'
require 'rcms/MenuItem'

require "date"

fs = File::SEPARATOR
sessionId = AdminSession.createSessionID
my_session = HttpSession.new(HttpSession.generate_code(6))

#----------------------------------------------------------------------------------------------------
parentProperyFile = GlobalSettings.getGlobal("Parent-PropertyFile")
propertyLoader = PropertyLoader.new(parentProperyFile)
#jsonRenderer = JSON_XMLRenderer.new
#request = Hash.new
#request["file_contents"] = {"time":1577945273564,"blocks":[{"type":"header","data":{"text":"Test title","level":1}},{"type":"paragraph","data":{"text":"Congratulations, your RCMS instance is working!"}},{"type":"list","data":{"style":"unordered","items":["Cool Element 1","Element 2","Element 3"]}}],"version":"2.16.1"}


#"{\"time\":1577945273564,\"blocks\":[{\"type\":\"header\",\"data\":{\"text\":\"Test title\",\"level\":1}},{\"type\":\"paragraph\",\"data\":{\"text\":\"Congratulations, your RCMS instance is working!\"}},{\"type\":\"list\",\"data\":{\"style\":\"unordered\",\"items\":[\"Cool Element 1\",\"Element 2\",\"Element 3\"]}}],\"version\":\"2.16.1\"}"

#out = jsonRenderer.renderOutput(request, {}, my_session, propertyLoader, "/test.xml", "json_to_xml")
#puts out
#----------------------------------------------------------------------------------------------------

userName = "scott"
my_session["loginName"] = userName
GlobalSettings.setAdminSessionId(my_session, sessionId)
cWorkArea = GlobalSettings.getCurrentWorkArea(my_session)
cWorkArea = GlobalSettings.changeFilePathToMatchSystem(cWorkArea)
myPage = FileCMS.new(my_session, "#{cWorkArea}#{fs}menu.xml")
#puts AdminAccessControler.new.checkFileAccessPublish(sessionId, userName, myPage.FILE)


#cr.setRequest(Hash.new)
#cr.setSession(my_session)
#puts cr.getValue(@myTemplateDir, @myPageToRender, @myTemplate, key, @configProperties))

menu = PageMenu.new("#{cWorkArea}#{fs}coachcast.xml", true)

puts menu.compileMenu


#user = RCMSUser.new("scott")
#file = FileCMS.new(my_session, "Comment.java")
#fileAction = FileAction.new(file, FileAction.ACTION_EDIT)
#fActions = [fileAction]
#task = Task.new(user, Date.today, "test", "Task Description", fActions, true, false, -1, false, false, "scott")
#task.assignUser(user)
#task.setStatus(task.STATUS_NEW)
