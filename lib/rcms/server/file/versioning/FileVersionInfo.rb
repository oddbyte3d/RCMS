class FileVersionInfo

    @TYPE_MODIFIED = 0
    @TYPE_DELETED = 1
    @TYPE_RENAMED = 2
    @TYPE_ROLLBACK = 3

    def initialize(user, type, vWhen)

        @WHEN = vWhen
        @adminUser = user
        @VTYPE = type
    end

    def getVersionTypeAsString

        case @VTYPE
        when @TYPE_DELETED
          return "Deleted"
        when @TYPE_MODIFIED
          return "Modified"
        when @TYPE_RENAMED
          return "Renamed"
        when @TYPE_ROLLBACK
          return "Rollback"
        end
        return "Unknown type"
    end


end
