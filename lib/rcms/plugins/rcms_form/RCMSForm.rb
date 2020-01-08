
#import java.util.*;
#import com.cuppait.cuppaweb.cuppaform.actionmods.CuppaFormAction;
#import com.cuppait.cuppaweb.cuppaform.actionmods.CuppaFormExtraField;
#import de.codefactor.util.parser;
#import de.codefactor.xml.dxml.XMLSmart;
#import de.codefactor.xml.dxml.XMLSmartClient;
#import de.codefactor.xml.dxml.parser.XMLDocumentHash;
#import de.codefactor.instantsite.security.AccessControler;
require_relative '../../xml/XMLDocumentHash'
require_relative '../../xml/XMLSmart'
require_relative '../../xml/XMLSmartClient'
require_relative '../../server/file/exception/FileNotFound'


class RCMSForm

    #private Hashtable cuppaFormDescriptor;
    #private Vector requiredFields = new Vector();
    #private XMLDocumentHash xmlDoc = new XMLDocumentHash();
    #private String extraFields[] = null;
    #private String userName = null;
    #private Properties userProperties = new Properties();
    #private Hashtable parameters = null;
    #private String myAction;

    # Creates a new instance of RCMSForm
    def initialize(descriptorFile)

      @XMLDoc = XMLDocumentHash.new
      if descriptorFile.is_a? Hash
        @FormDescriptor = descriptorFile
      elsif descriptorFile.is_a? String
        @FormDescriptor = @xmlDoc.createHashtableFromFile(descriptorFile)
        if @FormDescriptor == nil
          raise FileNotFound.new("File not found : #{descriptorFile}")
        end
      end
    end


    def setAction(action)
        @myAction = action
    end

    def getAction
        return @myAction
    end

    def setParameters(params)
        @parameters = params
    end

    def getParameters
        return @parameters
    end

    def setUserProperties(props)
        @userProperties = props
    end

    def getUserProperties
        return @userProperties
    end

    def setUserName(userName)
        @userName = userName
    end

    def getUserName
        return @userName
    end

    def getXML
        xml = "<FORM><ID>"
        xml.concat(getId)
        xml.concat("</ID><NAME><![CDATA[")
        xml.concat(getName)
        xml.concat("]]></NAME><DISPLAY_NAME><![CDATA[")
        xml.concat(getDisplayName)
        xml.concat("]]></DISPLAY_NAME><SUBMIT_VALUE><![CDATA[")
        xml.concat(getSubmitValue)
        xml.concat("]]></SUBMIT_VALUE><SHOW_AFTER_SUBMIT><![CDATA[")
        xml.concat(showAfterSubmit)
        xml.concat("]]></SHOW_AFTER_SUBMIT><RETURN_MESSAGE><![CDATA[")
        xml.concat(getReturnMessage)
        xml.concat("]]></RETURN_MESSAGE><RETURN_ERROR><![CDATA[")
        xml.concat(getErrorMessage)
        xml.concat("]]></RETURN_ERROR><DESCRIPTION><![CDATA[")
        xml.concat(getDescription)
        xml.concat("]]></DESCRIPTION><HANDLER>")
        length = getFormHandlers.size
        at = 0
        getHandlers().each{ |formHandler|
            at = at.next
            xml.concat(formHandler.class.name)
            xml.concat(":") if at<length
        }
        xml.concat("</HANDLER><PAGES>");
        for i in 0..getPageCount
          xml.concat(getPage(i).getXML)
        end
        xml.concat("</PAGES></FORM>")

        return xml
    end

    def getPageCount
        formSmart = XMLSmartClient.new
        formSmart.setHashtable(@FormDescriptor)
        formSmart.setNode("PAGE/")
        return formSmart.getCount
    end

    def getPage(index)
        @XMLDoc.setCountToZero
        page = @XMLDoc.getHashForNameAtPos(@FormDescriptor, "PAGE", index)
        @XMLDoc.setCountToZero
        return FormPage.new(page, index)
    end

    def getId
        formSmart = XMLSmartClient.new
        formSmart.setHashtable(@FormDescriptor)
        formData = formSmart.getNodeElement("FORM",0,"ID/")
        return formData[0].to_i
    end

    def getName
        formSmart = XMLSmartClient.new
        formSmart.setHashtable(@FormDescriptor)
        formData = formSmart.getNodeElement("FORM",0,"NAME/")
        return formData[0]
    end

    def getDisplayName
      formSmart = XMLSmartClient.new
      formSmart.setHashtable(@FormDescriptor)
      formData = formSmart.getNodeElement("FORM",0,"DISPLAY_NAME/")
      return formData[0]
    end


    def getDescription
      formSmart = XMLSmartClient.new
      formSmart.setHashtable(@FormDescriptor)
      formData = formSmart.getNodeElement("FORM",0,"DESCRIPTION/")
      return formData[0]
    end

    def getReturnMessage
      formSmart = XMLSmartClient.new
      formSmart.setHashtable(@FormDescriptor)
      formData = formSmart.getNodeElement("FORM",0,"RETURN_MESSAGE/")
      return formData[0]
    end

    def getErrorMessage
      formSmart = XMLSmartClient.new
      formSmart.setHashtable(@FormDescriptor)
      formData = formSmart.getNodeElement("FORM",0,"RETURN_ERROR/")
      return formData[0]
    end

    def getSubmitValue
      formSmart = XMLSmartClient.new
      formSmart.setHashtable(@FormDescriptor)
      formData = formSmart.getNodeElement("FORM",0,"SUBMIT_VALUE/")
      return formData[0]
    end

    def showAfterSubmit
      formSmart = XMLSmartClient.new
      formSmart.setHashtable(@FormDescriptor)
      formData = formSmart.getNodeElement("FORM",0,"SHOW_AFTER_SUBMIT/")
      return formData[0]
    end

    def getHandlers

        formSmart = XMLSmartClient.new
        formSmart.setHashtable(@FormDescriptor)
        formData = formSmart.getNodeElement("FORM",0,"HANDLER/")
        formHandlers = formData[0]
        actionForm = nil
        handlersSt = formHandlers.split(",")
        handlers = Array.new
        handlersSt.each{ |handle|

          className = handle[handle.rindex("/")+1..handle.size]
          require_relative(handle)
          obFilter = Kernel.const_get(className).new() #Need to define BaseHandler class


        }
        return handlers
    end


    def getExtraFields

        handlers = getFormHandlers
        fields = Array.new
        handlers.each{ |handle|
          tmpList = handle.getActionFields
          fields + tmpList
        }
        return fields
    end

    def getExtraFieldsMarkup(fields)


        String returnFields[] = new String[fields.length];
        for(int i = 0; i < fields.length; i++)
        {
            String field = "";
            switch(fields[i].getType())
            {
                case FormField.TYPE_HIDDEN:
                    field = "<input class='ok' type='hidden' name='"+fields[i].getName()+"'";
                    if(fields[i].getValue() != null)
                        field += " value='"+fields[i].getValue()+"'";
                    else if(parameters.containsKey(fields[i].getName()))
                        field += " value='"+parameters.get(fields[i].getName())+"'";
                    field += "/>";
                    break;
                case FormField.TYPE_TEXT:
                    field = "<input class='ok' type='text' name='"+fields[i].getName()+"'";
                    if(fields[i].getValue() != null)
                        field += " value='"+fields[i].getValue()+"'";
                    else if(parameters.containsKey(fields[i].getName()))
                        field += " value='"+parameters.get(fields[i].getName())+"'";
                    field += "/>";
                    break;
                case FormField.TYPE_RADIO:
                    field = "<input class='ok' type='radio' name='"+fields[i].getName()+"'";
                    if(fields[i].getValue() != null)
                        field += " value='"+fields[i].getValue()+"'";
                    else if(parameters.containsKey(fields[i].getName()))
                        field += " value='"+parameters.get(fields[i].getName())+"'";
                    field += "/>";
                    break;
                case FormField.TYPE_CHECKBOX:
                    field = "<input class='ok' type='checkbox' name='"+fields[i].getName()+"'";
                    if(fields[i].getValue() != null)
                        field += " value='"+fields[i].getValue()+"'";
                    else if(parameters.containsKey(fields[i].getName()))
                        field += " value='"+parameters.get(fields[i].getName())+"'";
                    field += "/>";
                    break;
                case FormField.TYPE_LIST:
                    field = "<select class='ok' name='"+fields[i].getName()+"'>";
                    if(fields[i].getValue() != null)
                    {
                        Vector values = fields[i].getMultipleValues();
                        for(int j = 0; j < values.size(); j++)
                        {
                            Hashtable option = (Hashtable)values.get(j);
                            if(option.containsKey("value") && option.containsKey("display_value"))
                                field += "<option value='"+option.get("value")+"'>"+option.get("display_value")+"</option>";
                            else if(option.containsKey("value") && !option.containsKey("display_value"))
                                field += "<option value='"+option.get("value")+"'>"+option.get("value")+"</option>";
                            else if(!option.containsKey("value") && option.containsKey("display_value"))
                                field += "<option value='"+option.get("display_value")+"'>"+option.get("display_value")+"</option>";
                            else
                                field = "";
                        }
                    }
                    else if(parameters.containsKey(fields[i].getName()))
                    {
                        Vector values = (Vector)parameters.get(fields[i].getName());
                        for(int j = 0; j < values.size(); j++)
                            field += "<option>"+values.get(j)+"</option>";
                    }
                    field += "</select>";
                    break;
                case FormField.TYPE_TEXTAREA:
                    field = "<textarea class='ok' name='"+fields[i].getName()+"'>";
                    if(fields[i].getValue() != null)
                        field += (String)fields[i].getValue();
                    else if(parameters.containsKey(fields[i].getName()))
                        field += (String)parameters.get(fields[i].getName());
                    field += "</textarea>";
                    break;

            }
            returnFields[i] = field;
        }
        return returnFields;
    end

end
