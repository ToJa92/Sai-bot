require './rdparse'
require './class.rb'

class OurStuff
  def initialize
    @ourParser = Parser.new("ourparse") do
      # Finds all the strings
      token(/^"[^"]*"/) {|s| s}
      # Gets rid of all the whitespace
      token(/\s+/)
      token(/^</){|m| m}
      token(/^>/){|m| m}
      token(/^,/){|m| m}
      token(/^{/){|m| m}
      token(/^}/){|m| m}
      token(/^=/){|m| m}
      token(/^for/){|m| m}
      token(/^while/){|m| m}
      token(/^if/){|m| m}
      token(/^elseif/){|m| m}
      token(/^else/){|m| m}
      token(/^print/){|m| m}
      token(/^read/){|m| m}
      token(/^ins/){|m| m}
      token(/^rem/){|m| m}
      token(/^func/){|m| m}
      token(/^\*\*/){|m| m}
      token(/^(\+|-|\/|\*)/){|m| m}
      token(/^return/){|m| m}
      token(/^at/){|m| m}
      token(/^len/){|m| m}
      token(/^string/){|m| m}
      token(/^bool/){|m| m}
      token(/^list/){|m| m}
      token(/^int/){|m| m}
      token(/^float/){|m| m}
      token(/^le/){|m| m}
      token(/^lt/){|m| m}
      token(/^gt/){|m| m}
      token(/^ge/){|m| m}
      token(/^eq/){|m| m}
      token(/^ne/){|m| m}
      token(/^true/){|m| m}
      token(/^false/){|m| m}
      token(/^[a-z]+[a-z_]*/){ |m| m }
      # Finds all floating point numbers
      token(/^(\d+\.\d*)|(\d*\.\d+)/) {|f| f.to_f}
      # Finds all integers
      token(/^\d+/){|i| i}
      # Remove the rest
      token(/.*/)

      #  ---Parser---
      start :program do
        match(:statements) {|stmts| ProgramRoot.new(stmts.reverse).eval }
      end

      rule :statements do
        match(:statement, :statements) { |stmt, stmts| (stmts + [stmt]) }
        match(:statement) { |stmt| [stmt] }
      end

      rule :statement do
        match(:compound_statement)
        match(:advanced_statement)
        match(:simple_statement)
      end

      rule :compound_statement do
        match(:for_stmt)
        match(:while_stmt)
        match(:if_list)
      end

      rule :simple_statement do
        match(:at_stmt)
        match(:len_stmt)
        match(:func_call)
      end

      rule :advanced_statement do
        match(:declaration)
        match(:print_stmt)
        match(:read_stmt)
        match(:ins_stmt)
        match(:rem_stmt)
        match(:func_stmt)
        match(:assign_stmt)
        match(:return_stmt)
        match(:inc_decr_stmt)
      end

      rule :for_stmt do
        match('<', 'for', ',', :declaration, ',', :expr, ',',
              :incr_decr_stmt, '>',
              :block){|_, _, _, assign, _, test, _, incr, _, block|
          ForStmtNode.new(assign, test, incr, block) }
      end

      rule :while_stmt do
        match('<', 'while', ',', :expr, '>', :block){ |_, _, _, expr, _, block|
          WhileStmtNode.new(expr, block) }
      end

      rule :if_list do
        match(:if_stmt, :elseif_stmt,
              :else_stmt){ |if_stmt, elseif_list, else_stmt|
          IfElseifElseNode.new(if_stmt + elseif_list + else_stmt) }
        match(:if_stmt, :elseif_stmt){ |if_stmt, elseif_list|
          IfElseifElseNode.new(if_stmt + elseif_list) }
        match(:if_stmt, :else_stmt){ |if_stmt, else_stmt|
          IfElseifElseNode.new(if_stmt + else_stmt) }
        match(:if_stmt){ |if_stmt| IfElseifElseNode.new(if_stmt) }
      end

      rule :if_stmt do
        match('<', 'if', ',', :expr, '>', :block) { |_, _, _, expr, _, block|
          [IfStmtNode.new(BooleanNode.new(expr), block)] }
      end

      rule :elseif_stmt do
        match('<', 'elseif', ',', :expr, '>',
              :block, :elseif_stmt) { |_, _, _, expr, _, block, elseif_stmts|
          elseif_stmts + [IfStmtNode.new(BooleanNode.new(expr), block)].reverse
        }
        match('<', 'elseif', ',', :expr, '>',
              :block) { |_, _, _, expr, _, block|
          [IfStmtNode.new(BooleanNode.new(expr), block)] }
      end

      rule :else_stmt do
        match('<', 'else', '>', :block) {|_, _, _, block|
          [IfStmtNode.new(block)] }
      end

      rule :print_stmt do
        match('<', 'print', ',', :expr, '>'){ |_, _, _, a, _|
          PrintNode.new([a]) }
      end

      rule :read_stmt do
        match('<', 'read', ',', :identifier, '>'){ |_, _, _, input, _|
          InputNode.new([input]) }
      end

      rule :ins_stmt do
        match('<', 'ins', ',', :identifier, ',',
              :expr, '>'){ |_, _, _, id, _, expr| InsertNode.new(id, expr) }
      end

      rule :rem_stmt do
        match('<', 'rem', ',', :identifier, ',',
              :expr, '>'){ |_, _, _, id, _, expr|
          RemoveNode.new(id, expr) }
        match('<', 'rem', ',', :identifier, '>'){ |_, _, _, id, _, expr|
          RemoveNode.new(id) }
      end

      rule :func_stmt do
        match('<', 'func', ',', :type, ',',
              :identifier, ',', :type_list, '>', :block){ |_, _, _,
          type, _, id, _, args, _, block|
          FunctionNode.new(id, type, args, block) }
      end

      rule :func_call do
        match('<', :identifier, ',', :atom_list, '>') { |_, id, _, args, _|
          FuncCallNode.new(id, args)
        }
      end

      rule :type_list do
        match(:declaration, ',', :type_list){ |decl, _, decls|
          ([decl] + decls)
        }
        match(:declaration) { |decl| [decl] }
      end

      rule :assign_stmt do
        match('<', '=', ',', :identifier, ',',
              :expr, '>'){ |_, _, _, id, _, expr, _|
          AssignmentNode.new(id, expr) }
      end

      rule :return_stmt do
        match('<', 'return', ',', :expr, '>'){ |_, _, _, expr|
          ReturnNode.new(expr) }
      end

      rule :at_stmt do
        match('<', 'at', ',', :identifier, ',',
              :integer, '>'){ |_, _, _, id, _, index, _|
          AtNode.new(id, index)
        }
      end

      rule :len_stmt do
        match('<', 'len', ',', :identifier, '>'){ |_, _, _, id|
          LengthNode.new(id) }
      end

      rule :incr_decr_stmt do
        match('<', :incr_decr_list, ',',
              :identifier, ',', :expr, '>'){ |_, incr_decr, _, id, _, expr, _|
          IncrementNode.new(id, incr_decr, expr)
        }
      end

      rule :incr_decr_list do
        match('+', '='){ |_| :pleq }
        match('-', '='){ |_| :mieq }
        match('*', '='){ |_| :mueq }
        match('/', '='){ |_| :dieq }
      end

      rule :type do
        match('string')
        match('bool')
        match('list')
        match('int')
        match('float')
      end

      rule :declaration do
        match('<', :type, ',', :identifier,
              ',', :expr, '>'){ |_,type,_,id,_,expr|
          IdentifierNode.new(id, type, expr)
        }
        match('<', :type, ',', :identifier, '>') {
          |_,type,_,identifier| IdentifierNode.new(identifier, type)
        }
      end

      rule :block do
        match('{', :block_item) { |_,stmt| stmt }
      end

      rule :block_item do
        match(:statement, :block_item) { |stmt, stmts|
          ([stmt] + stmts)
        }
        match(:statement, '}'){ |stmt,_| [stmt] }
      end

      rule :expr do
        match(:and_test)
        match(:expr, "or", :and_test) {|op1, _, op2| OrNode.new(op1, op2)}
      end

      rule :and_test do
        match(:not_test)
        match(:and_test, "and", :not_test) {|op1, _, op2| AndNode.new(op1, op2)}
      end

      rule :not_test do
        match(:comparison)
        match("not", :not_test) {|_, val| NotNode.new(val)}
      end

      rule :comparison do
        match(:num_expr, :comp_op,
              :num_expr){ |num1, op, num2|
          BinaryComparisonNode.new(num1, op, num2) }
        match(:num_expr)
      end

      rule :comp_op do
        match('lt'){ :< }
        match('le'){ :<= }
        match('gt'){ :> }
        match('ge'){ :>= }
        match('eq'){ :== }
        match('ne'){ :!= }
      end

      rule :num_expr do
        match(:num_expr, '+', :term) { |num1, _, num2| AddNode.new(num1, num2) }
        match(:num_expr, '-', :term) { |num1, _, num2|
          SubtractNode.new(num1, num2)
        }
        match(:term)
      end

      rule :term do
        match(:term, '*', :factor) { |num1, _, num2|
          MultiplyNode.new(num1, num2) }
        match(:term, '/', :factor) { |num1, _, num2|
          DivisionNode.new(num1, num2) }
        match(:factor)
      end

      rule :factor do
        match('+', :factor) {|_, num1| UnaryPlusNode.new(num1)}
        match('-', :factor) {|_, num1| UnaryMinusNode.new(num1)}
        match(:power)
      end

      rule :power do
        match(:atom, '**', :term) {|num1, _, num2| PowerNode.new(num1, num2)}
        match(:simple_statement)
        match(:atom)
      end

      rule :atom do
        match(:string)
        match(:float)
        match(:integer)
        match(:bool)
        match(:identifier)
      end

      rule :atom_list do
        match(:atom, ',', :atom_list){ |atom, _, atoms|
          ([atom] + atoms)
        }
        match(:atom){ |atom| [atom] }
      end

      rule :identifier do
        match(/[a-z]+[a-z_]*/){|m| NameNode.new(m) }
      end

      rule :float do
        match(/(\d+\.\d*)|(\d*\.\d+)/) {|f| FloatNode.new(Float(f)) }
      end

      rule :integer do
        match(/\d+/) {|i| IntegerNode.new(Integer(i)) }
      end

      rule :string do
        match(/"[^"]*"/) {|s| StringNode.new(s[1,s.size-2]) }
      end

      rule :bool do
        match(/true/) { |_| BoolNode.new(true) }
        match(/false/) { |_| BoolNode.new(false) }
      end
    end
  end

  def done(str)
    ["quit","exit","bye",""].include?(str.chomp)
  end

  def prompt
    print "[Sai-bot] "
    str = gets
    if done(str) then
      puts "Bye."
    else
      puts "=> #{@ourParser.parse str}"
    end
  end

  def parse(str)
    @ourParser.parse str
  end

  def log(state = true)
    if state
      @ourParser.logger.level = Logger::DEBUG
    else
      @ourParser.logger.level = Logger::WARN
    end
  end
end

a = OurStuff.new
a.log true
a.parse(File.read("test.ut"))
