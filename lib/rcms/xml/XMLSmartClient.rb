#
require_relative './XMLDocumentHash'
require_relative '../util/Parser'

class XMLSmartClient



    # Creates new XmlHelper
    def initialize
      @xmlTool = XMLDocumentHash.new
      @xml = Hash.new
      @xmlFile = nil
      @count = 0
      @node = nil
      @index = 0
      @nodeElement = nil
      @nodeElements = Array.new
      @nodeAt = 0
      @store = false
      @attributName = nil
      @attributeElementName = nil
      @xmlStore = Hash.new
      @xmlStoreMap = nil

	    @nodeValues = Array.new
    end


    def setXML(xml)
    	@xml = xml
    end

    # Set the XML-File to get information from,
    # First we look in the ATG wide component
    # ActiveRepositoryLoader for the existing
    # Hashtable corresponding to xmlFile, if it
    # is not there then we still need to load
    # it from the file system.
    # @param xmlFile Path to the file

    def setXmlFile(xmlFileTmp)
      @xmlFile = xmlFileTmp
      if(@xmlFile.index("//") != nil)
        @xmlFile = Parser.replaceAll(@xmlFile,"//","/")
      end
      if(File.exists?(@xmlFile) && !File.directory?(@xmlFile))
        @xml = @xmlTool.createHashtableFromFile(@xmlFile)
      end
      #else
      #  if(!xmlFile.endsWith(".admin"))
      #Logger.doLog(Logger.ERROR,"Error: '"+xmlFile+"' file exists:"+(new File(xmlFile).exists())+"  is Directory:"+(new File(xmlFile).isDirectory()));

    end

    # Get the XML-File to get information from
    # @return Path to xml file
    def getXmlFile
	     return @xmlFile
    end

    # Set the Hashtable to the one given
    # @param hashmap Hashtable to set
    def setXML(xml)
	    @xmlFile = "Hashtable given"
	    @xml = xml
    end

    # Get the XML-File to get information from
    # @return hashmap
    def getXML
	     return @xml
    end

    #/** don't use this function just for dummy reason
    # * @param count int
    #*/
    #public void setCount(int count){
	  #   this.count = 0;
    #}

    # returns the number of nodes found
    # @return int
    def getCount
	     return @nodeValues.size
    end

    # this parameter defines which node to give back
    # @param index index to use
    def setIndex(index)
	     @index = index
    end

    # Returns the index currently used
    # @return int
    def getIndex
	     return @index
    end

    # helper function to exchange the
    # vector to get to the wanted child nodes
    # @param nodes Vector of nodes
    # @param nextNode Name of next node
    # @return returns a revised Vector

    def traverseNodes(nodes, nextNode)
    	tVec = Array.new
    	for i in 0..nodes.size

    	    tmp = nodes[i]
    	    tmpNode = nil
    	    @xmlTool.setCountToZero()
    	    at = 0
    	    while((tmpNode = @xmlTool.getHashForNameAtPos(tmp,nextNode,at)) != nil)
        		at = at.next
        		@xmlTool.setCountToZero()
        		tVec.push(tmpNode)
    	    end
    	end
    	return tVec
    end

    # a String like ParentNode/ChildNode
    # must be set to get the wanted child nodes
    # @param node Node to use
    def setNode(node)
        if(@xml != nil)

          @node = node
          tokens = node.split("/")
          working = @xml

          if(@xmlStoreMap != nil && @xmlStoreMap != "")
              working = @xmlStore.get(@xmlStoreMap)
          elsif(@nodeValues.size > 0 && @store)
              working = @nodeValues.get(@index);
          end

          @nodeValues.clear
          localIndex = 0
          localNode = ""
          localHashNode = nil
          @xmlTool.setCountToZero()
          while((localHashNode = @xmlTool.getHashForNameAtPos(working,tokens[0],localIndex)) != nil)
              localIndex = localIndex.next
              @xmlTool.setCountToZero()
              @nodeValues << localHashNode
          end
          if(tokens.length != 1 && @nodeValues.size != nil)
              for i in 1..tokens.size
                  @nodeValues = traverseNodes(@nodeValues,tokens[i])
              end
          end
          @node = tokens[tokens.size-1];
        end
    end

    # Set the name of the Node which
    # has the Attribute to be
    # searched for
    # @param attElName Node name
    def setAttributeElement(attElName)
	     @attributeElementName = attElName
    end
    # Returns the Node name used in finding the
    # Node Attribute
    # @return Node name
    def getAttributeElement
      return @attributeElementName
    end


    # Sets the name of the Attribute to find
    # @param attributName Attribute name
    def setAttribute(attributName)
	     @attributName = attributName
    end

    # Returns the value of the Attribute found
    # @return Attribute found
    def getAttribute
    	if(@nodeValues.size > @index)
    	    tmp = @nodeValues[index]
    	    result = @xmlTool.searchForAttribute(tmp, @attributeElementName, @attributName)
    	    return result
    	else
  	    return ""
      end
    end


    # Returns a xml fragment in form of a
    # hashMap that can be used by the
    # XMLDocumentHash object.
    # @param index Index of node to return
    # @return xml fragment in hashmap form
    def retNode(index)

    	if(@nodeValues.size > index)
    	    return @nodeValues[index]
    	else
    	    return Hash.new
    	end
    end

    # use this function to get the wanted child nodes defined at setNode from the xml file
    # @return name of node used.
    def getNode(*args)
      if(args.size == 1)
        return retNode(args[0])
      else
      	if(@nodeValues.size > @index)
      	    tmp = @nodeValues[@index]
      	    retStr = @xmlTool.searchForValue(tmp,@node)
      	    return retStr
      	else
  	       return ""
        end
      end
    end

    # set a nodeElement to get from a node
    # can be in the form of node1/node2...
    # each element will be returned as called.
    # ie. node1 on the first call, node2 on the
    # second call.
    # @param nodeElement String representing the nodes.
    def setNodeElement(nodeElement)
    	nodeAt = 0
    	if(nodeElement == nil || nodeElement == "")
    	    nodeElement = ""

    	else
    	    if(nodeElement.index('/') != nil)
            @nodeElements = nodeElement.split("/")
    	    else
        		@nodeElements.clear
        		@nodeElements[0] = nodeElement
    	    end
    	end
  end


  # Combines the methods
  #    setNode()
  #    setIndex(int)
  #    setNodeElement(String)
  #    getNodeElement()
  # and returns the result in an array
  # @param node Name
  # @param index
  # @param nodeElement Element to search for
  # @return Element Array.
    def getNodeElement(node, index, nodeElement)
    	setNode(node)
    	setIndex(index)
    	setNodeElement(nodeElement)
    	returnElements = Array.new
    	for i in 0..nodeElements.size
    	    returnElements[i] = getNodeElement
    	end
    	return returnElements
    end


    #Return the number of Node Elements which have been requested
    def getNodeElementCount
        return @nodeElements.size
    end

    #Return the name of the next node element to be requested
    def getNextNodeElementName

      	if(@nodeValues.size > @index)

      	    if(@nodeAt < @nodeElements.size)
          		retStr = @nodeElements[@nodeAt];
          		return retStr.strip
      	    end
      	    return ""

      	else
      	    return ""
      	end

    end

    # get a nodeElement of a xml-tree from the node
    # @return next node
    def getNodeElement
    	if(@nodeValues.size > @index)
    	    tmp = @nodeValues[index]
    	    if(@nodeAt < @nodeElements.size)
            retStr = nil
            if(@nodeElements[@nodeAt].index(':') != nil)
                nodeName = @nodeElements[@nodeAt][0..@nodeElements[@nodeAt].index(':')-1]
                attributeName = @nodeElements[@nodeAt][ @nodeElements[@nodeAt].index(':')]
                retStr = @xmlTool.searchForAttribute(tmp, nodeName, attributeName)
            else
                retStr = @xmlTool.searchForValue(tmp,@nodeElements[@nodeAt])
            end
        		if(@nodeElements.size != 1)
        		    nodeAt = nodeAt.next
        		end
        		return retStr.strip

    	    end
    	    return ""

    	else
    	  return ""
    	end
    end


    # store the actual tree of nodes as root node
    # @param store store or not.

    def setStore(store)
	     @store = store
    end

    # Returns a boolean using store or not.
    # @return is stored?
    def getStore
	     return @store
    end

    # store the actual tree of nodes as root node
    # and in a internal map which can be called later
    # with setStoreMap()
    # @param storeName key in hashmap
    def setStoreAktiveMap(storeName)
    	if(storeName == "NULL")
    	    @xmlStoreMap = nil
    	else
    	    @xmlStore[storeName] = xml
    	    @xmlStoreMap = storeName
    	end
    end

    # Returns the name of the map in store
    # that is aktive.
    # @return Name of aktive map.
    def getStoreAktiveMap
	     return @xmlStoreMap
    end

    # Sets the node in the store represented by
    # the key 'storeName' as the root node.
    # @param storeName Name of store to use.
    def setStoreMap(storeName)
	     @xmlStoreMap = storeName
    end

    # Returns the name of the aktive map in store.
    # @return Store name
    def getStoreMap
	     return @xmlStoreMap
    end

    # Returns a xml fragment in form of a
    # hashMap that can be used by the
    # XMLDocumentHash
    # object. That is stored in the internal map
    # represented by the key 'name'
    # @param name name of stored map to return
    # @return Hashtable xml fragment.
    def getStoredHash(name)
	     return @xmlStore[name]
    end
    # Returns the aktive xml in form of a
    # hashMap that can be used by the
    # XMLDocumentHash object.
    # @return aktive xml Hash.
    def getActiveMap
	     return @xml
    end
end
