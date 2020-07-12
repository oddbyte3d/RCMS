require_relative "../../util/PropertyLoader"
require_relative "../GlobalSettings"
require_relative "../template/Template"
require_relative "../net/HttpSession"

class Task



    attr_accessor :STATUS_NEW, :STATUS_OPEN, :STATUS_WORKING, :STATUS_COMPLETED, :SORT_DUEDATE,
    :SORT_NAME, :SORT_DESCRIPTION, :SORT_STATUS

#    def initialize(CuppaUser creator, Date dueDate, String taskName, String taskDescription,
#            ArrayList relatedFiles, boolean notifyEmail, boolean canReject,
#            int taskIdFallBackOnReject, boolean canCancel, boolean notifyOnCancel,
#            String notifyUserOnCancel) {


    def initialize(creator, dueDate, taskName, taskDescription, relatedFiles, notifyEmail,
            canReject, taskIdFallBackOnReject, canCancel, notifyOnCancel, notifyUserOnCancel)

        @STATUS_NEW = 0
        @STATUS_OPEN = 1
        @STATUS_WORKING = 2
        @STATUS_COMPLETED = 3
        @SORT_DUEDATE = 0
        @SORT_NAME = 1
        @SORT_DESCRIPTION = 2
        @SORT_STATUS = 3
        @idchars = ['1','2','3','4','5','6','7','8','9','0']
        @FS = File::SEPARATOR
        parentProperyFile = GlobalSettings.getGlobal("Parent-PropertyFile")
        @properties = PropertyLoader.new(parentProperyFile)
        @sortBy = @SORT_DUEDATE
        @createdBy = creator.USER_NAME
        @dueDate = dueDate
        @taskDescription = taskDescription
        @taskName = taskName
        generateTaskId(taskName)
        @relatedFiles = relatedFiles
        @notifyEmail = notifyEmail
        @canReject = canReject
        @taskIdFallBackOnReject = taskIdFallBackOnReject
        @canCancel = canCancel
        @notifyOnCancel = notifyOnCancel
        @notifyUserOnCancel = notifyUserOnCancel
        setStatus(@STATUS_NEW)
    end


    def assignUser(assignedUser)
        @assignedUser = assignedUser
    end


    def setWorkflowId( workFlowId)
        @workFlowId = workFlowId
    end

    def assignToGroup(assignedGroup)
        @assignedGroup = assignedGroup
    end

    def getCreator
        return RCMSUser.new(@createdBy)
    end

    def addComment(comment)

        if @comments.is_a? String
          @comments = Comment.new(getCreator, comment)
        end
        if @comments == nil
          @comments = Array.new
        end
        @comments << comment
    end

    def commentCount
        if @comments == nil
            return 0
        else
            return @comments.size
        end
    end

    def getComment(index)
        if @comments != nil
            return comments[index]
        else
            return nil
        end
    end

    def getSortBy
        return @sortBy
    end

    def setSortBy(sortBy)
        @sortBy = sortBy
    end

    def generateTaskId(taskName)
        @taskId = taskName + Array.new(9) { @idchars.sample }.join
    end

    def getAssignedGroup
        return @assignedGroup
    end

    def getAssignedUser
        return @assignedUser
    end

    def canCancel?
        return @canCancel
    end

    def canReject?
        return @canReject
    end

    def getDueDate
        return @dueDate
    end

    def notifyEmail?
        return @notifyEmail
    end

    def notifyOnCancel?
        return @notifyOnCancel
    end

    def getNotifyUserOnCancel
        return @notifyUserOnCancel
    end

    def getPercentDone
        return @percent_done
    end

    def getRelatedFiles
        return @relatedFiles
    end

    def getStatus
        return @status
    end

    def getTaskId
        return @taskId
    end

    def getTaskIdFallBackOnReject
        return @taskIdFallBackOnReject
    end

    def getWorkFlowId
        return @workFlowId
    end

    def setCanCancel(canCancel)
        @canCancel = canCancel
    end

    def setCanReject(canReject)
        @canReject = canReject
    end

    def setDueDate(dueDate)
        @dueDate = dueDate
    end

    def setNotifyEmail(notifyEmail)
        @notifyEmail = notifyEmail
    end

    def setNotifyOnCancel(notifyOnCancel)
        @notifyOnCancel = notifyOnCancel
    end

    def setNotifyUserOnCancel(notifyUserOnCancel)
        @notifyUserOnCancel = notifyUserOnCancel
    end

    def setPercentDone(percent_done)
        @percent_done = percent_done
    end

    def setRelatedFiles(relatedFiles)
        @relatedFiles = relatedFiles
    end

    def setStatus(status)
      puts "Set Status : #{status == @STATUS_NEW}"
        if(status == @STATUS_NEW || status == @STATUS_COMPLETED || status == @STATUS_OPEN || status == @STATUS_WORKING)
            @status = status
            #puts "Setting status to: #{getStatusString}"

            session = HttpSession.new(HttpSession.generate_code(12))
            #cWorkArea = GlobalSettings.getCurrentWorkArea(session)
            docDataDir = GlobalSettings.getDocumentDataDirectory
            templateDir = "#{docDataDir}#{@FS}system#{@FS}templates#{@FS}Email/tasks/"
            user = RCMSUser.new(@createdBy)

            #puts "notifyUserOnCancel:"+notifyUserOnCancel+" "+(this.status == Task.STATUS_COMPLETED)+" "+(this.notifyEmail)+" "+(this.notifyUserOnCancel));
            if(@status == @STATUS_NEW && @notifyEmail && @assignedUser != nil)
                from = "rcms@"+GlobalSettings.getGlobal("Domain")
                puts "From: #{from}"
                params = Hash.new
                params["domain"] = GlobalSettings.getGlobal("Domain")
                fields = user.getUserFields
                puts "Fields : #{fields}"
                fields.each{ |key|
                  puts "Key : #{key}"
                  params[key] = "#{user.getUserField(key)}"
                }

                path = GlobalSettings.changeFilePathToMatchSystem(GlobalSettings.getDocumentConfigDirectory()+
                        "Comment.java");

                myPage = FileCMS.new(session, path)
                page = Page.new(myPage, -1, session, myPage.getFileURL)
                myTemplate = Template.new(templateDir, page)
                myTemplate.setAdditionalParameters(params)
                email = myTemplate.getParsedTemplate
                #email = ""#PrepareEmailTemplate.prepareEmailUserTemplate(template, new CuppaUser(this.assignedUser), params);
                puts "Sending email: #{email}"
                #GlobalSettings.getMailer().sendMail(from, new String[]{new CuppaUser(this.assignedUser).getUserEmail()}, "You have a new task.", email, new File[0], MailSend.PRIORITY_HIGH, true);
            elsif(@status == @STATUS_COMPLETED && @notifyUserOnCancel != nil)
                from = "rcms@"+GlobalSettings.getGlobal("Domain")
                puts "From: #{from}"
                params = Hash.new
                params["domain"] = GlobalSettings.getGlobal("Domain")
                path = GlobalSettings.changeFilePathToMatchSystem(GlobalSettings.getDocumentConfigDirectory()+
                        "Comment.java")
                myPage = FileCMS.new(session, path)
                page = Page.new(myPage, -1, session, myPage.getFileURL)
                myTemplate = Template.new(templateDir, page)
                email = myTemplate.getParsedTemplate
              puts "Sending email: #{email}"
                #GlobalSettings.getMailer().sendMail(from, new String[]{new CuppaUser(this.notifyUserOnCancel).getUserEmail()}, "Task Complete.", email, new File[0], MailSend.PRIORITY_HIGH, true);

            end
        end
    end

    def getName
        return @taskName
    end

    def getDescription
        return @taskDescription
    end

    def getStatusString
      puts "getStatus : #{@status}"
        case(@status)
        when @STATUS_COMPLETED
            return "Completed"
          when @STATUS_OPEN
            return "Open"
          when @STATUS_WORKING
            return "In Progress"
          when @STATUS_NEW
            return "New"
        end
        return "Unknown status"
    end

    def setTaskIdFallBackOnReject(taskIdFallBackOnReject)
        @taskIdFallBackOnReject = taskIdFallBackOnReject
    end

#    def =(o)
#        if(o instanceof Task)
#            case(sortBy)
#
#              when Task.SORT_DUEDATE
#                return @dueDate <=> o.getDueDate
#              when Task.SORT_NAME
#                return @taskName == o.getName
#              when Task.SORT_DESCRIPTION
#                return @taskDescription == o.getDescription
#              when Task.SORT_STATUS
#                if o.getStatus == @status
#                    return 0
#                elsif(@status == Task.STATUS_COMPLETED || ((@status == Task.STATUS_NEW || @status == Task.STATUS_OPEN || @status == Task.STATUS_WORKING) &&
#                        o.getStatus == Task.STATUS_COMPLETED))
#                    return -1
#                end
#            end
#        end
#        return -1
#    end


end
