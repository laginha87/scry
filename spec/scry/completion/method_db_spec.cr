require "../../spec_helper"
module Scry::Completion
    describe MethodDB do
        it ".generate" do
            path = File.expand_path("spec/fixtures/completion/sample.cr")
            method_db = MethodDB.generate([
                path
            ])
            method_db.db["A"].map(&.name).should eq(["method", "method_b"])
            method_db.db["A.class"].map(&.name).should eq(["class_method"])
            # method_b.classes['A'].descendants.should eq([""])
        end
    end
end