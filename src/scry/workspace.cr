require "./completion/dependency_graph"

module Scry
  struct Workspace
    property root_uri : String
    property process_id : Int32 | Int64
    property max_number_of_problems : Int32
    property open_files
    property dependency_graph : Completion::DependencyGraph::Graph

    def initialize(root_uri, process_id, max_number_of_problems)
      @root_uri = root_uri
      @process_id = process_id
      @max_number_of_problems = max_number_of_problems
      @open_files = {} of String => TextDocument
      @dependency_graph = Completion::DependencyGraph::Graph.new
    end

    def open_workspace
      @dependency_graph = Completion::DependencyGraph::Builder.new(ENV["CRYSTAL_PATH"].split(":") + ["#{@root_uri}/src"]).build
    end

    def put_file(params : DidOpenTextDocumentParams | DidChangeTextDocumentParams)
      file = TextDocument.new(params)
      @open_files[file.filename] = file
    end

    def drop_file(params : TextDocumentParams)
      filename = TextDocument.uri_to_filename(params.text_document.uri)
      @open_files.delete(filename)
    end

    def get_file(text_document : TextDocumentIdentifier)
      filename = TextDocument.uri_to_filename(text_document.uri)
      @open_files[filename]
    end
  end
end
