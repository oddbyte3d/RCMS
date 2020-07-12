class HttpSession < Hash

  attr_reader :sessionId

  def initialize(id)
    @sessionId = id
  end

  def self.generate_code(number)
    charset = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9')
    Array.new(number) { charset.sample }.join
  end


  def getParameter(key)
    return self[key]
  end

  def setParameter(key, value)
    self[key] = value
  end
end
