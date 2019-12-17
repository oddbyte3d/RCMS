
class ObjectRepositoryTimer

  attr_reader :IS_RUNNING, :REFRESH
	#private ObjectRepository loader;
	#private long refresh;
	#private boolean isRunning = false;


	def initialize
    @my_mutex = Mutex.new
    @IS_RUNNING = false
    #@REFRESH = 2.minutes.from_now
    @REFRESH = 30#5.second.from_now #.second.from_now
    setRefresh(@REFRESH)
  end


	def setLoader(loader)
	   @LOADER = loader
  end

	def setRefresh(refresh)
    @REFRESH = refresh
    if !@IS_RUNNING
      #puts "set thread..."
      Thread.new do
        @IS_RUNNING = true
        sleep @REFRESH
        #puts 'deactivate'
        #puts "running thread"
        runTimer
        setRefresh(@REFRESH)
      end
      #handle_asynchronously :runTimer, :run_at => Proc.new { @REFRESH }
			@IS_RUNNING = true
		end
	end


	def destroy
		@IS_RUNNING = false
	end

  private

	def runTimer
    @my_mutex.synchronize{
      if @IS_RUNNING
          puts "Timer running...."
          if @LOADER != nil
  		        @LOADER.run
          end
          @IS_RUNNING = false

      end
    }
	end
end
