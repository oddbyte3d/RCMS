class Tag
  #attr_reader :name
  attr_accessor :name, :content, :children, :attributes, :isComment, :isContentCDATA, :isSpecialTextTag, :tagEnd, :hasEndTag

  def initialize(name)
    @name = name
    #puts "Tag Name: #{name}"
    @attributes = {}
    @children = []
    @isComment = false
    @isContentCDATA = false
    @isSpecialTextTag = false
    @tagEnd = nil
    @hasEndTag = false
    @content = nil
  end


  def setTagEnd(tagEnd)
      @tagEnd = tagEnd
      @hasEndTag = true
      if @tagEnd == "special-text-tag"
          @isSpecialTextTag = true
      end
  end

  #def isSpecialTextTag
  #  isSpecialTextTag = (@content != nil)
  #  return isSpecialTextTag
  #end

end
