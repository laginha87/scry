require "../../spec_helper"
module Scry::Completion
    describe MethodDB do
        it ".generate builds the method db" do
            path = File.expand_path("spec/fixtures/completion/sample.cr")
            method_db = MethodDB.generate([
                path
            ])
            method_db.db["A"].map(&.name).should eq(["method", "method_b"])
            method_db.db["A.class"].map(&.name).should eq(["class_method"])

            method_db.db["B"].map(&.name).should eq(["struct_method_a"])
            method_db.db["B.class"].map(&.name).should eq(["struct_class_method"])
        end

        it ".generate builds the class hierarchy" do
            path = File.expand_path("spec/fixtures/completion/sample_4.cr")
            method_db = MethodDB.generate([
                path
            ])

            method_db.classes["A"].descendants.map(&.node).should eq(["Reference"])
            method_db.classes["C"].descendants.map(&.node).should eq(["A", "Reference"])
            method_db.classes["M::A"].descendants.map(&.node).should eq(["Reference"])
            method_db.classes["M2::C"].descendants.map(&.node).should eq(["A", "Reference"])
            method_db.classes["M::B"].descendants.map(&.node).should eq(["M::A", "Reference"])
            method_db.classes["M::C"].descendants.map(&.node).should eq(["A", "Reference"])
            method_db.classes["M::C2"].descendants.map(&.node).should eq(["M::A", "Reference"])
            method_db.classes["M::C3"].descendants.map(&.node).should eq(["M::B", "M::A", "Reference"])
            method_db.classes["M::C4"].descendants.map(&.node).should eq(["D", "Reference"])
        end
    end
end