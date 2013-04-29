require './class'

main = ProgramRoot.new([IdentifierNode.new("a", "int", 5),
                       InputNode.new([NameNode.new("a")]),
                       PrintNode.new([NameNode.new("a")])])

main.eval
