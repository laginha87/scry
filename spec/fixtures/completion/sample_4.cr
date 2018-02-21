class A
    def puts_class_and_super
      puts "#{self.class.to_s} -> A"
    end
  end

  class D
    def puts_class_and_super
      puts "#{self.class.to_s} -> D"
    end
  end

  class C < A
  end

  class M::A
    def puts_class_and_super
      puts "#{self.class.to_s} -> M::A"
    end
  end

  class M2::C < A
  end

  class M::B < M::A
  end

  class M::C < A
  end

  module M
    class C2 < A; end

    class C3 < B; end

    class C4 < D; end
  end

  A.new.puts_class_and_super     # A -> A
  C.new.puts_class_and_super     # C -> A
  M::A.new.puts_class_and_super  # M::A -> M::A
  M2::C.new.puts_class_and_super # M2::C -> A
  M::B.new.puts_class_and_super  # M::B -> M::A
  M::C.new.puts_class_and_super  # M::C -> A
  M::C2.new.puts_class_and_super # M::C2 -> M::A
  M::C3.new.puts_class_and_super # M::C3 -> M::B It's not what is ouputed but its what's right
  M::C4.new.puts_class_and_super # M::C4 -> D
