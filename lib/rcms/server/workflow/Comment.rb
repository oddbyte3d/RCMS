require "date"

class Comment

    def initialize(submitter, comment)
        @submitter = submitter
        @comment = comment
        @dateSubmitted = Date.new
    end

    def getSubmissionDate
        return @dateSubmitted
    end

    def getComment
        return @comment
    end

    def getSubmitter
        return @submitter
    end
end
