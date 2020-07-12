
class EmailUser

    attr_accessor :FNAME, :LNAME, :EMAIL, :TELEPHONE, :COMPANY, :DOB, :ACCEPTS_EMAILS
    attr_reader :ID, :USER_PARAMS


    # Creates a new instance of EmailUser
    def initialize(id, fName, lName, email, telephone, dob, company, userParams, willAcceptEmails)

        @ID = id
        @FNAME = fName
        if(@FNAME == nil)
          @FNAME = "Not Provided"
        end
        @LNAME = lName
        if(@LNAME == nil)
          @LNAME = "Not Provided"
        @EMAIL = email
        @TELEPHONE = telephone
        if(@TELEPHONE == nil)
          @TELEPHONE = "Not Provided"
        end
        @DOB = dob
        @COMPANY = company
        if(@COMPANY == nil)
          @COMPANY = "Not Provided"
        end

        @USER_PARAMS = userParams
        @ACCEPTS_EMAILS = willAcceptEmails
    end


    def containsParam(key)
        return @USER_PARAMS.key?(key)
    end

    def paramHasMultipleValues(key)
        return (@USER_PARAMS.key?(key) && @USER_PARAMS[key].instance_of? Array)
    end

    def getParamAtIndex(key, index)

      if(@USER_PARAMS.key?(key) && @USER_PARAMS[key].instance_of? Array)
          return @USER_PARAMS[key][index]
      else
          return nil
      end
    end

    def getParam(key)
        return @USER_PARAMS[key]
    end

end
