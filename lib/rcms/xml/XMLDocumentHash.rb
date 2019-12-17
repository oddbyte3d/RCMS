
require_relative "../util/Parser"
require_relative "./XMLDocument"
require_relative "./Tag"


class XMLDocumentHash
    attr_accessor :xmlVersion, :xmlEncoding, :APPEND_HEADER, :NOT_FOUND

    def initialize
      @NOT_FOUND = "##Not-found##" #string to return when not found
      @xmlVersion = "1.0"          #Version of the XML that is bieng used (Default is 1.0)
      @xmlEncoding = "ISO-8859-1"  #Encoding that is bieng used(Default is ISO-8859-1
      @APPEND_HEADER = true        #Append the header when XML is parsed to string(Default is true)
      @searchForValueAtPosCount = 0
      @removeValueAtPosCount = 0
      @searchForAttributeAtPosCount = 0
      @getHashForNameAtPosCount = 0
      @newAttributeAtPosCount = 0
      @addNodeAtPosCount = 0
      @removeHashForNameAtPosCount = 0

    end


    #Creates a new Node in the XML Hashtable
    def newNode(nodeName, nodeValue, nodeAttributes)


        hmToReturn = Hash.new     #Create a new Hashtable this represents the Node
        hmToReturn["nodeName"] = nodeName    #This is the Node Name ie(<nodeName></nodeName>)
        hmToReturn["nodeValue"] = nodeValue  #This is the Node Value ie(<nodeName>NodeValue</nodeName>)
        hmToReturn["nodeAttributes"] = nodeAttributes    #These are the Node attributesie(<nodeName nodeAttribute="value"></nodeName>)
        hmToReturn["childCount"] = 0      #Amount of children Nodes

        #puts "Hash forNewNode:#{hmToReturn}"
        #setAddHeader(false);
        #    try{
        #        String toCreateXML = new String(parseHashtableToXML(hmToReturn,true).getBytes(),xmlEncoding);
        #        //System.out.println("Parsed Hash:"+toCreateXML);
        #        hmToReturn = createHashtableFromString(toCreateXML);
        #        return hmToReturn;
        #    }catch(Exception e){}
        #    return null;
        return hmToReturn
    end

	def setNodeName(hmXML, nodeName)

		#hmXML.delete("nodeName")
		hmXML["nodeName"] = nodeName
		return hmXML
	end


  def createHashtableFromFile(fileName)
    return createHashtableFromString( File.read(fileName) )
  end
=begin
 Creates a new xmlHashtable from a String
 @param xml String to create a Xml Hashtable from
 @return Xml Hashtable
=end
  def createHashtableFromString( xml )

    docType = "<!DOCTYPE"
    encoding = "encoding=\""
    #TO-DO : parser functions in own element
    if xml.index(encoding) != nil
      xml = Parser.replace(xml, xml[xml.index(encoding)-1..xml.index("\"",xml.index(encoding)+encoding.size)],"#{encoding}#{@xmlEncoding}\"")
    end
    if(xml.index(docType) != nil)
        #puts "\n\n\n----------------XML Before-------------------\n#{xml}"
        xml = Parser.replace(xml, xml[xml.index(docType)..xml.index(">",xml.index(docType)+docType.size)],"")
        #puts "\n\n\n----------------XML After-------------------\n#{xml}"
    end
    #System.out.println("\n\n\n----------------XML-------------------\n"+xml);
    xmlDoc = XMLDocument.new(xml,false)
    #System.out.println("\n\n\n----------------XML-------------------\n"+xmlDoc.toString());
    return createHashtableFromXMLDocument(xmlDoc)    #Returns the Document
  end

  def getChildCount(xml)

      if xml["childCount"] != nil
          return xml["childCount"]
      end
      return -1;
  end

  def getChildrenNames(xml)

      childCount = xml["childCount"].to_i
      toReturn = Array.new

      for i in 0..childCount do

          child = xml[i]
          toReturn[i] = child["nodeName"]
      end
      return toReturn
  end

 # Returns a child node at index
 # @param rolle Xml Hashtable
 # @param index Index of child node
 # @return Xml Hashtable
 # representing the child node
	def getChildNode(xml, index)

    #puts "XML -- \n\n#{xml}"
	    childCount = 0
      if(xml != nil && xml["childCount"] != nil)

        childCount = xml["childCount"].to_i
    		if(index >= 0 && index < childCount)
    		    return xml[index]
    		end
      end
	    return nil
	end

  def getNodeName(xml)
    if(xml != nil && xml["nodeName"] != nil )
        return xml["nodeName"]
    end
    return ""
  end

 #  Adds a New Node Value to the XML
 # @param rolle
 # @param nodeName
 # @param toAdd
 # @param nodeOver
 #TO-DO: Make synchronized (Mutex.new??)
  def addNodeAtPos(xml, toAdd, nodeOver)

      size = xml["childCount"].to_i
      if(xml["nodeName"] == nodeOver)

              xml["childCount"] = size+1
              xml[size] = toAdd
              return
      end
      for j in 0..size

          values = xml[j]
          if(values["nodeName"] == nodeOver)
              addNodeAtPos(values, toAdd, nodeOver)
              break
          else

              countVals = values["childCount"].to_i
              for k in 0..countVals
                  addNodeAtPos(values[k], toAdd,nodeOver)
              end
          end
      end
  end

  def addNodeAtPos(xml, toAdd, nodeOver, position)

    size = xml["childCount"].to_i
    if(xml["nodeName"]== nodeOver)

        countVals = xml["childCount"].to_i
        xml["childCount"] = countVals+1
        if(position < countVals)

            for i in countVals..position

                temp = xml.delete(i)
                if(temp != nil)
                    xml[i+1] = temp
                end
            end
        end
        if(position > countVals)
            xml[countVals] = toAdd
        else
            xml[position] = toAdd
        end
        return
    end
    for j in 0..size

        values = xml[j]
        if(values["nodeName"] == nodeOver)

            countVals = values["childCount"].to_i
            values["childCount"] = countVals+1
            if(position < countVals)

                for i in countVals..position
                    temp = xml.delete(i)
                    if(temp != nil)
                        xml[i+1] = temp
                    end
                end
            end
            if(position > countVals)
                xml[countVals] = toAdd
            else
                xml[position] = toAdd
            end
            return
        else
            countVals = values["childCount"].to_i
            for k in 0..countVals
                addNodeAtPos(values[k], toAdd,nodeOver)
            end
        end
    end
  end

 #-----------------------------------------
 #
 #  Adds a value to the XML stating at the node toStartAt
 # @param rolle
 # @param toStartAt
 # @param nodeName
 # @param toAdd

  def addNodeStartingAt(xml, toAdd, toStartAt, nodeName)

      count = 0
      size = xml["childCount"].to_i
      for j in 0..size

          values = xml[j]
          if(values["nodeName"] == toStartAt)
              addNodeAtPos(values,toAdd,nodeName)
          else
              countVals = values["childCount"].to_i
              for k in 0..countVals
                  addNodeStartingAt(values[k], toAdd,nodeName,toStartAt)
              end
          end
      end
    end
        # Tries to Clean the XML Hashtable from not needed Nodes(Extreame Beta use at own Risk[ Removes unwanted comments ]).
        # @param documentHash Hashtable
        # @return Hashtable
  def cleanXMLMap(documentHash)

     xmlMap = Hash.new

      childCount = documentHash["childCount"].to_i
      xmlMap["nodeName"] = documentHash["nodeName"]
      xmlMap["nodeValue"] = documentHash["nodeValue"]
      xmlMap["nodeAttributes"] = documentHash["nodeAttributes"]
      xmlCount = 0
      for i in 0..childCount
          xmlTemp = documentHash[i]
          if(  !xmlTemp["nodeName"].start_with?("\#") )

              xmlTemp = cleanXMLMap(hmTemp)
              xmlMap[rollenCount] = hmTemp
              xmlCount = xmlCount.next
          end
      end
      xmlMap["childCount"] = xmlCount
      return xmlMap
  end

	def createHashtableFromXMLDocument(xmlDoc)
	    return createHashtableFromXMLTag(xmlDoc.getRootTag)
	end


	def createHashtableFromXMLTag(xmltag)

	    if(xmltag == nil || xmltag.name.downcase == "special-text-tag")
	    	return nil
      end
      #if(xmltag.name.downcase == "special-text-tag")

      #end
	    xmlTemp = xmltag.children
      #puts "XML-tag: #{xmlTemp}"
      hmTemp = Hash.new
	    hmTemp["nodeName"] = xmltag.name
	    if(xmltag.content != nil)
			     hmTemp["nodeValue"] = xmltag.content
	    else
			     hmTemp["nodeValue"] = ""
	    end
	    if(xmltag.attributes != nil)
			     hmTemp["nodeAttributes"] = xmltag.attributes
	    else
			     hmTemp["nodeAttributes"] = Hash.new
	    end
	    i = 0
	    addNext = 0

			size = xmlTemp.size
			for i in 0..size
        if(xmlTemp[i] != nil && xmlTemp[i].name.downcase == "special-text-tag")
          nodeValue = xmlTemp[i].content
          if(nodeValue.strip != "")
            hmTemp["nodeValue"] = nodeValue
          end
        end
				tmp = createHashtableFromXMLTag(xmlTemp[i])
				if(tmp != nil)

			    	hmTemp[addNext] = tmp
			    	addNext = addNext.next
				end
	    end
	    hmTemp["childCount"] = addNext
		  return hmTemp
	end


  def getNodeAttributes(xmltmp)

      return xmltmp["nodeAttributes"]
  end


   # Returns the first HashNode with the Name of nodeName
   # @param rolle
   # @param nodeName
   # @return
    def getHashForName(xmltmp, nodeName)

        if(xmltmp["nodeName"] == nodeName) #First check to see if We already have the right node
            return xmltmp   #If yes then give it back to the caller
        end

        size = xmltmp["childCount"].to_i #Get the count of children to inspect
        for j in 0..size   #Loop through the child nodes to find the right one

            values = xmltmp[j]   #Get the Next ChildNode out.
            if(values["nodeName"] == nodeName)       #Check the name
                return values;  #If it is the one we are searching for then return it
            else    #If not then we need to search through all the childNodes from this Node

                countVals = values["childCount"].to_i #Get the amount of childNodes
                for k in 0..countVals  #Loop through the Nodes
                    value = getHashForName(values[k] = nodeName) #Now check the Node and its children
                    if(value != nil)
                        return value
                    end
                end
            end
        end
        return nil
    end

    #Return the Node from name nodeName at position index
    # @param rolle
    # @param nodeName
    # @return
    # TO-DO: make synchronized
    def getHashForNameAtPos(xml, nodeName, index)
      if(xml == nil)
        return
      end
      #puts "XML: #{xml}"
      if( xml != nil && xml["nodeName"] == nodeName )

        if(@getHashForNameAtPosCount == index)
            return xml
        end
        @getHashForNameAtPosCount = @getHashForNameAtPosCount.next
      end
      attribs = nil
    	if(xml["nodeAttributes"] != nil)
    	   attribs = xml["nodeAttributes"]
    	else
    		 attribs = Hash.new
    	end
      size = xml["childCount"].to_i
      for j in 0..size

          values = xml[j]
          if(values != nil && values["nodeName"] == nodeName)
              if(@getHashForNameAtPosCount == index)
                  return values
              end
              @getHashForNameAtPosCount = @getHashForNameAtPosCount.next
          elsif(values != nil)
              countVals = values["childCount"].to_i
              for k in 0..countVals
                  value = getHashForNameAtPos(values[k], nodeName, index)
                  if(value != nil)
                      return value
                  end
              end
          end
      end
      return nil
  end
  ################################################################################################################
  #Returns the first HashNode with the Name of nodeName
  # @param rolle
  # @param nodeName
  # @return
  def removeHashForName(xml, nodeName)
    if( xml["nodeName"] == nodeName) #First check to see if We already have the right node
        return xml   #If yes then give it back to the caller
    end

    size = xml["childCount"].to_i #Get the count of children to inspect
    for j in 0..size   #Loop through the child nodes to find the right one
        values = xml[j]   #Get the Next ChildNode out.
        if(values["nodeName"] == nodeName)       #Check the name

            xml["childCount"] = size -1
            removed = xml.delete[j]
            if(j < (size-1))
                for i in (j+1)..size
                    temp = xml.delete[i]
                    xml[i-1] = temp
                end
            end
            return removed

        else    #If not then we need to search through all the childNodes from this Node

          countVals = values["childCount"].to_i #Get the amount of childNodes
          for k in 0..countVals  #Loop through the Nodes
              value = removeHashForName(values[k], nodeName) #Now check the Node and its children
              if(value != nil)
                  return value
              end
          end
        end
    end
    return nil
  end

 #Return the Node from name nodeName at position index
 # @param rolle
 # @param nodeName
 # @return
 # TO-DO: need to synchronize following

  def removeHashForNameAtPos(xml, nodeName, index)

      if( xml != nil && xml["nodeName"] == nodeName )

          if(@removeHashForNameAtPosCount == index)
              return xml
          end
          @removeHashForNameAtPosCount = @removeHashForNameAtPosCount.next
      end
      attribs = xml["nodeAttributes"]
      size = xml["childCount"].to_i
      for j in 0..size

          values = xml[j]
          if(values != nil && values["nodeName"] == nodeName)

              if(@removeHashForNameAtPosCount == index)

                  xml["childCount"] = size-1
                  removed = xml.delete(j)
                  if(j < (size-1))

                      for i in (j+1)..size
                          temp = xml.delete(i)
                          xml[i-1] = temp
                      end
                  end

                  return removed
              end
              @removeHashForNameAtPosCount = @removeHashForNameAtPosCount.next

          else

              countVals = values["childCount"].to_i
              for k in 0..countVals

                  value = removeHashForNameAtPos(values[k], nodeName, index)
                  if(value != nil)
                      return value
                  end
              end
          end
      end

      return nil
  end


 #Return the Node from name nodeName at position index
 # @param rolle
 # @param nodeName
 # @return
 # TO-DO: make synchronized
  def removeNodeAtPos(xml, index)

      attribs = xml["nodeAttributes"]
      size = xml["childCount"].to_i
      returnHash = xml.delete(index)
      for j in (index+1)..size

          temp = xml.delete(j)
          xml[j-1] = temp
      end
      xml["childCount"] = (size-1)
      return returnHash
  end

################################################################################################################




 # Creates a XML String from the Hashtable
 # @param hmXML
 # @return
 # TO-DO: make private/synchronized

    def getXMLText(hmXML, cdata)
        if hmXML == nil
          return
        end
        xml = ""
        #try{
        #    XML = new String("".getBytes(),xmlEncoding);
        #}catch(Exception e){}

        #puts "----#{hmXML}"

        nodeName    =  hmXML["nodeName"]
        hmAttrib    =  hmXML["nodeAttributes"]
        nodeValue   =  hmXML["nodeValue"]
        #puts "Node Value : #{nodeValue}"
        needsFinish = true
        childCount  =  hmXML["childCount"].to_i
        #puts "Child Count: #{childCount}"
        if(nodeName != nil )

           if(nodeName[0] != '#' && !nodeName.start_with?("!--"))

                xml = "<".concat(nodeName).encode(xmlEncoding)
                #attSet = hmAttrib.keysSet();
                #Object attObj[] = attSet.toArray();
                hmAttrib.keys.each{ |key|
                  xml.concat(" #{key}=\"#{hmAttrib[key]}\"").encode(xmlEncoding)

                }
                needsFinish = true
                xml.concat(">")

            end
            if(needsFinish || childCount!=0)
                #puts "1 Node Value: #{nodeValue}"
                if(nodeName.start_with?("#comment") || nodeName.start_with?("!--") && !nodeName.end_with?("/"))
                  #puts "1.1 Node Value: #{nodeValue}"
                    xml = "<!--#{nodeValue}".encode(xmlEncoding)
                    attSet.keys.each{ |key|
                      xml.concat(" #{key}=\"#{hmAttrib[key]}\"").encode(xmlEncoding)
                    }
                    xml.concat("-->")
                end
                #puts "2 Node Value: #{nodeValue} #{nodeName}"
                if(nodeValue != nil && nodeValue.strip != "" && !nodeName.start_with?("#comment") && !nodeName.start_with?("!--") && !nodeName.end_with?("/"))
                  #puts "2.1 Node Value: #{nodeValue}"
                    if(cdata)
                        xml.concat("<![CDATA[#{nodeValue}]]>").encode(@xmlEncoding)
                    else
                      #puts "2.2 Node Value: #{nodeValue}"
                        xml.concat(nodeValue)
                    end
                end


                for i in 0..childCount
                  xmlt = getXMLText(hmXML[i], cdata)
                  #puts "----#{xmlt}"
                  if xmlt != nil
                    xml.concat(xmlt )
                  end
                end
                if(nodeName[0] != '#' && !nodeName.start_with?("!--") && !nodeName.end_with?("/"))

                    xml.concat("</#{nodeName}>\n")
                end
            end
        end
        return xml.encode(@xmlEncoding)
    end

    # TO-DO: make private/synchronized
    def getXMLFromHashtable(hmXML, deep)

        #xml = (new String(("").getBytes(),xmlEncoding) );}catch(Exception e){}
        nodeName     =  hmXML["nodeName"]
        hmAttrib     =  hmXML["nodeAttributes"]
        nodeValue    =  hmXML["nodeValue"].strip
        tab          =  ""
        needsFinish  =  true
        childCount   =  hmXML["childCount"].to_i

        #puts "Deep is: #{deep}"
        for i in 0..deep
            tab.concat("\t")
        end
        if(nodeName[0] != '#')

            xml = "<#{nodeName}"
            attSet.keys.each{ |key|
              xml.concat(" #{key}=\"#{hmAttrib[key]}\"").encode(xmlEncoding)
            }
            needsFinish = true
            xml.concat(">")

        end
        if(needsFinish || childCount!=0)

            if(nodeName.start_with?("#comment"))

                xml = "<!--#{nodeValue}".encode(xmlEncoding)
                attSet.keys.each{ |key|
                  xml.concat(" #{key}=\"#{hmAttrib[key]}\"").encode(xmlEncoding)
                }
                XML.concat("-->")
            end

            if(nodeValue != nil && nodeValue != "" && !nodeName.start_with?("#comment"))
                xml.concat(nodeValue).encode(xmlEncoding)
            end

            for i in 0..childCount
                xml.concat(getXMLFromHashtable(hmXML[i],deep+1))
            end
            if(nodeName[0] != '#')
                xml.concat("</#{nodeName}>\n")
            end
        end
        return xml
    end

  #Creates a new Attribute and adds it to the Hashtable
  # @param rolle
  # @param nodeName
  # @param attributeName
  # @param toReplaceWith
  # TO-DO: make synchronized

    def newAttributeAtPos(xml, nodeName, attributeName, attribute, index)

        if( xml["nodeName"] == nodeName )
            if(newAttributeAtPosCount == index)
                attribs = xml["nodeAttributes"]
                attribs[attributeName] = attribute
            end
            newAttributeAtPosCount.next
        end

        size = xml["childCount"].to_i
        for j in 0..size

            values = xml[j]
            if(values["nodeName"] == nodeName)
                if(newAttributeAtPosCount == index)
                    hmValue = values["nodeAttributes"]
                    hmValue[attributeName] = attribute
                end
                @newAttributeAtPosCount = @newAttributeAtPosCount.next
            else
                count = values["childCount"].to_i
                for k in 0..count
                    newAttributeAtPos(values[k],nodeName,attributeName,attribute,index)
                end
            end
        end
    end

 # Creates XML as a String from a correct Hashtable
 # @param hmXML
 # @return

    def parseHashtableToXML(hmXML)

        xml = ""
        if(@APPEND_HEADER)
            xml = "<?xml version=\"#{@xmlVersion}\" encoding=\"#{@xmlEncoding}\"?>\n"
        end
        xml.concat(getXMLFromHashtable(hmXML,0))
        return xml.encode(@xmlEncoding)
    end

    def parseHashtableToXML(hmXML, cdata)

        xml = ""
        if(@APPEND_HEADER)
            xml = "<?xml version=\"#{xmlVersion}\" encoding=\"#{xmlEncoding}\"?>\n"
        end
        xml.concat(getXMLText(hmXML,cdata))
        return xml.encode(@xmlEncoding)
    end

   # Removes a Value from the Hashtable
   # @param rolle
   # @param nodeName
   # @param index
   # @return
   # TO-DO: make synchronized
    def removeValueAtPos(xml, nodeName, index)


        size = xml["childCount"].to_i
        for j in 0..size

            values = xml[j]
            if(values["nodeName"] == nodeName)
                if(removeValueAtPosCount  == index)

                    hmValue = xml.delete(xml[j])
                    xml["childCount"] = (size-1)
                    for i in (j+1)..size

                        temp = xml.delete(i)
                        xml[i-1] = temp
                    end
                    return hmValue
                end
                @removeValueAtPosCount = @removeValueAtPosCount.next
            else
                countVals = values["childCount"].to_i
                for k in 0..countVals

                    value = removeValueAtPos(values[k],nodeName,index)
                    if(value != nil)
                        return value
                    end
                end
            end
        end
        return nil
    end

 #Removes a value (the search for this value starts at /-- toStartAt --/
 # @param rolle
 # @param toStartAt
 # @param nodeName
 # @param index
 # @return
 # TO-DO: make synchronized

    def removeValueStartingAt(xml, toStartAt, nodeName, index)

        count = 0
        size = xml["childCount"].to_i
        for j in 0..size

            values = xml[j]
            if(values["nodeName"] == toStartAt)
                return removeValueAtPos(values,nodeName,index)
            else

                countVals = values["childCount"].to_i
                for k in 0..countVals

                    value = removeValueStartingAt(values[k],nodeName,toStartAt,index)
                    if(value != null)
                        return value
                    end
                end
            end
        end
        return nil
    end

  #Replaces an Attribute within a XML tag
  # @param rolle
  # @param nodeName
  # @param attributeName
  # @param toReplaceWith
  # TO-DO: make synchronized

    def replaceAttribute(xml, nodeName, attributeName, toReplaceWith)

        if( xml["nodeName"] == nodeName )

            attribs = xml["nodeAttributes"]
            attribs[attributeName] = toReplaceWith
        end

        size = xml["childCount"].to_i
        for j in 0..size

            values = xml[j]
            if(values["nodeName"] == nodeName)

                hmValue = values["nodeAttributes"]
                hmValue[attributeName] = toReplaceWith
            else

                count = values["childCount"].to_i
                for k in 0..count
                    replaceAttribute(values[k],nodeName,attributeName,toReplaceWith)
                end
            end
        end
    end

 #  Replaces a Value within a XML tag
 # @param rolle
 # @param nodeName
 # @param toReplaceWith
 # TO-DO: make synchronized

    def replaceValue(xml, nodeName, toReplaceWith)

        if( xml["nodeName"] == nodeName )
            xml["nodeValue"] = toReplaceWith
        end

        attribs = xml["nodeAttributes"]
        size = xml["childCount"].to_i
        for j in 0..size

            values = xml[j]
            if(values["nodeName"] == nodeName)

            #    if(values.get("0") == null)
            #    {
	          #     System.out.println("Adding val");
            #        Hashtable childMe = new Hashtable();     //Create a new Hashtable this represents the Node
            #        childMe.put("nodeName","#text");    //This is the Node Name ie(<nodeName></nodeName>)
            #        childMe.put("nodeValue",toReplaceWith);  //This is the Node Value ie(<nodeName>NodeValue</nodeName>)
            #        childMe.put("nodeAttributes",new Hashtable());    //These are the Node attributesie(<nodeName nodeAttribute="value"></nodeName>)
            #        childMe.put("childCount",new Integer(""+0));      //Amount of children Nodes
            #
            #        this.addNodeAtPos(values, childMe,nodeName);
            #    }
            #    else
            #    {
	          #   System.out.println("Replacing val");
            #        Hashtable hmValue = (Hashtable)values.get("0");
            #        hmValue.put("nodeValue",toReplaceWith);
            #    }
                values["nodeValue"] = toReplaceWith

            else

                count = values["childCount"].to_i
                for k in 0..count

                    replaceValue(values[k],nodeName,toReplaceWith)
                end
            end
        end
    end

 # Tries to find an Attribute given the node name returns "" if nothing found
 # @param rolle Xml Hashtable to search
 # @param nodeName Name of node to find
 # @param attributeName Attribute name to find.
 # @return Value of attribute.
 # TO-DO: make synchronized
    def searchForAttribute(xml, nodeName, attributeName)

        if( xml["nodeName"] == nodeName )

            attribs = xml["nodeAttributes"]
            if(attribs[attributeName] == nil)
                return @NOT_FOUND
            end
            return attribs[attributeName]
        end

        size = xml["childCount"].to_i
        for j in 0..size

            values = xml[j]
            if(values["nodeName"] == nodeName)

                hmValue = values["nodeAttributes"]
                if(hmValue[attributeName] != nil)
            	     return hmValue[attributeName]
                end
            else

              value = searchForAttribute(values,nodeName,attributeName)
              if(value != "" && value != @NOT_FOUND)
          	     return value
              end
            end
        end
        return @NOT_FOUND
    end


 #  Tries to find an Attribute given the node name and at which position to find it
 #  (First finds index amount of nodeName -1 then returns the next one ) returns "" if not found
 # @param rolle
 # @param nodeName
 # @param attributeName
 # @return
 # TO-DO: make synchronized
    def searchForAttributeAtPos(xml, nodeName, attributeName, index)

        if( xml["nodeName"] == nodeName )

            if(searchForAttributeAtPosCount == index)

                attribs = xml["nodeAttributes"]
                if(attribs[attributeName] == nil)
                    return @NOT_FOUND
                end
                return attribs[attributeName]
            else
                @searchForAttributeAtPosCount = @searchForAttributeAtPosCount.next
            end
        end


        size = xml["childCount"].to_i
        for j in 0..size

            values = xml[j]
            if(values["nodeName"] == nodeName)

                if(searchForAttributeAtPosCount == index)
                    attribs = values["nodeAttributes"]
                    return attribs[attributeName]
                end
                @searchForAttributeAtPosCount = @searchForAttributeAtPosCount.next

            else
                countVals = values["childCount"].to_i
                for k in 0..countVals
                    value = searchForAttributeAtPos(values[k],nodeName,attributeName,index)
                    if(value != @NOT_FOUND)
                        return value
                    end
                end
            end
        end
        return @NOT_FOUND
    end

 #  Tries to find an Attribute given the node name, a starting node and at which position to find it
 #  (First finds index amount of nodeName -1 then returns the next one ) returns "" if not found
 # @param rolle
 # @param toStartAt
 # @param nodeName
 # @param index
 # @return
 # TO-DO: make synchronized

        def searchForAttributeStartingAt(xml, toStartAt, nodeName, attributeName, index)

            count = 0
            size = xml["childCount"].to_i
            for j in 0..size

                values = xml[j]
                if(values["nodeName"] == toStartAt)
                    return searchForAttributeAtPos(values,nodeName, attributeName,index)
                else
                    countVals = values["childCount"].to_i
                    for k in 0..countVals
                        value = searchForAttributeStartingAt(values[k],nodeName,toStartAt, attributeName,index)
                        if(value != "")
                            return value
                        end
                    end
                end
            end
            return ""
        end

 #  Returns the first match of nodeName returns "" if not found
 # @param rolle
 # @param nodeName
 # @return

  def searchForValue(xml, nodeName)
      #puts "\n--------------\nXMLDocumentHash.searchForValue 979: #{nodeName} \n#{xml}\n---------------------------"
      if(xml == nil)
        return ""
      end
      if xml["nodeName"] == nodeName
          hmTemp = xml[0]
          if hmTemp != nil

              if hmTemp == nil || hmTemp["nodeValue"] == nil
                  return ""
              end
              return hmTemp["nodeValue"]
          else
              if xml == nil || xml["nodeValue"] == nil
                  return ""
              end

              return xml["nodeValue"]
          end
      end

      attribs = xml["nodeAttributes"]
      #puts "nodeAttributes : #{attribs}"
      size = xml["childCount"]
      #puts "childCount : #{size}"
      for j in 0..(size-1)

          value = xml[j]
          #puts "\n--at #{j}-------------Value XMLDocumentHash 1007----\n#{value}\n--------------------"
          if (value != nil && value["nodeName"] == nodeName)

              if value == nil || value == nil || value["nodeValue"] == nil
                  return ""
              end
              return value["nodeValue"]
          else

              count = value["childCount"]
              for k in 0..count
                  valSt = searchForValue(value[k], nodeName)
                  if valSt != @NOT_FOUND && valSt != ""
                      return value
                  end
              end
          end
      end
      return @NOT_FOUND
  end

  def setCountToZero

      @searchForValueAtPosCount = 0
      @removeValueAtPosCount = 0
      @searchForAttributeAtPosCount = 0
      @getHashForNameAtPosCount = 0
      @newAttributeAtPosCount = 0
      @removeHashForNameAtPosCount = 0
  end

 # Returns the value of the x-th nodeName, returns "" if not found
 # @param rolle
 # @param nodeName
 # @param index
 # @return

  def searchForValueAtPos(xml, nodeName, index)

      if xml.name == nodeName
          if @searchForValueAtPosCount == index
              xmlTemp = xml.children[0]
              if xmlTemp != nil
                  if xmlTemp.content == nil
                      return ""
                  end
                  return xmlTemp.content
              else
                  if xml.content == nil
                      return ""
                  end
                  return xml.content
              end
          else
              @searchForValueAtPosCount = @searchForValueAtPosCount.next
          end
      end

      attribs = xml.attributes
      size = xml.children.size
      for j in 0..size do

          value = xml.children[j]
          if value.name == nodeName

              if @searchForValueAtPosCount == index

                  val = value.content
                  if val == nil
                      val = ""
                  end
                  return val
              end
              @searchForValueAtPosCount = @searchForValueAtPosCount.next
          else

              countVals = value.children.size
              for k in 0..countVals do

                  valSt = searchForValueAtPos(value.children[k], nodeName, index)
                  if !valSt == @NOT_FOUND
                      if valSt == nil

                          valSt = ""
                      end
                      return valSt
                  end
              end
          end
      end
      return @NOT_FOUND
  end


 # Returns the value of x-th nodeName given the starting node and a index
 # @param rolle
 # @param toStartAt
 # @param nodeName
 # @param index
 # @return

  def searchForValueStartingAt(xml, toStartAt, nodeName, index)
      count = 0;
      size = xml.children.size #((Integer)rolle.get("childCount")).intValue();
      for j in 0..size do
        value = xml.children[j]
        if value.name == toStartAt
          return searchForValueAtPos(values,nodeName,index)
        else
            countVals = value.children.size
            for k in 0..countVals do
                #String value = searchForValueStartingAt((Hashtable)values.get(new Integer(k)),nodeName,toStartAt,index);
                valSt = searchForValueStartingAt(value.children[k], toStartAt, nodeName, index)
                if valSt == ""
                    return valSt
                end
            end
        end
      end
      return ""
  end

end
