module Scry::Completion
  class MethodCallContext < Context
    TYPE_REGEXP      = /[A-Z][a-zA-Z_:0-9]+/
    NEW_REGEXP       = /(?<type>#{TYPE_REGEXP})(?:\(.+\))?\.new/
    FUNC_CALL_REGEXP = /(?<class>#{TYPE_REGEXP})\.(?<method>\w+)[\(\s]/

    def initialize(@text : String, @target : String, @method : String, @db : MethodDB)
    end

    def find
      t = get_type
      res = t ? @db.matches([t], @method) : [] of String
      to_completion_items res
    end

    def get_type
      case @text
      when /#{@target} = (true|false)\s/
        "Bool"
      when /#{@target} = [-+]?[0-9]+(_([iu])(8|16|32|64))?/
        if $~[1]?
          "#{($~[2] == "i" ? "Int" : "UInt")}#{$~[3]}"
        else
          "Int32"
        end
      when assign_regexp, declaration_regexp, in_file_method_declaration_regexp
        $~["type"]
      # when /#{@target} = #{FUNC_CALL_REGEXP}/ TODO

      #     pattern = "#{m["class"]}.#{m["method"]}"
      #     res = db.match pattern
      #     if res.size == 1 && (entry = res.first) &&
      #         (m = entry.signature.match /:\s?(#{TYPE_REGEXP})(?:\(.+\))?\s*$/)
      #         return m[1]
      #     else
      #         Server.logger.debug "Fail to get the return type of function call : #{m}"
      #     end
      else
          # Log.logger.debug "Can't find the type of \"#{@target}\""
          nil
      end


      #
      #     Server.logger.debug "Can't find the type of \"#{@splitted.first}\""
      #     nil
      #   end
    end

    private def to_completion_items(results : Array(String))
      results.map do |res|
        CompletionItem.new(res, get_kind(res), res, nil)
      end
    end

    private def assign_regexp
      /#{@target}\s*=\s*#{NEW_REGEXP}/
    end

    private def declaration_regexp
      /#{@target}\s*:\s*(?<type>#{TYPE_REGEXP})/
    end

    private def in_file_method_declaration_regexp
      /def\s*#{@target}\(.*\)\s*:\s*(?<type>#{TYPE_REGEXP})/
    end

    private def get_kind(label : String)
      return CompletionItemKind::Folder
      case label
      when .starts_with?(".new")
        CompletionItemKind::Constructor
      when .starts_with?(".")
        CompletionItemKind::Method
      else
        CompletionItemKind::Function
      end
    end
  end
end
