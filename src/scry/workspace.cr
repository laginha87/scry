require "./completion/dependancy_graph"
require "./completion/method_db"
require "json"
require "./protocol/*"
require "./text_document"
require "compiler/crystal/syntax"
module Scry
  struct Workspace
    property root_uri : String
    property process_id : Int32 | Int64
    property max_number_of_problems : Int32
    property open_files
    property graph : Scry::Completion::Graph(String)

    def initialize(root_uri, process_id, max_number_of_problems)
      @root_uri = root_uri
      @process_id = process_id
      @max_number_of_problems = max_number_of_problems
      @open_files = {} of String => {TextDocument, Completion::MethodDB}
      @graph = Scry::Completion::Graph(String).new
    end

    def put_file(params : DidOpenTextDocumentParams | DidChangeTextDocumentParams)
      file = TextDocument.new(params)
      descendants = @graph[file.filename].descendants.map &.node
      Log.logger.debug("The descendants of #{file.filename} are the descendants: #{descendants.join " : "}")
      node = Completion::MethodDB.generate(descendants)
      @open_files[file.filename] = {file, node}
    end

    def update_file(params : DidOpenTextDocumentParams | DidChangeTextDocumentParams)
      file = TextDocument.new(params)
      _, node = @open_files[file.filename]
      @open_files[file.filename] = {file, node}
    end

    def drop_file(params : TextDocumentParams)
      filename = TextDocument.uri_to_filename(params.text_document.uri)
      @open_files.delete(filename)
    end

    def get_file(text_document : TextDocumentIdentifier)
      filename = TextDocument.uri_to_filename(text_document.uri)
      @open_files[filename]
    end

    def process_requires
      @graph = Scry::Completion::Builder.new(ENV["CRYSTAL_PATH"].split(":") + ["#{@root_uri}/src"]).build
    end
  end
end
