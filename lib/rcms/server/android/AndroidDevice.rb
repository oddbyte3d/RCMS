require "fcm"
require "json"
require_relative "../GlobalSettings"
require_relative "../../object_repository/ObjectRepository"
require_relative "../../object_repository/RepositoryObject"
require_relative "./Device"
require_relative "./Subscription"

class AndroidDevice

  def initialize(params)
    @subscriptionLists = GlobalSettings.getLoadedRepository("DeviceIDs.obj")
    if(params.key?("session"))
      @session = params['session']
    end

    if params.key?('device_id') && params.key?('action') && params.key?('user')
      device_id = params['device_id']
      action = params['action']
      user = params['user']
      #device = AndroidDevice.new
      @out = register(user, device_id) if action == "register"

      if action == "subscribe" && params["subscribe"] != nil
        subscription = params["subscribe"]
        @out = subscribe(user, device_id, subscription)
      elsif action == "subscribe" && params["subscribe"] == nil
        @out = '{"error": "required parameters missing"}'
      elsif action == "unsubscribe" && params["unsubscribe"] != nil
        subscription = params["unsubscribe"]
        @out = unsubscribe(user, device_id, subscription)
      elsif action == "unsubscribe" && params["unsubscribe"] == nil
        @out = '{"error": "required parameters missing"}'
      elsif action == "check_ss" && params["list"] != nil
        subscription = params["list"]
        @out = check_subscription(user, device_id, subscription)
        puts "\n\n-------------------------------------------\n#{@out}\n--------------------------------------------\n\n"
      elsif action == "check_ss" && params["list"] == nil
        @out = '{"error": "required parameters missing"}'
      end

    elsif params['action'] == "subscriptions"
      subscriptions = getAllSubscriptions
      #puts "\n\n++++++++++++++++++++\n#{subscriptions}"
      @out = "{ \"subscriptions\": {"
      if subscriptions != nil
        scount = subscriptions.size
        sat = 0
        subscriptions.keys.each{ |subsr|
          sat = sat.next
          @out.concat "\"#{subsr}\": ["
          at = 0
          count = subscriptions[subsr].deviceCount
          puts "Subscription count:  #{count}"
          subscriptions[subsr].devices.keys.each{ |nsub|
            at = at.next
            #puts "#{nsub}"
            @out.concat "\"#{subscriptions[subsr].devices[nsub].userName}|#{subscriptions[subsr].devices[nsub].deviceId}\""
            @out.concat "," if at < count
          }
          @out.concat "]"
          @out.concat "," if sat < scount
        }
      end
      @out.concat "}}"
      #puts "Returning :::::::::::::::::::::::::::::::::   #{@out}"
    elsif params['action'] == "add_subscription"
      addSubscription( params["ssname"] )
      @out = '{"success": "subscription queue added"}'
    elsif params['action'] == "del_subscription"
      deleteSubscription( params["ssname"] )
      @out = '{"success": "subscription queue deleted"}'
    elsif params['action'] == "push_notification"
      devicesReached = sendPushnotification( params["topic"], params["file"] )
      @out = '{"success": "'+devicesReached.to_s+' subscribed users have been reached."}'
    else
      @out = '{"error": "required parameters missing"}'
    end

  end

  #------Get results from whatever action we are doing------------------------
  def getResult
    return @out
  end

  #------Register a device---------------------------------------------------
  def register(user, device_id )

    if !@subscriptionLists.hasKey device_id
      device = Device.new(user, device_id)

      @subscriptionLists.commitObject(device_id, device, false)
      return '{"register": "success"}'
    else
      return '{"register": "device already registered"}'
    end
  end

  #------Unsubscribe a device from a queue------------------------------------------
  def unsubscribe(device_id, subscription)
    #puts "\n\n------------------------------\nUnsubscribe from: #{subscription}\n--------------------------------------"
    if @subscriptionLists.hasKey device_id
      device = @subscriptionLists.getRepositoryObject(device_id).getObject
      device.removeSubscription(subscription)
      @subscriptionLists.commitObject(device_id, device, false)
    end
    if @subscriptionLists.hasKey("subscriptions")
      subscriptions = @subscriptionLists.getRepositoryObject("subscriptions").getObject
      if(subscriptions.key? subscription)
        subs = subscriptions[subscription]
        subs.removeDevice(device_id)
        @subscriptionLists.commitObject("subscriptions", subscriptions, false)
        return "{\"unsubscribe\": \"Device unsubscribed from #{subscription}\"}"
      end
    else
      return '{"unsubscribe": "No subscriptions available"}'
    end
  end

  #------Create a new subscription queue------------------------------------------
  def addSubscription(subscr)
    subscriptions = Hash.new
    if @subscriptionLists.hasKey("subscriptions")
      subscriptions = @subscriptionLists.getRepositoryObject("subscriptions").getObject
    end
    subscriptions[subscr] = Subscription.new(subscr)
    @subscriptionLists.commitObject("subscriptions", subscriptions, false)
  end

  def getSubscription(subname)
    if @subscriptionLists.hasKey("subscriptions")
      subscriptions = @subscriptionLists.getRepositoryObject("subscriptions").getObject
      return subscriptions[subname] if subscriptions.key?(subname)
    end
  end

  #------Delete a subscription queue------------------------------------------
  def deleteSubscription(subscr)
    subscriptions = Hash.new
    if @subscriptionLists.hasKey("subscriptions")
      subscriptions = @subscriptionLists.getRepositoryObject("subscriptions").getObject
    end
    #subscriptions[subscr] = Array.new
    #@subscriptionLists.commitObject("subscriptions", subscriptions, false)
    subscriptions.delete(subscr)
    @subscriptionLists.commitObject("subscriptions", subscriptions, false)
  end

  #------Return all subscription queues------------------------------------------
  def getAllSubscriptions
      if @subscriptionLists.hasKey("subscriptions")
        return @subscriptionLists.getRepositoryObject("subscriptions").getObject
      end
  end

  #------Subscribe a device to a subscription queue------------------------------------------
  def subscribe(user, device_id, subscription)
    if @subscriptionLists.hasKey device_id
      device = @subscriptionLists.getRepositoryObject(device_id).getObject
      subscriptions = Hash.new
      subscriptions = @subscriptionLists.getRepositoryObject("subscriptions").getObject if @subscriptionLists.hasKey("subscriptions")

      #puts "\n\n_____________________Sub Queues_______________________\n#{subscriptions}\n\nLooking for #{subscription}\n__________________________________"

      if subscriptions.key? subscription
        sub = subscriptions[subscription]
        #sub.addDevice(device_id)
        if(sub != nil && sub.hasDevice?(device_id))  # Device Already subscribed so let the user know
          return "{\"subscribe\": \"Device already subscribed to #{subscription}\"}"
        else #Lets subscribe the user(only implemented locally, not on the firebase server)
          device.addSubscription(sub)
          sub.addDevice(device)
          @subscriptionLists.commitObject("subscriptions", subscriptions, false) #List of all subscription lists with device ids
          @subscriptionLists.commitObject(device_id, device, false) #We also keep a list of subscriptions with the particular device id... do we need this??

          return "{\"subscribe\": \"Device subscribed to #{subscription}\"}"
        end
      else
        return '{"subscribe": "Subscription queue('+subscription+') does not exist."}'
      end
    else
      return '{"subscribe": "Device not registered"}'
    end
  end

  #------Check if a device is subscribed to a queue------------------------------------------
  def check_subscription(user, device_id, sub)
    if @subscriptionLists.hasKey device_id
      device = @subscriptionLists.getRepositoryObject(device_id).getObject
      return "{\"subscribed\": \"#{device.hasSubscription?(sub)}\"}"
    else
      return "{\"subscribed\": \"false\"}"
    end
  end

  def sendPushnotification(topic, file)

    fcm = FCM.new(GlobalSettings.getGlobal("FirebaseServerKey"))
    ret = loadFCMMessage(file)
    devList = getSubscription(topic).deviceList
    response = fcm.send(devList, JSON.parse(ret))
    return devList.size
  end



  def loadFCMMessage(path)

    #path = env['PATH_INFO']
    #puts "++++++++++++++++++++++++++++++++++++++\n#{path}\n+++++++++++++++++++++++++++++++++++++++"
    params = Hash.new
    sessionId = ""
    my_session = nil
    if @session["sessionId"] == nil
      sessionId = AdminSession.createSessionID
      my_session = HttpSession.new(sessionId)
      @session["sessionId"] = sessionId
      #puts "++++++++++++++++++++++++++++++++++++++\nCreating new session\n+++++++++++++++++++++++++++++++++++++++"
    else
      sessionId = @session["sessionId"]
      my_session = GlobalSettings.getSession(sessionId)
      #puts "++++++++++++++++++++++++++++++++++++++\nRetrieved session: #{my_session}\n+++++++++++++++++++++++++++++++++++++++"
    end
    my_session["current_path"] = path

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
    #theme = params["theme"] if params.key?("theme")
    availableThemes = properties.getProperties("TemplateDirectory")
    #puts "---------------------------------------\n\nAvailable Themes: #{availableThemes}\n\n----------------------------------------------"
    if(availableThemes.key?(fileEnding) != nil)
      theme = availableThemes[fileEnding]
    end
    begin
      params["requested_path"] = path
      render.setAdditionalParameters(params)
      #puts "Before render... #{render.class.name}"
      out = render.render( params, Hash.new, my_session, properties, path, theme, baseDocRoot,
                      baseDocRootInc, false)

      #puts "After Render: #{out}"
    rescue FileAccessDenied => e  #Catch any AccessDenied errors
      #redirect GlobalSettings.getGlobal("LoginPage")
      out = e.message
    rescue FileNotFound => e
      #notFoundPath = GlobalSettings.getGlobal("FileNotFound")
      out = e.message
      #redirect GlobalSettings.getGlobal("FileNotFound")+"?FileNotFound=#{e.message}"
    end
    return out

  end



end
