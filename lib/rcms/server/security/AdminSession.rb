#import java.security.SecureRandom;
#import java.math.*;

class AdminSession

#    private static HashMap hmSession = new HashMap();
#    private static SecureRandom rand = new SecureRandom();//SecureRandom.getInstance("BBS");


#    private static AdminSessionTimer timer = new AdminSessionTimer();;
#    private static HashMap hmModulesInUse = null;
#    private static HashMap hmFilesInUse = null;
    @@ALL_SESSIONS = Hash.new

    def initialize

        #rand = new SecureRandom(rand.generateSeed(12));
    end

    # Make this private....
    def self.checkModules

      #Change this to each session having an expiry date/time
      sessions = getAllSessions()
    end

    def self.generate_code(number)
      charset = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9')
      Array.new(number) { charset.sample }.join
    end

    def self.createSessionID
      # Create a random session id
      return AdminSession.generate_code(30)
    end
    def self.getAllSessions

        return @@ALL_SESSIONS
    end

  	def self.addNewSession(sessionName)

			hmNewSession = Hash.new
      hmNewSession["created"] = Time.now.to_f
      hmNewSession["sessionId"] = sessionName
			@@ALL_SESSIONS[sessionName] = hmNewSession
      puts "Added session: #{@@ALL_SESSIONS}"
			return true
  	end

	def self.deleteAllSessions
		@@ALL_SESSIONS.clear
  end


	def self.deleteSession(sessionName)

		if(@@ALL_SESSIONS.key?(sessionName))
			@@ALL_SESSIONS.delete(sessionName)
			return true
		else
			return false
		end
	end


	def self.getSessionHash(sessionName)

    #puts "getSessionHash #{@@ALL_SESSIONS}"
		if(@@ALL_SESSIONS.key?(sessionName))
			return @@ALL_SESSIONS[sessionName]
		else
			return nil
		end
	end

	def self.putInSession(sessionName, objName, obj)

		if(@@ALL_SESSIONS.key(sessionName))
			hmSessionTemp = @@ALL_SESSIONS[sessionName][objName] = obj
			return true
		else
			return false
		end
	end


	def self.getFromSession(sessionName, objName)

    puts "AdminSession: #{@@ALL_SESSIONS}"
		if(@@ALL_SESSIONS.key?(sessionName))
		    return @@ALL_SESSIONS[sessionName][objName]
		else
		    return nil
		end
	end


	def self.deleteFromSession(sessionName, objName)

		if(@@ALL_SESSIONS.key?(sessionName))
      if(@@ALL_SESSIONS[sessionName].key?(objName))

				@@ALL_SESSIONS[sessionName][objName].remove(objName)
				return true
      end
		end
    return false
	end

end
