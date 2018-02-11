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
        check = visit.pop
        visited << check
        check.children.reject { |e| visited.includes?(e) }.each { |e| visit << e }
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
      @nodes.has_key?(node) ? @nodes[node] : nil
    end
  end

  class Builder
    def initialize(@lookup_paths : Array(String))
    end

    def build
      graph = Graph(String).new
      @lookup_paths.map { |e| File.join(File.expand_path(e), "**", "*.cr") }
                   .uniq
                   .each do |d|
        Dir.glob(d).each do |d|
          get_requires d, graph
        end
      end
      graph.nodes.each do |_, n|
        Log.logger.debug("Node: ")
        Log.logger.debug(n.node)
        Log.logger.debug("Descendants: ")
        Log.logger.debug n.descendants.map(&.node).join("\n    ")
      end

      graph
    end

    def get_requires(file, graph)
      file_dir = File.dirname(file)
      file_path = File.expand_path(file).chomp(".cr")

      File.each_line(file)
          .map { |line| /^\s*require\s*\"(?<file>.*)\"\s*$/.match(line) }
          .reject(&.nil?)
          .map { |e| e.as(Regex::MatchData)["file"] }
          .each do |m|
        path = resolve_path(m, file_dir)
        if !path
          Log.logger.debug "#{m} Not Found"
        elsif path.ends_with?("*")
          acc = [] of String
          Dir.glob(path).each do |_p|
            p = File.expand_path(_p).chomp(".cr")
            graph.add_edge(file_path, p)
            acc.each do |pp|
              graph.add_edge(pp, p)
            end
            acc << p
          end
        else
          graph.add_edge(file_path, path)
        end
      end
    end

    def resolve_path(mod, dir)
      return File.expand_path(mod, dir) if mod.starts_with?(".")
      @lookup_paths.each do |e|
        path = File.expand_path(mod, e)
        return path if File.exists?(path)
      end
    end
  end
end
