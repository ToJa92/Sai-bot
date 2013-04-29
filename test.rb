require './class'

main = ProgramRoot.new([IdentifierNode.new(NameNode.new("a"), "list", [
IntegerNode.new(1),IntegerNode.new(2),IntegerNode.new(3)]),
                        IdentifierNode.new(NameNode.new("b"), "int", 0),
                        InputNode.new([NameNode.new("b")]),
                        InsertNode.new(NameNode.new("a"), NameNode.new("b")),
                        PrintNode.new([NameNode.new("a")])])

main.eval
