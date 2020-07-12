$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), './' ) )
require 'strscan'
require 'Tag'

class XMLDocument

  attr_reader :XML_DOC
  @SPECIAL_TEXT_TAG = "special-text-tag"

  def initialize(xml, isFile)
    if isFile
      @buffer =  File.read(xml)
      finishInit
    elsif (xml.is_a? String)
      @buffer = xml
      finishInit
    else
      @XML_DOC = xml
    end
  end

  def finishInit
    @readPosition = 0
    #puts @buffer.string
    #@buffer = StringScanner.new(str)
    #@tags   = []
    @queue  = []
    @beginningUnusableTags = []
    @NO_ATTRIBUTE_END = "**NO_ATTRIBUTE_END**"
    @ROOT_ELEMENT_NAME = "XML"
    @AUTO_ROOT_NAME = true
    @XML_DOC = []
    @TAGS_IN_ORDER = {}
    @ENCODING = "ISO-8859-1"
    @NO_ATTRIBUTE_END = "**NO_ATTRIBUTE_END**"
    parse
  end

  def getRootTag
    return @XML_DOC[0]
  end
  def parse
    parseDocument(@buffer)
  end

  def parseDocument(doc)
      doc = doc.strip

      while doc.start_with?("<!DOCTYPE") || doc.start_with?("<!--") || doc.start_with?("<?")
          if doc.start_with?("<!DOCTYPE")
              toRemove = doc[doc.index("<!DOCTYPE"),doc.index('>')+1]
              @beginningUnusableTags << toRemove
              doc = replace(doc,toRemove,"")
              doc = doc.strip
          end

          if doc.start_with?("<!--")
              toRemove = doc[doc.indexOf("<!--"),doc.indexOf("-->")+3]
              @beginningUnusableTags << toRemove
              doc = replace(doc,toRemove,"")
              doc = doc.strip

          end
          if doc.start_with?("<?")
              toRemove = doc[doc.index("<?"),doc.index('>')+1]
              @beginningUnusableTags << toRemove
              doc = replace(doc,toRemove,"")
              doc = doc.strip

          end
      end


      @buffer = doc				#Set the current document to the string given

      @buffer =  setTextTags(@buffer)
      #puts "Buffer after setTextTags : #{@buffer}"
      getTags(@buffer)
      organizeHash()
  end

  def setTextTags(toParse)
      String toReturn = ""
      starttext = false
      cdata = false

      for i in 0..toParse.size do
        if toParse[i] != nil
          if !cdata && toParse[i] == '<' && toParse[i+1] != '!' && starttext
              toReturn.concat("</special-text-tag>")
              toReturn.concat(toParse[i])
              #puts "text tags 1 : #{toReturn}"
              starttext = false
          elsif toParse[i] == '<' && toParse[i+1] == '!' && toParse[i+2] == '['
              cdata=true
              toReturn.concat("<special-text-tag>")
              toReturn.concat(toParse[i])
              #puts "text tags 2 : #{toReturn}"
          elsif cdata && toParse[i] == '>' && toParse[i-1] == ']'  && toParse[i-2] == ']'
              cdata = false
              toReturn.concat(toParse[i])
              toReturn.concat("</special-text-tag>")
              #puts "text tags 3 : #{toReturn}"
          elsif !cdata && toParse[i] == '>' && toParse[i-1] != ']' &&  (toParse[i+1] != nil && toParse[i+1].strip != "") #, toParse.size
              starttext = true
              toReturn.concat(toParse[i])
              toReturn.concat("<special-text-tag>")
              #puts "text tags 4 : #{toReturn}"
          else
              toReturn.concat(toParse[i])
              #puts "text tags 5 : #{toReturn}"
          end
        end
      end
      return toReturn
  end

  def getTags(toSearch)

      newToSearch = toSearch  #Set the String to Search
      hmTemp = nil
      tagAt = 0
      deleteNextTextTagEnd = false
      while (hmTemp = getTag(newToSearch)) != nil	#Check to make sure that we are still getting tags

          if tagAt == 0 && @AUTO_ROOT_NAME
              @ROOT_ELEMENT_NAME = hmTemp.name
              #puts "RootTag::#{@ROOT_ELEMENT_NAME}::----"
          end

          if hmTemp.name != nil && hmTemp.isSpecialTextTag && hmTemp.content != nil && hmTemp.content.strip == ""
              deleteNextTextTagEnd = true
          elsif deleteNextTextTagEnd && hmTemp.isSpecialTextTag
              deleteNextTextTagEnd = false
          else
              @XML_DOC << hmTemp					#Put it into the HTMLDocument
              #System.out.println("Adding::"+hmTemp+"::");
              tagAt = tagAt.next
          end
          newToSearch = removeTag(newToSearch,hmTemp.name)	#Remove the Tag from the SearchString so it will not be processed again
      end

      return 1
  end

  def getTag(textToSearch)
    hmTag = Tag.new("---")
    startTag = textToSearch.index('<')
    endTag = textToSearch.index('>')
    nextToFind = ""
    if startTag != nil
      if textToSearch[startTag+1] == "!"
        nextToFind = "-->"
      else
        nextToFind = ">"
        endTag = textToSearch.index(nextToFind, startTag)
        endTag += nextToFind.size
      end
    end

    if startTag != nil && endTag != nil
      tag = textToSearch[startTag, endTag]
      if tag != nil && (tag.index("</") == nil || tag.start_with?("<!--"))
        tagName = ""
        if tag.start_with?("<!--")
          tagName = "!--"
        else
          tagName = getTagName(tag)
        end

        tagHasEndTag = true
        if tagName.end_with?("/")
          tagHasEndTag = false
          tagNameWo = tagName[0, tagName.index("/")]
          tagTemp = replace(tag, tagName, tagNameWo)
          tagTemp << "</"+tagNameWo+">"
          replace(@buffer, tag, tagTemp) #Don't think this does anything
          tag = tagTemp
          tagName = tagNameWo
        elsif textToSearch.index("</#{tagName}>") != nil
          tagHasEndTag = false
        end
        hmTag.name = tagName
        if tagName == @SPECIAL_TEXT_TAG
          hmTag.isSpecialTextTag = true
        end
        if tagName.start_with?("!--")
          hmTag.isComment = true
        else
          atts = getAttributes(tag)
          if atts == nil
            atts = {}
          end
          hmTag.attributes = atts
        end
        if hmTag.isComment
          tmpContent = tag
          tmpContent = tmpContent[4, tmpContent.index("-->")]
          textToSearch = replace(textToSearch, tag, "")
        elsif
           tmpContent = textToSearch[endTag, textToSearch.size]
           if(tmpContent.strip.start_with?("<![CDATA["))
             tmpContent = tmpContent[9, tmpContent.index("]]>")-9]
             #puts "tmpContent : #{tmpContent}"
             hmTag.isContentCDATA = true
           elsif tmpContent.index("<") != nil && tmpContent.index(">") != nil && tmpContent.index("</") != nil
             tmpContent = tmpContent[0, tmpContent.index("<")]
             #code
           end
           if tmpContent.size != 0
             textToSearch = replace(textToSearch, tmpContent, "")
           end
        end
        if tmpContent == nil
          tmpContent = ""
        end
        hmTag.content = tmpContent
      elsif tag != nil

        hmTagEnd = Tag.new(getTagName(tag))
        #puts "Setting end tag :#{hmTagEnd.name}:"
        hmTagEnd.setTagEnd(hmTagEnd.name)
        #hmTagEnd.tagEnd = getTagName(tag)
        #hmTagEnd.hasEndTag = true
        return hmTagEnd
      end

    else
      hmTag = nil
    end
    return hmTag
  end

  def getTagName(tag)
    tagB = tag.index("<")
    tagE = tag.rindex(">")
    if(tagB != nil)
      tagB = tagB.next
      tagNE = tag.index(" ")
      if tagNE == nil
        tagNE = tagE
      end
      tagNam = tag[tagB, tagNE-1]
      if tagNam == "!--"
        tagNam = tag[tagB, tagNE]
      end
      if tagNam.strip != ""
        if tagNam[0] == "/"
          tagNam = tagNam[1, tagNam.size]
        end
        #puts "TagName : #{tagNam}"
        return tagNam
      else
        puts "Tag does not have a correct name..."
        return nil
      end
    else
      puts "This is not a tag..."
      return nil
    end
  end

  def getAttributes(tag)
    #puts "Getting Att:#{tag}:"
    attribs = {}
    tagNamE = tag.index(" ")
    tagWOName = ""
    if tagNamE != nil
      tagWOName = tag[tagNamE+1..tag.rindex('"')]
      #puts "TAGWOName :#{tagWOName}:"
      while tagWOName.index(" ") != nil || tagWOName.index("=") != nil do
        tagWOName = tagWOName.strip
        nameStart = 0
        nameEnd = tagWOName.index("=")+1
        #puts "NameEnd : #{nameEnd}"


        if nameEnd == nil || ((tagWOName.index(" ") != nil && tagWOName.index(" ") < nameEnd) && tagWOName.index(" ") != nil)
          attNameWOEnd = tagWOName
          if tagWOName.index(" ") < nameEnd
            nameEnd = attNameWOEnd.index(" ")
          else
            nameEnd = attNameWOEnd.size-1
          end
          #puts "::#{tagWOName}::"
          attribs[attNameWOEnd[0, nameEnd]] = @NO_ATTRIBUTE_END
          tagWOName = replace(tagWOName, attNameWOEnd, "")
          next
        end

        searchForSpace = nil
        nextChar = tagWOName[nameEnd]
        nextChar2 = tagWOName[nameEnd+1]

        if nextChar == "'"
          if nextChar2 == "'"
            searchForSpace = nameEnd+1
          else
            searchForSpace = tagWOName.index("'", nameEnd+1)
          end
        elsif nextChar == '"'

          if nextChar2 == '"'
            searchForSpace = nameEnd+1
          else
            searchForSpace = tagWOName.index('"', nameEnd+1)
          end
        else
          searchForSpace = tagWOName.index(" ", nameEnd)
        end
        if searchForSpace == nil
          searchForSpace = tagWOName.size-1
        end
        if nameEnd != nil && (searchForSpace == nil || searchForSpace > nameEnd)
          attribStart = nameEnd+1
          attribEnd = nil
          attNextChar = tagWOName[attribStart-1]
          attNextChar2 = tagWOName[attribStart]
          replaceAttNextChar = false
          if attNextChar == "'"
            replaceAttNextChar = true
            if attNextChar2 == "'"
              attribEnd = attribStart+1
            else
              attribEnd = tagWOName.index("'", attribStart)
            end
          elsif attNextChar == '"'
            #puts 'next char is "'
            replaceAttNextChar = true
            if attNextChar2 == '"'
              attribEnd = attribStart+1
            else
              attribEnd = tagWOName.index('"', attribStart)
            end
          else
            attribEnd = tagWOName.index(" ", attribStart)
          end
          if attribEnd == nil
            attribEnd = tagWOName.size-1
          end
          tagName = tagWOName[nameStart, nameEnd-1]
          tagAttrib = tagWOName[attribStart-1..attribEnd-1]
          #puts "1 tagWOName :#{tagWOName}:"
          #puts "2 tagAttrib #{tagAttrib}"
          if replaceAttNextChar && tagAttrib.index(attNextChar) != nil
            tagAttrib = replace(tagAttrib, attNextChar, "")
          end
          #puts "Attribute Found : #{tagName} #{tagAttrib}"
          attribs[tagName] = tagAttrib
          #puts "Attributes : #{attribs}"
          if !(attribEnd+1 > tagWOName.size)
            tagWOName = tagWOName[attribEnd+1, tagWOName.size]
          end
        else
          tagWOName = tagWOName.strip
          tagNameEnd = tagWOName.index(" ")
          if tagName == nil || tagNameEnd == nameStart
            tagNameEnd = tagWOName.size
          end
          tagName = tagWOName[nameStart, tagNameEnd]
          tagWOName = tagWOName[tagNameEnd, tagWOName.size]
        end
      end
    end
    return attribs
  end

  def removeTag(toRemoveFrom, tagName)
      #Parse the Next tag out of the String
      startTag = toRemoveFrom.index('<')
      endTag = toRemoveFrom.index('>')
      nextToFind = ""
      if startTag != nil
          if toRemoveFrom[startTag+1] == '!' && toRemoveFrom[startTag+2] == '-' && toRemoveFrom[startTag+3] == '-'
              nextToFind = "-->"
          else
              nextToFind = ">"
          end
          endTag = toRemoveFrom.index(nextToFind,startTag)
          endTag += nextToFind.size
      end
      if startTag != nil && endTag != nil
          toRemoveFrom = toRemoveFrom[endTag,toRemoveFrom.size]
          if toRemoveFrom.size > 0 && !toRemoveFrom.start_with?("<")
              toRemoveFrom = toRemoveFrom[toRemoveFrom.index('<'),toRemoveFrom.size].strip
          elsif toRemoveFrom.size > 0 && toRemoveFrom.start_with?("<![CDATA[")
              toRemoveFrom = toRemoveFrom[toRemoveFrom.index("]]>")+2,toRemoveFrom.size].strip
          end
      end
      return toRemoveFrom
  end

  def replace(toSearch, toReplace, toReplaceWith)
    temp = ""
    toUseSearch = toSearch
    toUseReplace = toReplace
    startIndex = toUseSearch.index(toUseReplace)
    endIndex = startIndex+toReplace.size
    temp << toSearch[0, startIndex]
    temp << toReplaceWith
    temp << toSearch[endIndex, toSearch.size]
  end

  def replaceAll(toSearch, toReplace, toReplaceWith)
      tmp = toSearch
      toReturn = toSearch
      while tmp.index(toReplace) != nil do
        tmp = replace(toSearch, toReplace, toReplaceWith)
        toReturn = tmp
      end
      return toReturn
  end


  def organizeHash


      size = @XML_DOC.size	#Get the amount of tags to process
      tagsWEndCount = {}	#Hashtable to hold all the tags that have a closing tag
      tagsWOEndCount = {}	#Hashtable to hold all the tags that have no closing tag
      tagsFound = {}	#Hashtable to hold the tags in order


      #First we need to count how many of each tag there is that have a matching end tag
      #keys = @XML_DOC.keys


      for hmTemp in @XML_DOC do
          #puts "Tag :#{hmTemp.name}: EndTag :#{hmTemp.hasEndTag}:"
          #hmTemp = @XML_DOC[i]            #Get the Next tag

          if !hmTemp.isSpecialTextTag && hmTemp.hasEndTag  #Check if it is an End Tag

              tagCount = 0
              if tagsWEndCount[hmTemp.name] != nil			#Count the Tags with this name
                  tagCount = tagsWEndCount[hmTemp.name]
              end
              #tagCount = tagCount.next										#Add one to it
              tagsWEndCount[hmTemp.name] = tagCount.next  #Save how many of this tag there are so far
          end
      end

      #puts "\n\ntagsWEndCount :#{tagsWEndCount}\n\n"
      #Next put the tags in order ie. frameset0,frameset1 etc...
      tagsAt = {}

#-----------------------------------------------------------------------
      for hmTemp in @XML_DOC do

        #  hmTemp = @XML_DOC[i] #Get the Next Tag

          tagName = hmTemp.name	#Get the TagName
          #puts "tag:#{tagName}"

          if tagName != nil && tagsWEndCount[tagName] != nil	#If this tag has a matching End Tag
              tagCount = 0

              if tagsAt[tagName] != nil
                  tagCount = tagsAt[tagName]	#Get the Count of Tags already found with this tagname
              end

              @TAGS_IN_ORDER["#{tagName}#{tagCount}"] = hmTemp	#Put it in its order
              #tagCount = tagCount.next #increment
              #puts "Counted #{tagName} : #{tagCount}"
              tagsAt[tagName] = tagCount.next

          end
      end
      #puts "\n\nTagsAt :#{tagsAt}:\n\n"
#-----------------------------------------------------------------------

      hmOpenTags = {}     #Hashtable to put Opened tags into
      hmTagAt = {}	      #Which tag are we processing
      vTagInline = []	    #Tags that are bieng processed in order from 1-x
      vOpenedTags = []
      lastOpenTag = nil			#Last tag that was opened


      #Lastly we need to organize the Hashtable
      for hmTemp in @XML_DOC do

          vTagSize = vTagInline.size #Get the amount of opened Tags
          #puts "Tags opened :#{vTagSize}"
          vOpenedSize = vOpenedTags.size
          #hmTemp = @XML_DOC[i] #Get the next tag
          tagName = hmTemp.name #Get the TagName
          #puts "tagsWEndCount :#{tagName}: :#{tagsWEndCount[tagName]}"
          tagEnd = hmTemp.tagEnd	#See if it is an EndTag
          if tagName != nil && tagEnd == nil && tagsWEndCount[tagName] != nil	  #if it has a name and is not an EndTag

              lastOpenTag = hmTemp				#Set the current tag to be the last opened Tag
              vOpenedTags << lastOpenTag
              tagCount = 0
              if hmTagAt[tagName] != nil	#if more than one tag with the same name
                  tagCount = hmTagAt[tagName]	#Get the count of tags with the same name that are opened
              end
              hmOpenTags["#{tagName}#{tagCount}"] = hmTemp	#put the Tag into the opened tags Hashtable
              vTagInline << "#{tagName}#{tagCount}"			#put it into the ordered Vector
              tagCount = tagCount.next  		#Make sure that the count gets incremented
              hmTagAt[tagName] = tagCount	#and put it back with the new value
          elsif tagEnd != nil 	#If the tag that we are processing is an End Tag
              tagCount = 0
              if hmTagAt[tagEnd] != nil 		#See if there are more than one of the same tag

                  myTag = nil
                  if vOpenedTags[vOpenedSize-1].name  == tagEnd
                      myTag = vOpenedTags[vOpenedSize-1]
                      vOpenedTags.delete_at(vOpenedSize-1)
                      vOpenedSize = vOpenedSize-1
                  end
                  lastOpenTag = vOpenedTags[vOpenedSize-1]
                  if myTag != nil && lastOpenTag != nil
                    lastOpenTag.children << myTag
                  end
              end
          else
              if lastOpenTag != nil
                  vTags = []
                  if lastOpenTag.children != nil
                      vTags = lastOpenTag.children
                  end
                  hmTemp.hasEndTag = false #["noEndTag"] = "1"
                  vTags << hmTemp
                  lastOpenTag.children = vTags #put("tags",vTags);

              end
          end

      end


      hmTest = @TAGS_IN_ORDER[@ROOT_ELEMENT_NAME+"0"]

      @XML_DOC.clear
      @XML_DOC << hmTest
  end

  def printChild( tag, xml)
    if tag.children != nil && tag.children.size > 0
      for tt in tag.children do
        #xml.concat("<#{tag.name}")
        printChild(tt)
      end
    end
  end



  def xmlToString(hmTag)
      return tagToString(hmTag,0)
  end

  def tagToString(hmTag, deep)
      #puts "TagContent :#{hmTag.content.strip}:"
      toReturn = ""
      toTab = ""
      if hmTag.content != nil && hmTag.content.strip != ""
          return hmTag.content
      else
          toReturn.concat("\n")
      end


      for i in 0..deep do
          toTab.concat("\t")
      end
      toReturn.concat(toTab+"<"+hmTag.name)
      attributes = hmTag.attributes

      #Set attSet = hmAttributes.keySet();
      attObs = attributes.keys

      if !hmTag.isComment
          for i in attObs
              toAdd = " "
              if i != @NO_ATTRIBUTE_END
                  toAdd = "=\"#{attributes[i]}\""
              end

              toReturn.concat( " #{i}#{toAdd}" )
          end
      end
      if hmTag.isComment()
          toReturn.concat("#{hmTag.content}-->\n")
      else
          toReturn.concat(">")
      end
      if !hmTag.isComment && (hmTag.content != nil && !hmTag.content.strip =="")
          tagContent = hmTag.content
          isCDATA = hmTag.isContentCDATA
          tagContent = tagContent.strip
          tagContent = replaceAll(tagContent,"\n","\r")
          if tagContent.end_with("\r#{toTag}")
              length = toTab.size+2
              tagContent = tagContent[0..tagContent.size-length]
          end
          if isCDATA
              toReturn.concat( "#{toTab}\t<![CDATA[#{tagInhalt}]]>\n")
          else
              toReturn.concat("#{toTab}\t#{tagInhalt}\n")
          end
      end
      v = nil

      if !hmTag.isComment && (v = hmTag.children)!= nil
          #vSize = v.size
          for j in v do
              toReturn.concat( tagToString(j,deep.next) )
          end
      end
      if !hmTag.isComment && !hmTag.hasEndTag
          toReturn.concat( "#{toTab}</#{hmTag.name}>\n" )
      end
      return toReturn.encode(@ENCODING)
  end





end
