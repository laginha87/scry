require "../../spec_helper"
require "./helper"

def children(node)
    node.children.map(&.node).sort
end

module Scry::Completion
    describe Builder do
        it "builds" do
            graph = Helper.init_test_dependacy_graph
            root = Helper.root
            sample_2_path = File.expand_path("sample_2" , root)
            sample_3_path = File.expand_path("sample_3" , root)
            sample_path = File.expand_path("sample" , root)
            json_path = File.expand_path("json" , Crystal::CrystalPath.default_path.split(":").grep(/crystal/).first.as(String))
            prelude_path = File.expand_path("prelude" , Crystal::CrystalPath.default_path.split(":").grep(/crystal/).first.as(String))
            tree_path = File.expand_path("tree" , root)

            node = graph[sample_2_path]
            children(node).should eq([sample_3_path, prelude_path].sort)

            node = graph[sample_3_path]
            children(node).should eq([sample_path, prelude_path].sort)

            node = graph[sample_path]
            children(node).should eq([json_path, tree_path, prelude_path].sort)
        end
    end
end