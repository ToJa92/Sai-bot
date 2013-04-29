require './class'

main = ProgramRoot.new([IdentifierNode.new(NameNode.new("a"), "int", 5),
                        PrintNode.new([NameNode.new("a")]),
                       InputNode.new([NameNode.new("a")]),
                       PrintNode.new([NameNode.new("a")])])

main.eval
