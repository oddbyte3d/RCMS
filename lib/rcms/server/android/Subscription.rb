class Subscription

  attr_accessor :subName, :devices

  def initialize(name)
    @subName = name
    @devices = Hash.new
  end

  def hasDevice?(device_id)
    return @devices.key? device_id
  end

  def deviceList
    return @devices.keys
  end

  def addDevice(device)
    @devices[device.deviceId] = device
  end

  def removeDevice(device_id)
    @devices.delete(device_id) if @devices.key? device_id
  end

  def deviceCount
    return @devices.size
  end

end
