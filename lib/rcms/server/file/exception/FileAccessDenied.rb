class FileAccessDenied < StandardError

  attr_reader :error
  def initialize(message)
    @error = message
    super(@error)
  end

end
