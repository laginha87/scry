require "compiler/crystal/crystal_path"
require "../../spec_helper"

class Helper
    @@builder : Scry::Completion::Graph(String)?
    def self.root
        File.expand_path("spec/fixtures/completion")
    end

    def self.init_test_dependacy_graph
        unless @@builder
            paths = Crystal::CrystalPath.default_path.split(":")
            paths << root
            @@builder = Scry::Completion::Builder.new(paths).build
        end
        @@builder.as(Scry::Completion::Graph(String))
    end
end