require "../../spec_helper"
module Scry::Completion
    describe MethodDB do
        it ".generate" do
            path = File.expand_path("spec/fixtures/completion/sample.cr")
            db = MethodDB.generate([
                path
            ]).db


            db.should eq({"A" => ["#method", "#method_b", ".class_method"]})
        end
    end
end