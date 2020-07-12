require_relative './xml/XMLSmart'
require_relative './xml/XMLSmartClient'
require_relative './xml/XMLDocumentHash'
require_relative './util/PropertyLoader'
require_relative './server/GlobalSettings'

class PageModule

    attr_reader :isVisible, :moduleID
    @descriptor = ""
    @isVisible = false
    @moduleID = 0
    @moduleIDS = ""
    @nodeType = ""
    @moduleName = ""
    @contentBlock = ""
    @index = -1

    # Creates a new instance of PageModule
    def initialize(descrip)
        @xmlHelper = XMLSmart.new
        @xmlWorker = XMLDocumentHash.new
        @modDataHash = Hash.new

        #puts "Modules to load : #{GlobalSettings.getGlobal("modules")}"
        @modules = PropertyLoader.new(GlobalSettings.getGlobal("modules"))

        #puts descrip

        @descriptor = descrip #@xmlWorker.getChildNode(descrip, 0)
        #@descriptor = @xmlWorker.getChildNode(descrip, 0)
        #puts "Descriptor : #{@descriptor}"
        @xmlHelper.setXML(@descriptor)

        vis = @xmlWorker.searchForValue(@descriptor, "visible")
        #puts "Visible : #{vis}"
        if(vis == @xmlWorker.NOT_FOUND)
            @isVisible = true
        else
            @isVisible = (vis == "true")
        end
        @moduleIDS = @xmlWorker.searchForValue(@descriptor,"id")
        @moduleID = @moduleIDS.to_i

        @contentBlock = @xmlWorker.searchForValue(@descriptor,"content_block")
        if(@contentBlock == @xmlWorker.NOT_FOUND)
            @contentBlock = nil
        end



        hmTmp = @xmlWorker.getChildNode(@descriptor,0)
        #puts "hmTmp : #{hmTmp}"
        @nodeType = @xmlWorker.getNodeName(@descriptor)
        #puts "Node Type : #{@nodeType}"
        @moduleName = @xmlWorker.searchForValue(@descriptor,"descriptive_name")#@xmlWorker.getNodeName(@descriptor)
        #puts "Module Name : #{@moduleName}"


        xmlHelperMod = XMLSmart.new
        xmlHelperMod.setXML(@descriptor) #Load xml Data
        modData = 0
        #puts "Module ID :#{@moduleIDS}"
        #puts "Loading mod data :#{@modules.getProperty(@nodeType,"xmlParentNode_#{modData}")}"
        while(@modules.getProperty(@nodeType, "xmlParentNode_#{modData}") != nil)

            xmlHelperMod.setNode(@modules.getProperty(@nodeType,"xmlParentNode_#{modData}"))    #Select the correct module
            xmlHelperMod.setIndex(0)
            xmlHelperMod.setNodeElement("id")
            at = 0
            for j in 0..xmlHelperMod.getCount()

                xmlHelperMod.setIndex(j)
                idSt = xmlHelperMod.getNodeElement()
                if(xmlHelperMod.getNodeElement() == @moduleIDS)
                    at = j
                    #puts "Found Module at: #{j}"
                end
            end
            #puts "Setting INDEX to: #{at}"
            xmlHelperMod.setIndex(at)

            #puts "=====================================\nMod Data #{modData} has multiple entries? #{@modules.getProperty(@nodeType,"xmlDataMultiple_#{modData}")}\n====================================="
            multiData = @modules.getProperty(@nodeType,"xmlDataMultiple_#{modData}")
            #puts "MultiData : #{multiData}"
            #at = 0
            if(multiData)

                tmpSm = XMLSmartClient.new
                #xmlHelperMod.setNode(@modules.getProperty(@nodeType,"xmlParentNode_#{modData}"))    #Select the correct module
                #xmlHelperMod.setIndex(0)
                nextNode = xmlHelperMod.getNode(at)
                #puts "MultiData Node: #{at} : #{nextNode}"
                tmpSm.setXML(nextNode)
                tmpSm.setNode(@modules.getProperty(@nodeType,"xmlParentNodeMultiple_#{modData}"))
                countDMod = tmpSm.getCount
                vData = Array.new
                for j in 0..countDMod-1

                    tmpSm.setIndex(j)

                    tmpSm.setNodeElement(@modules.getProperty(@nodeType,"xmlDataToLoad_#{modData}"))
                    htDataTmp = Hash.new
                    #puts "------HELP-----\n#{@modules.getProperty(@nodeType,"xmlDataToLoad_#{modData}")}\n#{tmpSm.getNodeElementCount}"
                    for k in 0..tmpSm.getNodeElementCount-1

                        nodeName = tmpSm.getNextNodeElementName
                        #puts "NodeName : #{nodeName}"
                        workon = tmpSm.getNodeElement
                        htDataTmp[nodeName] = workon if nodeName.strip != ""
                        #puts "----------->>>>>>-------\n\n#{htDataTmp}\n\n---------------------<<<<<<<<<<<-----------------"
                    end
                    #puts "\n-------END--------"
                    vData << htDataTmp if htDataTmp.keys.size > 0
                end
                @modDataHash[@modules.getProperty(@nodeType,"xmlSessionId_#{modData}")] = vData

            else

                xmlHelperMod.setNodeElement(@modules.getProperty(@nodeType,"xmlDataToLoad_#{modData}"))
                htDataTmp = Hash.new
                for k in 0..xmlHelperMod.getNodeElementCount()
                    htDataTmp[xmlHelperMod.getNextNodeElementName()] = xmlHelperMod.getNodeElement()
                end
                @modDataHash[@modules.getProperty(@nodeType,"xmlSessionId_#{modData}")] = htDataTmp
                #puts @modDataHash
            end
            modData = modData.next
        end

    end

    def getModuleName
        return @moduleName
    end

    def getIndex
        return @index
    end

    def setIndex(index)
        @index = index
    end

    def getModuleData
        return @modDataHash
    end

    def getModuleType
        return @nodeType
    end

    def getID
        return @moduleID
    end

    def getContentBlock
        return @contentBlock
    end

    def isVisible
        return @isVisible
    end

    def getModuleDescriptor
        return @descriptor
    end

    def toString

        ret = "---------------Page Module START-------------------------\n"
        ret.concat("\t")
        ret.concat("Type :#{getModuleType}")
        ret.concat("\n")
        ret.concat("\t")
        ret.concat("ID :#{getID}")
        ret.concat("\n")
        ret.concat("\t")
        ret.concat("\t")
        ret.concat("Is Visible :#{isVisible}")
        ret.concat("\n")
        ret.concat("---------------Page Module END--------------------------\n")
        return ret
    end
end
