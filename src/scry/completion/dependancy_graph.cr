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
    property root_node

    def initialize
      @nodes = {} of T => Node(T)
      @root_node =Set(Node(T)).new
    end

    def add(value : T)
      @nodes[value] = Node.new value
    end

    def add_edge(value_1 : T, value_2 : T)
      if @nodes.has_key?(value_1)
        @root_node.delete @nodes[value_1]
      else
        add value_1
        @root_node << @nodes[value_1]
      end
      add(value_2) unless @nodes.has_key?(value_2)
      @nodes[value_1].children << @nodes[value_2]
    end

    def []?(node : T) : Node(T) | Nil
      @nodes.has_key?(node) ? @nodes[node] : nil
    end

    def [](node : T) : Node(T)
      @nodes[node]
    end
  end

  class Builder
    def initialize(@lookup_paths : Array(String))
      Log.logger.debug("Looking into: #{@lookup_paths.join ", "}")
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

      prelude_path = graph.nodes.keys.find { |e| e.ends_with?("src/prelude.cr") }.as(String)
      graph.nodes.keys.each { |n| graph.add_edge(n, prelude_path) unless n.ends_with?("src/prelude.cr") }
      Log.logger.debug "Finished Building for the following keys: #{graph.nodes.keys.join "\n"}"
      graph
    end

    def get_requires(file, graph)
      file_dir = File.dirname(file)
      current_file_path = File.expand_path(file)

      requires_so_far = [] of String

      File.each_line(file)
          .map { |line| /^\s*require\s*\"(?<file>.*)\"\s*$/.match(line) }
          .reject(&.nil?)
          .map { |e| e.as(Regex::MatchData)["file"] }
          .each do |required_file|
            required_file_path = resolve_path(required_file, file_dir)
        if !required_file_path
          Log.logger.debug "#{required_file} Not Found on dir #{file_dir} with resolved path #{required_file_path}"
        elsif required_file_path.ends_with?("*.cr")
          acc = [] of String
          Dir.glob(required_file_path).each do |p|
            graph.add_edge(current_file_path, p)
            requires_so_far.each do |pp|
              graph.add_edge(pp, p)
            end
            requires_so_far << p
          end
        else
          Log.logger.debug("ADding the edge #{current_file_path}")
          graph.add_edge(current_file_path, required_file_path)
          requires_so_far.each do |path|
            graph.add_edge(required_file_path, path)
          end
          requires_so_far << required_file_path
        end
      end
    end

    # private def expand_path(path)
    #   path.ends_with?(".cr") ? File.expand_path(path) : "#{File.expand_path(path)}.cr"
    # end

    def resolve_path(mod, dir)
      return File.expand_path(mod, dir) + ".cr" if mod.starts_with?(".")
      @lookup_paths.each do |e|
        path = File.expand_path(mod, e) + ".cr"
        return path if File.exists?(path)
      end
    end
  end
end
