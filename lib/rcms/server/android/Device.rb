class Device

  attr_accessor :userName, :deviceId, :subscriptions

  def initialize(username, device_id)
    @userName = username
    @deviceId = device_id
    @subscriptions = Hash.new
  end

  def hasSubscription?(sub)
    return @subscriptions.key? sub
  end

  def addSubscription(sub)
    @subscriptions[sub.subName] = sub
  end

  def removeSubscription(subName)
    if @subscriptions.key? subName
      sub = @subscriptions[subName]
      sub.removeDevice(@deviceId)
      @subscriptions.delete(subName)
    end
  end

end
