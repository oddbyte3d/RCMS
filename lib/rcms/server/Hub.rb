require_relative "./net/HttpSession"
require_relative "./filters/OutputFilter"

class Hub


  def self.applyFilters(request, response, session, content)
      #puts "-----------------------------------\nIn Apply Filters\n----------------------------------------"
      if(request["APPLY_FILTERS"] != nil && request["APPLY_FILTERS"] == "false")
          return content
      else
        filterClasses = GlobalSettings.getGlobal("OutputFilters")
        #puts "All Filter Classes: #{filterClasses}"
        filters = filterClasses.split(",")
        myContent = content
        filters.each{ |filter|

            if(filter.strip.size > 0)

                #puts "Filter : #{filter}"
                className = filter[filter.rindex("/")+1..filter.size]
                #puts "ClassName : #{className}"
                require_relative(filter)
                obFilter = Kernel.const_get(className).new(session)
                #puts "obFilter.is_a?(OutputFilter) #{obFilter.class.name}"
                if(obFilter.is_a?(OutputFilter))

                    #puts "\tAccepted filter..."
                    myContent = obFilter.filterOutput(request, response, session, myContent)
                    #puts "\t...filter done #{myContent}"
                end
            end
        }
        #puts "\tReturning finished content"
        return myContent
      end
  end

  def self.applyFilter(request, response, session, content, filterClass)
      #puts "-----------------------------------\nIn Apply Filters\n----------------------------------------"
      if(request["APPLY_FILTERS"] != nil && request["APPLY_FILTERS"] == "false")
          return content
      else

        if(filterClass.strip.size > 0)

            className = filterClass[filterClass.rindex("/")+1..filterClass.size]
            require_relative(filterClass)
            obFilter = Kernel.const_get(className).new(session)
            puts "obFilter.is_a?(OutputFilter) #{obFilter.class.name}"
            if(obFilter.is_a?(OutputFilter))
              puts "\tAccepted filter..."
              myContent = obFilter.filterOutput(request, response, session, myContent)
              #puts "\t...filter done #{myContent}"
            end
        end
        #puts "\tReturning finished content"
        return myContent
      end
  end



end
