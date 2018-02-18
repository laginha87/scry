require "../../spec_helper"
require "./helper"
require "compiler/crystal/syntax"

module Scry::Completion
  describe MethodCallContext do

    it "finds on int" do

      db = MethodDB.new({
        "Int32" => ["to_s", "to_json", "t_a", "+"].map {|e| MethodDbEntry.new(e, "MOCK FILE", Crystal::Def.new(e))}
      })

      code_sample_1 = "
                a = 1
                a.to_
            "
      context = MethodCallContext.new(code_sample_1, "a", "to_", db)
      context.find.map(&.label).should eq(["to_s", "to_json"]), "Failed for code_sample_1"

      code_sample_2 = "
      def u(a: Int32)
        a.to_
      "

      context = MethodCallContext.new(code_sample_2, "a", "to_", db)
      context.find.map(&.label).should eq(["to_s", "to_json"]), "Failed for code_sample_2"

      code_sample_3 = "
      def u(a  : Int32)
        a.to_
      "

      context = MethodCallContext.new(code_sample_3, "a", "to_", db)
      context.find.map(&.label).should eq(["to_s", "to_json"]), "Failed for code_sample_3"

      code_sample_4 = "
      def a(b : Object) : Int32
        2
      end
      a.to_
      "

      context = MethodCallContext.new(code_sample_4, "a", "to_", db)
      context.find.map(&.label).should eq(["to_s", "to_json"]), "Failed for code_sample_4"
    end
  end
end
