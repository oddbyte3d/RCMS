class Parser

  def initialize
  end

  def self.replace(toSearch, toReplace, toReplaceWith)
    temp = ""
    toUseSearch = toSearch
    toUseReplace = toReplace
    startIndex = toUseSearch.index(toUseReplace)
    endIndex = startIndex+toReplace.size
    temp << toSearch[0, startIndex]
    temp << toReplaceWith
    temp << toSearch[endIndex, toSearch.size]
  end

  def self.replaceAll(toSearch, toReplace, toReplaceWith)
      tmp = toSearch
      toReturn = toSearch
      while tmp.index(toReplace) != nil do
        #puts "Search #{tmp} : for: #{toReplace}"
        tmp = replace(tmp, toReplace, toReplaceWith)
        toReturn = tmp;
      end
      return toReturn;
  end


end
