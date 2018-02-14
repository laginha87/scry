require "../../spec_helper"

module Scry::Completion
    describe Trie do
        it "can add paths" do
            trie = Trie(String).new
            trie.add("a", "Entry")
            trie.add("b", "Entry 2")
            trie.size.should eq 2
        end
    end
end