class HttpSession < Hash

  attr_reader :sessionId

  def initialize(id)
    @sessionId = id
  end

  def getParameter(key)
    return self[key]
  end

  def setParameter(key, value)
    self[key] = value
  end
end
