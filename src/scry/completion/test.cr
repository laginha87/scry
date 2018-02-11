require "compiler/crystal/syntax"

module Scry::Completion
    struct Node(T)
        property node
        property children

        def initialize(@node : T)
            @children = Set(Node(T)).new
        end
        def hash(hasher)
            @node.hash(hasher)
        end

        def descendants : Set(Node(T))
            visit = children.to_a
            visited = Set(Node(String)).new
            while visit.size != 0
                check = visit.pop()
                visited << check
                check.children.reject{|e| visited.includes?(e)}.each{|e| visit << e}
            end
            visited
        end
    end

    class Graph(T)
        property nodes

        def initialize
            @nodes = {} of T => Node(T)
        end

        def add(node : T)
            @nodes[node] = Node.new node
        end

        def add_edge(node_1 : T, node_2 : T)
            add(node_1) unless @nodes.has_key?(node_1)
            add(node_2) unless @nodes.has_key?(node_2)
            @nodes[node_1].children << @nodes[node_2]
        end

        def get(node : T) : Node(T) | Nil
            @nodes.has_key?(node) ? @nodes[node]: nil
        end
    end

    class Require
        @@dependecies = Graph(String).new
        @@dependants = Graph(String).new

        def self.get_requires(file)
            file_dir = File.dirname(file)
            file_path = File.expand_path(file).chomp(".cr")

            File.each_line(file)
                .map { |line|/^\s*require\s*\"(?<file>.*)\"\s*$/.match(line)}
                .reject(&.nil?)
                .map{|e| e.as(Regex::MatchData)["file"]}
                .each do |m|
                    path = resolve_path(m, file_dir)
                    if !path
                        Log.logger.debug "#{m} Not Found"
                    elsif path.ends_with?("*")
                        acc = [] of String
                        Dir.glob(path).each do |_p|
                            p = File.expand_path(_p).chomp(".cr")
                            @@dependecies.add_edge(file_path, p)
                            @@dependants.add_edge(p, file_path)
                            acc.each do |pp|
                                @@dependecies.add_edge(pp, p)
                                @@dependants.add_edge(p, pp)
                            end
                            acc << p
                        end
                    else
                        @@dependants.add_edge(path, file_path)
                        @@dependecies.add_edge(file_path, path)
                    end
                end
            # return [] of String unless matches
            # res = [] of String
            # i = 1
            # while m = matches[i]
            #     res << m
            #     i+=1
            # end
            # res
        end

        def self.resolve_path(mod, dir)
            return File.expand_path(mod, dir) if mod.starts_with?(".")
            ENV["CRYSTAL_PATH"].split(":").each do |e|
                path = File.expand_path(mod, e)
                return path if File.exists?(path)
            end
        end

        def self.dependecies
            @@dependecies
        end

        def self.dependants
            @@dependants
        end
    end

    class TypeVisitor < Crystal::Visitor
        property types
        property ntypes
        def initialize()
            @types = [] of String
        end
        def visit(node : Crystal::TypeDef)
            @types << node.name
        end

        def visit(node : Crystal::ClassDef)
            return false if node.visibility != Crystal::Visibility::Public
            @types << node.name.names.join("::")
            true
        end
        def visit(node : Crystal::ModuleDef)
            node.visibility == Crystal::Visibility::Public
        end

        def visit(node)
            true
        end
    end

    # puts Require.dependecies.nodes.size
    # puts Require.dependants.nodes.size
    # node = Require.dependecies.get("/usr/local/Cellar/crystal-lang/0.24.1_1/src/concurrent/scheduler")

    # exit unless node

    # visitor = TypeVisitor.new

    # node.descendants
    #          .map(&.node)
    # puts Dir.glob("/usr/local/Cellar/crystal-lang/0.24.1_1/src/**/*.cr")
    # Dir.glob("/usr/local/Cellar/crystal-lang/0.24.1_1/src/**/*.cr")
    #         .select{|e| File.exists? e }
    #         .map{|e| File.read e }
    #         .map{|e| Crystal::Parser.parse e }
    #         .each do |node|
    #             node.accept(visitor)
    #         end

    # puts visitor.types.group_by(&.size).keys
end