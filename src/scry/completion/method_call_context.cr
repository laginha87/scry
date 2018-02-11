
module Scry::Completion
  class MethodCallContext < Context
    def initialize(@target : String, @method : String, @line : String, @text_document : TextDocument, @graph : Graph(String), @node : Crystal::ASTNode)
    end

    def find
      # to_completion_items(["Results", "And", "more", "results"])
      # TODO implement method call comlpetion
      filename =  @text_document.filename.chomp(".cr")
      to_completion_items(@graph.get(filename).as(Scry::Completion::Node(String)).descendants.map &.node)
    end

    def to_completion_items(results : Array(String))
      results.map do |res|
        CompletionItem.new(res, CompletionItemKind::Method, res, nil)
      end
    end
  end
end
