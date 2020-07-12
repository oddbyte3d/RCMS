require_relative "../file/FileCMS"

class WorkFlow


    class << self
      @@WORKFLOW_TYPE_FILE_DELETED = 0
      @@WORKFLOW_TYPE_FILE_PUBLISH = 1
      @@WORKFLOW_TYPE_WORK_TODO = 2
      @@STEP_WORK = 0
      @@STEP_REVIEW = 1
      @@STEP_APPROVE = 2
      @@STEP_PUBLISH = 3
      @@STEP_DONE = 4
      @@steps = {WorkFlow.STEP_WORK, WorkFlow.STEP_REVIEW, WorkFlow.STEP_APPROVE, WorkFlow.STEP_PUBLISH, WorkFlow.STEP_DONE}
    end
    #private int myType;
    #private int currentStep = 0;
    #private ArrayList<FileAction> relatedFiles;

    def initialize(type, relatedFiles)
        @myType = type
        if @relatedFiles.is_a? Array
          @relatedFiles = relatedFiles
        else
          @relatedFiles = {relatedFile}
        end
    end


    def getCurrentStep
        if(@currentStep < @@steps.size)
          return @@steps[@currentStep]
        else
          return -1
        end
    end

    def step
        @currentStep = @currentStep.next
    end

    def isDone
        return @currentStep == WorkFlow.STEP_DONE
    end
end
