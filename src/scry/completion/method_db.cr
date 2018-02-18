require "compiler/crystal/syntax"

module Scry::Completion
  class MethodDB
    property db : Hash(String, Array(MethodDbEntry))
    property classes : Graph(String)

    def initialize
      @db = Hash(String, Array(MethodDbEntry)).new
      @classes = Graph(String).new
    end

    def initialize(@db)
      @classes = Graph(String).new
    end

    def matches(types : Array(String), text : String) : Array(MethodDbEntry)
      types.each.flat_map do |e|
        res = @db[e]?
        if res
          res
        else
          Log.logger.debug("Couldn't find type #{e}")
          [] of MethodDbEntry
        end
      end
      .select(&.name.starts_with? text)
      .to_a
    end

    def add(t : String, methods : Array(MethodDbEntry))
      @db[t] = methods
    end

    def self.generate(paths)
        db = new
        paths.each do |path|
            unless File.exists? path
              Log.logger.error("Couldn't find #{path} to generate method db")
              next
            end
            node = Crystal::Parser.parse(File.read path)
            visitor = Generator.new(path)
            node.accept(visitor)
            db.db.merge!(visitor.classes) do |k, old_val, new_val|
              old_val + new_val
            end
        end
        db
    end
  end
  struct MethodDbEntry
    property name : String
    property file : String
    property location : String?
    property signature : String

    def initialize(@name, @file, node : Crystal::Def)
      @signature = "(#{node.args.map(&.to_s).join(", ")}) : #{node.return_type.to_s}"
      @location = node.location.to_s if node.location
    end

    def_equals_and_hash name
  end
  class Generator < Crystal::Visitor
    property classes
    def initialize(@file : String)
      @classes   =  {} of String => Array(MethodDbEntry)
      @class_queue = [] of String
    end

    # def visit(node : Crystal::ModuleDef)
    #   ns = node.name.to_s.split "::"
    #   @module_pop[node] = ns.size

    #   if ns.size > 1
    #     ns[0..-2].each do |namespace|
    #       @db.push_module namespace, @current_file
    #     end
    #   end

    #   @db.push_module ns.last, @current_file
    #   true
    # end
    def visit(node : Crystal::ModuleDef)
      true
    end

    def visit(node : Crystal::ClassDef)
      @classes[node.name.to_s] = [] of MethodDbEntry
      @classes["#{node.name.to_s}.class"] = [] of MethodDbEntry
      @class_queue << node.name.to_s
      true
    end

    def visit(node : Crystal::Def)
      return false if @class_queue.size == 0 || node.visibility != Crystal::Visibility::Public
      if node.name == "initialize"
        @classes["#{@class_queue.last}.class"] << MethodDbEntry.new("new", @file, node)
      elsif node.receiver
        @classes["#{@class_queue.last}.class"] << MethodDbEntry.new(node.name, @file, node)
      else
        @classes[@class_queue.last] << MethodDbEntry.new(node.name, @file, node)
      end
      false
    end

    def visit(node : Crystal::Expressions)
      true
    end


    def end_visit(node : Crystal::ClassDef)
      @class_queue.pop
    end

    def visit(node)
      false
    end
  end
end
