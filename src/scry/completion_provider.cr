require "./log"
require "compiler/crystal/crystal_path"
require "./completion/*"

module Scry
  class UnrecognizedContext < Exception
  end

  class CompletionProvider
    METHOD_CALL_REGEX       = /(?<target>[a-zA-Z][a-zA-Z_:]*)\s*\.\s*(?<method>[a-zA-Z]*[a-zA-Z_:]*)$/
    INSTANCE_VARIABLE_REGEX = /(?<var>@[a-zA-Z_]*)$/
    REQUIRE_MODULE_REGEX    = /require\s*\"(?<import>[a-zA-Z\/._]*)$/

    def initialize(@text_document : TextDocument, @context : CompletionContext | Nil, @position : Position, @method_db : Completion::MethodDB, @graph : Completion::Graph(String))
    end

    # def initialize(@text_document : TextDocument, @context : CompletionContext | Nil, @position : Position)
    #   @method_db = nil
    #   @graph = Scry::Completion::Graph(String).new
    # end
    def initialize(@text_document : TextDocument, @context : CompletionContext | Nil, @position : Position)
      @method_db = Completion::MethodDB.new
      @graph = Completion::Graph(String).new
    end

    def run
      parse_context.find
    end

    def parse_context
      start_index = @position.line > 10 ? (@position.line - 10) : 0
      lines = @text_document.source.lines[0..@position.line]
      lines[-1] = lines.last[0..@position.character - 1]
      lines = lines.join(" ")
      case lines
      when METHOD_CALL_REGEX
        Completion::MethodCallContext.new(@text_document.source, $~["target"], $~["method"], @method_db)
      when INSTANCE_VARIABLE_REGEX
        Completion::InstanceVariableContext.new($~["var"], lines, @text_document)
      when REQUIRE_MODULE_REGEX
        Completion::RequireModuleContext.new($~["import"], @text_document)
      else
        raise UnrecognizedContext.new("Couldn't identify context of: #{lines}")
      end
    end
  end
end
