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
require "fcm"


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
#myPage = FileCMS.new(my_session, "#{cWorkArea}#{fs}menu.xml")
#puts AdminAccessControler.new.checkFileAccessPublish(sessionId, userName, myPage.FILE)


#cr.setRequest(Hash.new)
#cr.setSession(my_session)
#puts cr.getValue(@myTemplateDir, @myPageToRender, @myTemplate, key, @configProperties))

#menu = PageMenu.new("#{cWorkArea}#{fs}coachcast.xml", true)

#puts menu.compileMenu


#user = RCMSUser.new("scott")
#file = FileCMS.new(my_session, "Comment.java")
#fileAction = FileAction.new(file, FileAction.ACTION_EDIT)
#fActions = [fileAction]
#task = Task.new(user, Date.today, "test", "Task Description", fActions, true, false, -1, false, false, "scott")
#task.assignUser(user)
#task.setStatus(task.STATUS_NEW)


fcm = FCM.new(GlobalSettings.getGlobal("FirebaseServerKey"))
# you can set option parameters in here
#  - all options are pass to HTTParty method arguments
#  - ref: https://github.com/jnunemaker/httparty/blob/master/lib/httparty.rb#L29-L60
#  fcm = FCM.new("my_server_key", timeout: 3)

#response = fcm.send_to_topic("news",
#            data: {title: "test title", message: "This is a FCM Topic Message!"})

options = {
            notification: { title: "Test notification", message: "Test FCM message" },
            data: {type: "banner", message: "This is a FCM Topic Message!",
            image_alt: "Alt image", image: "/images/daniel-j-schwarz-Qhnsv_Ey2mA-unsplash.jpg",
            banner_text: "Banner text this is actually working....", header_text: "Banner header text",
            header_title: "Header Title", items: [{"action":"/index.xml", "action_text":"Click Here"}]}
          }
response = fcm.send_to_topic('coachcast_news', options)

#response = fcm.send_with_notification_key("/topics/news",
#            data: {title: "test title", message: "This is a FCM Topic Message!"})

puts "Response: #{response}"
# See https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages for all available options.
#options = { "notification": {
#              "title": "Portugal vs. Denmark",
#              "body": "5 to 1"
#          }
#}
#response = fcm.send(registration_ids, options)
