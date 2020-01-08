require_relative '../util/Parser'
require_relative '../server/file/FileCMS'
require_relative '../server/GlobalSettings'
require_relative '../object_repository/ObjectRepository'
require_relative '../object_repository/ObjectRepositoryManager'
require_relative '../object_repository/RepositoryObject'
require_relative "./XMLDocument"
require_relative "./XMLDocumentHash"
require_relative "./Tag"
require_relative "../server/net/HttpSession"


class XMLSmart

    attr_accessor :store, :xmlStoreMap, :INDEX, :attributeElementName, :XML

    @@FS = File::SEPARATOR
    @@REPOSITORY_NAME = "XMLModCache.obj"

    #Creates new XmlHelper
#    def initialize(xml)
#      @xmlDoc = xml
#      @nodeValues = []
#      @serverDataPath = GlobalSettings.getGlobal("Server-DataPath")
#    end

    def initialize(*args)

      @xmlStoreMap = nil
      @xmlTool = XMLDocumentHash.new
      @nodeValues = []
      @store = true
      @attributeElementName = nil
      @attributeName = nil
      @nodeAt = 0
      if(args.size == 2)
        initialize_2(args[0], args[1])
      else
        sess = HttpSession.new(123456)
        initialize_2(sess, "<test/>")
      end
    end

    def initialize_2(sess, xml)
      @session = sess
      @xmlDoc = xml
      @serverDataPath = GlobalSettings.getCurrentWorkArea(@session)
      @OBMANAGER = GlobalSettings.getGlobal("ActiveRepositoryLoader")
    end


    def addCacheHTML(xmlFile, html, version)
        if (version == -1)
            addCacheHTML(xmlFile, html)
        end
    end

    def addCacheHTML(xmlFile, html)
      @OBMANAGER = GlobalSettings.getGlobal("ActiveRepositoryLoader");
      @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).commitObject(Parser.replaceAll(xmlFile, "/", "-"), html, true)
    end

    def getCacheHTML(xmlFile, version)
      if  version == -1
        return getCacheHTML(xmlFile)
      end
      return nil
    end

    def getCacheHTML(xmlFile)
        @OBMANAGER = GlobalSettings.getGlobal("ActiveRepositoryLoader");
        if (@OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(Parser.replaceAllInString(@XMLFILE, "/", "-")) == nil)
            return nil
        else
            return @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(Parser.replaceAllInString(@XMLFILE, "/", "-")).getObject()
        end
    end

    def setXmlFile_2(xmlFileTmp, version)

      if (version == -1)
            setXmlFile(xmlFileTmp)
      elsif (version != -1 && @session != nil)
        fullPath = xmlFileTmp
        if xmlFileTmp.index(@serverDataPath) == nil
            fullPath = @serverDataPath + fullPath
        end

        fcms = FileCMS.new(@session, fullPath)
        fv = fcms.getVersionedFile.getVersionByNumber(version)
        if (fv != nil && fv.getThisVersion != nil)
            self.setXmlFile(fv.getThisVersion.getAbsolutePath)
        else
            self.setXmlFile(fcms.getFileURL)
        end
      end
    end

    # Set the XML-File to get information from,
    # First we look in the ATG wide component
    # ActiveRepositoryLoader for the existing
    # Hashtable corresponding to @XMLFILE, if it
    # is not there then we still need to load
    # it from the file system.
    # @param @XMLFILE Path to the file

    #def setXmlFile(xmlFileTmp)
    def setXmlFile(*args)
      if(args.size == 2)
        setXmlFile_2(args[0], args[1])
      else
        obManager = GlobalSettings.getGlobal("ActiveRepositoryLoader");
        xmlFileTmp = args[0]
        if (@XMLFILE != nil && @XMLFILE == xmlFileTmp && @XML != nil)
          #puts "returning nil....."
            return nil
        end
        @XMLFILE = args[0]
        #puts "xmlFile : #{@XMLFILE}"
        fullPath = @XMLFILE
        scndPath = "#{File.absolute_path(GlobalSettings.getDocumentWorkAreaDirectory)}#{@@FS}"
        if(scndPath == @serverDataPath)
            scndPath = "#{File.absolute_path(GlobalSettings.getDocumentDataDirectory)}#{@@FS}"
        end
        if (!(fullPath.index(@serverDataPath) != nil) && !(fullPath.index(scndPath) != nil))
            fullPath = @serverDataPath.concat(fullPath)
        end

        if (@XMLFILE.index("//") != nil)
            @XMLFILE = Parser.replaceAll(@XMLFILE, "//", "/")
        end
        if (fullPath.index("//") != nil)
            fullPath = Parser.replaceAll(fullPath, "//", "/")
        end

        fullPath = GlobalSettings.changeFilePathToMatchSystem(fullPath)

        fullPathMod = Parser.replaceAll(Parser.replaceAll(fullPath, @@FS, "-"), ":", "[")
        xmlFileMod = Parser.replaceAll(Parser.replaceAll(@XMLFILE, @@FS, "-"), ":", "[")


        #puts "Obmanager: #{@OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME)}  -- Repo name: #{@@REPOSITORY_NAME} FullPath: #{fullPathMod}"

        if (@OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME) != nil &&
            @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod) != nil &&
            (@XML = @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod).getObject()) != nil)
            if (@XML != nil || !@XML == Array.new)
                #java.io.File fTest = new java.io.File(fullPath);

                if ((File.mtime(fullPath).to_time.to_i - @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod).CREATION_DATE.to_time.to_i) > 1500)
                    xmlDoc = XMLDocument.new(fullPath, true)
                    #xmlDoc.tagToString( xmlDoc.XML_DOC[0], 0 )
                    #puts "XMLSmart Doc is a #{xmlDoc.XML_DOC.class.name}"
                    hmXML = @xmlTool.createHashtableFromXMLDocument(xmlDoc)
                    @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).removeRepositoryObject(fullPathMod)

                    #puts "1 Commiting :#{fullPathMod}"
                    @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).commitObject(fullPathMod, hmXML, true)
                    @XML = hmXML
                    File.utime(0, @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod).CREATION_DATE.to_time, fullPath)

                    GlobalSettings.clearPageModules(@session, @XMLFILE, -1)
                end

            end

        elsif (@OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME) != nil &&
               @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod) != nil &&
               (@XML = @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(xmlFileMod).getObject()) != nil)
            if (@XML != nil || !@XML == Array.new)
                #java.io.File fTest = new java.io.File(@XMLFILE);

                if ((File.mtime(@XMLFILE) - obManager.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(xmlFileMod).getCreationDate()) > 1500)
                    hmXML = @xmlTool.createHashtableFromXMLDocument(XMLDocument.new(@XMLFILE, true))
                    @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).removeRepositoryObject(xmlFileMod)
                    @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).commitObject(xmlFileMod, hmXML, true)
                    @XML = hmXML
                    File.utime(0, @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod).getCreationDate(), fullPath)
                    File.utime(0, @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(xmlFileMod).getCreationDate(), @XMLFILE)
                    GlobalSettings.clearPageModules(@session, @XMLFILE, -1)
                end
            end
        else
          #puts "FullPath : #{fullPath} exist? #{File.exist?(fullPath)}"
            if (File.exist?(fullPath) && !File.directory?(fullPath))
                #puts "Load XML..."
                @XML = @xmlTool.createHashtableFromXMLDocument(XMLDocument.new(fullPath, true))
            end
            #puts "XML: #{@XML}"
            if (@XML != nil)
                #java.io.File fTest = new java.io.File(fullPath);

                #puts "3 Commiting :#{fullPathMod}"
                @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).commitObject(fullPathMod, @XML, true)
                File.utime(0, @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod).getCreationDate().to_time, fullPath)

            else
                if (File.exist?(@XMLFILE) && !File.directory?(@XMLFILE))
                    @XML = @xmlTool.createHashtableFromXMLDocument(XMLDocument.new(@XMLFILE, true))
                    if (@XML != nil )
                        #java.io.File fTest = new java.io.File(@XMLFILE);

                        #puts "4 Commiting :#{fullPathMod}"
                        @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).commitObject(xmlFileMod, @XML, truFile.utime(0, @OBMANAGER..getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod).getCreationDate(), fullPath))
                        File.utime(0, @OBMANAGER..getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(xmlFileMod).getCreationDate().to_time, @XMLFILE)
                    end
                end
                #}
            end
        end
      end
    end

    #-------------------------------------------------------------------------------
    def isNewest(xmlFileTmp, version)
        if (version == -1)
            return self.isNewest(xmlFileTmp)
        end
        if (@session != nil)
          fullPath = xmlFileTmp
          if (fullPath.index(@serverDataPath) == nil)
              fullPath = @serverDataPath.concat(fullPath)
          end
          fcms = FileCMS.new(@session, fullPath)
          fv = fcms.getVersionedFile().getVersionByNumber(version)
          if (fv != nil && fv.getThisVersion() != nil)
              return self.isNewest(fv.getThisVersion().getAbsolutePath())
          else
              return false #this.isNewest(fv.getCurrentVersion().getAbsolutePath());
          end
        end
        return true
    end


    def isNewest(xmlFileTmp)


        @XMLFILE = xmlFileTmp
        fullPath = @XMLFILE

        if (fullPath.index(@serverDataPath) == nil)
            fullPath = @serverDataPath.cocat(fullPath)
        end
        if (@XMLFILE.index("//") != nil)
            @XMLFILE = Parser.replaceAll(@XMLFILE, "//", "/")
        end
        if (fullPath.index("//") != nil)
            fullPath = Parser.replaceAll(fullPath, "//", "/")
        end

        fullPath = GlobalSettings.changeFilePathToMatchSystem(fullPath)
        fullPathMod = Parser.replaceAll(Parser.replaceAll(fullPath, @FS, "-"), ":", "[")
        xmlFileMod = Parser.replaceAll(Parser.replaceAll(@XMLFILE, @FS, "-"), ":", "[")

        if (@XML != nil && @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod) != nil &&
          (@XML = @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(fullPathMod).getObject()) != nil)
            if (@XML != nil)


                if ((File.mtime(fullPath).to_time.to_i - @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getObject(fullPathMod).CREATION_DATE.to_time.to_i) > 1500)
                    return false
                else
                    return true
                end
            end
        elsif (@XML != nil && @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(xmlFileMod) != nil && (@XML = @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(xmlFileMod).getObject()) != nil)
            if (@XML != nil) #|| !@XML.equals(new Hashtable()))

                if ((File.mtime(@XMLFILE).to_time.to_i - @OBMANAGER.getObjectRepsoitory(@@REPOSITORY_NAME).getRepositoryObject(xmlFileMod).CREATION_DATE.to_time.to_i) > 1500)
                    return false
                else
                    return true
                end
            end
        else
            return false
        end

        return false
    end


    def getXmlFile
        return @XMLFILE
    end

    def setXML(xml)
        @XMLFILE = "Hashtable given";
        @XML = xml
    end


    def getXML
        return @XML
    end

    # TO-DO: Figure out if this is needed...
    # returns the number of nodes found
    # @return int

    def getCount
        return @nodeValues.size
    end


    # helper function to exchange the
    # vector to get to the wanted child nodes
    # @param nodes Vector of nodes
    # @param nextNode Name of next node
    # @return returns a revised Vector
    # TO-DO: make private
    def traverseNodes(nodes, nextNode)
        tVec = Array.new
        #puts "***********************\ntraverseNodes :#{nextNode} \n_______________________________\n#{nodes}\n***********************************"
        for i in 0..nodes.size
            tmp = nodes[i]
            @xmlTool.setCountToZero()
            at = 0
            #tmpNode = @xmlTool.getHashForNameAtPos(tmp, nextNode, at)
            while ((tmpNode =@xmlTool.getHashForNameAtPos(tmp, nextNode, at) )!= nil)
                at = at.next
                @xmlTool.setCountToZero()
                tVec.push(tmpNode) # alternative is tVec.push(tmpNode)
                #tmpNode = @xmlTool.getHashForNameAtPos(tmp, nextNode, at)
            end
        end
        return tVec
    end



    # a String like ParentNode/ChildNode
    # must be set to get the wanted child nodes
    # @param node Node to use

    def setNode(node)
        #puts "----setNode --1 #{node}"
        if (@XML != nil)
            #puts "----setNode --2"
            @node = node
            tokens = node.split("/")
            #puts "setNode... tokens : #{tokens}"
            working = @XML
            #puts "Working ----- #{@nodeValues}"
            #puts "\n\n\n------->>>xmlStore count:#{@xmlStore.size}"
            #if (@xmlStoreMap != nil && @xmlStoreMap != "")
            #    working = @xmlStore[@xmlStoreMap]
                #puts "\n\n\n1------->>>working:#{working}"
            #elsif (@nodeValues.size > 0 && @store)
            #    working = @nodeValues[@INDEX]
                #puts "\n\n\n2------->>>working:#{@nodeValues}"
            #end

            @nodeValues.clear
            localIndex = 0
            localNode = ""
            #localHashNode = nil
            #puts "Working : #{tokens[0]}   ------\n#{working}"
            localHashNode = @xmlTool.getHashForNameAtPos(working, tokens[0], localIndex)
            #puts "LocalHash :#{localIndex}  :: #{tokens[0]}:\n--------------\n#{localHashNode}\n--------------------------\n"
            @xmlTool.setCountToZero
            while ((localHashNode = @xmlTool.getHashForNameAtPos(working, tokens[0], localIndex)) != nil)
                localIndex = localIndex.next
                @xmlTool.setCountToZero
                @nodeValues << localHashNode
                #localHashNode = @xmlTool.getHashForNameAtPos(working, tokens[0], localIndex)
                #puts "LocalHash :#{localIndex}  :: #{tokens[0]}:\n--------------\n#{localHashNode}\n--------------------------\n"
            end
            #puts "Tokens: #{tokens} #{@nodeValues}"
            if (tokens.size != 1 && @nodeValues.size > 0)
                for i in 0..(tokens.size-1)
                  #puts "About to traverseNodes... #{i} #{tokens[i]}"
                  tmpNodes = traverseNodes(@nodeValues, tokens[i])
                  #puts "TMP Nodes : #{tmpNodes}"
                  #if(tmpNodes != nil && tmpNodes.size > 0)
                    @nodeValues = tmpNodes
                  #end
                  #puts "Found Nodes : #{@nodeValues}"
                end
            end
            @node = tokens[tokens.size - 1]
            #puts "Finished Node : #{@nodeValues}"
        end
    end


    # Sets the name of the Attribute to find
    # @param attributeName Attribute name

    def setAttribute(attributeName)
        @attributeName = attributeName
    end

    # Returns the value of the Attribute found
    # @return Attribute found

    def getAttribute
        if (@nodeValues.size > @INDEX)
            tmp = @nodeValues[@INDEX]
            result = @xmlTool.searchForAttribute(tmp, @attributeElementName, @attributeName)
            return result
        else
            return ""
        end

    end

    # Returns a xml fragment in form of a
    # hashMap that can be used by the
    # XMLDocumentHash
    # object.
    # @param index Index of node to return
    # @return xml fragment in @XML form

    def retNode(index)
      #puts "Node Values: #{@nodeValues}"
        if (@nodeValues.size > index)
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
        if (@nodeValues.size > @INDEX)
            tmp = @nodeValues[@INDEX]
            #puts "----------------\nSearch For #{@node}\n#{tmp}\n--------------------------"
            retStr = @xmlTool.searchForValue(tmp, @node)
            #puts "----------------\nSearch For #{@node}\n#{retStr}\n--------------------------"
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
        @nodeElements = Array.new
        nodeAt = 0
        if (nodeElement == nil || nodeElement =="")
            @nodeElement = ""
        else
            if (nodeElement.index('/') != nil)
                @nodeElements = nodeElement.split("/")
            else
                @nodeElements = Array.new
                @nodeElements[0] = nodeElement
            end
       end
       #puts "Node Elements to search for: #{@nodeElements}"
    end

    def getNodeElement(*args)
      if(args.size == 0)
        return getNodeElement_0
      elsif(args.size == 3)

        return getNodeElement_3(args[0], args[1], args[2])
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



    def getNodeElement_3(node, index, nodeElement)

        #puts "---------getNodeElement_3 #{node}, #{index}, #{nodeElement}"
        @nodeAt = 0
        setNode(node)
        @INDEX = index #setIndex(index)
        setNodeElement(nodeElement)
        returnElements = Array.new
        #puts "Return Elements : #{@nodeElements.size}"
        if(@nodeElements != nil)
          for i in 0..@nodeElements.size
              returnElements[i] = getNodeElement_0
          end
        end
        return returnElements
    end

    #Return the number of Node Elements which have been requested
    def getNodeElementCount
        return @nodeElements.size
    end

    #Return the name of the next node element to be requested
    def getNextNodeElementName
        if (@nodeValues.size > @INDEX)
            if (@nodeAt < @nodeElements.size)
                retStr = @nodeElements[@nodeAt]
                return retStr.strip
            end
            return ""
       else
            return ""
       end
    end

    # get a nodeElement of a xml-tree from the node
    # @return next node
    def getNodeElement_0
        #puts "--->1 #{@nodeValues} : INDEX #{@INDEX} NodeAt: #{@nodeAt}"
        if (@nodeValues.size > @INDEX)
            tmp = @nodeValues[@INDEX]
            if (@nodeAt < @nodeElements.size)
                retStr = ""
                #puts "---->1 #{@nodeElements[@nodeAt]}"
                if (@nodeElements[@nodeAt].index(':') != nil)
                    @nodeName = @nodeElements[@nodeAt][0..@nodeElements[@nodeAt].index(':')]
                    @attributeName = @nodeElements[@nodeAt][@nodeElements[@nodeAt].index(':') + 1];
                    retStr = @xmlTool.searchForAttribute(tmp, @nodeName, @attributeName)
                else
                    #puts "Searching for : #{@nodeElements[@nodeAt]}"
                    retStr = @xmlTool.searchForValue(tmp, @nodeElements[@nodeAt])
                end
                if (@nodeElements.size != 1)
                    @nodeAt = @nodeAt.next
                end
                if(retStr.is_a? String)
                  return retStr.strip
                else
                  return retStr
                end
            end
            return ""
        else
            return ""
        end
    end

    def setIndex(index)
      @INDEX = index
    end
    def getIndex
      return @INDEX
    end

    # store the actual tree of nodes as root node
    # and in a internal map which can be called later
    # with setStoreMap()
    # @param storeName key in @XML
    def setStoreAktiveMap(storeName)
        if (storeName == "NULL")
            @xmlStoreMap = nil
        else
            @xmlStore[storeName] = @XML
            @xmlStoreMap = storeName
        end
    end

    # Returns the name of the map in store
    # that is aktive.
    # @return Name of aktive map.
    def getStoreAktiveMap
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
    # XMLDocumentHash
    # object.
    # @return aktive xml Hash.
    def getActiveMap
        return @XML
    end
end
