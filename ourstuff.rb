require './rdparse'
require './class.rb'


##############################################################################
#
# Stuff and things
#
##############################################################################

class OurStuff
  def initialize
    @ourParser = Parser.new("ourparse") do
      #  ---Lexer---
      #Finds all the strings
      token(/^"[^"]*"/) {|s| s}
      #Get rid of all the whitespaces
      token(/\s+/)
      token(/^</){|m| m}
      token(/^>/){|m| m}
      token(/^,/){|m| m}
      token(/^{/){|m| m}
      token(/^}/){|m| m}
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
      #Finds all float/doubls and the likes.
      token(/^(\d+\.\d*)|(\d*\.\d+)/) {|f| f.to_f}
      #Finds all integers.
      token(/^\d+/){|i| i}
      #Just gathers up any possible leftovers(necessary?)
      token(/.*/)
	  
      #  ---Parser---
      start :input do
        match(:stmt, :input) { |stmt, stmts|
          puts "-----MATCH(:STMT,:INPUT)-----"
          puts stmt.inspect
          puts
          puts stmts.inspect
          ProgramRoot.new(([stmts] + [stmt]).reverse).eval
        }
        match(:stmt) { |stmt| stmt }
      end
      
      rule :stmt do
        match(:for_stmt)
        match(:while_stmt)
        match(:if_stmt)
        match(:print_stmt)
        match(:read_stmt)
        match(:ins_stmt)
        match(:rem_stmt)
        match(:func_stmt)
        match(:assign_stmt)
        match(:return_stmt)
        match(:at_stmt)
        match(:len_stmt)
        match(:inc_decr_stmt)
        match(:declaration)
      end

      rule :for_stmt do
        match('<', 'for', ',', :assign_stmt, ',', :expr, ',', :incr_decr_stmt, '>', :block){|_, _, _, assign, _, test, _, incr, _, block| ForStmtNode.new(assign, test, incr, block)}
      end

      rule :while_stmt do
        match('<', 'while', ',', :expr, '>', :block) {|_, _, _, expr, _, block| WhileStmtNode.new(expr, block)}
      end

      rule :if_stmt do
        match('<', 'if', ',', :expr, '>', :block, :elseif_stmt, :else_stmt) {|_, _, _, expr, _, block|IfStmtNode.new(expr, block)}
        match('<', 'if', ',', :expr, '>', :block, :elseif_stmt){|_, _, _, expr, _, block|IfStmtNode.new(expr, block)}
        match('<', 'if', ',', :expr, '>', :block, :else_stmt){|_, _, _, expr, _, block|IfStmtNode.new(expr, block)}
        match('<', 'if', ',', :expr, '>', :block){|_, _, _, expr, _, block|
          puts "-----MATCH IF EXPR BLOCK-----"
          puts
          puts block.inspect
          puts
          IfStmtNode.new(expr, block)
        }
      end

      rule :elseif_stmt do
        match('<', 'elseif', ',', :expr, '>', :block) {||IfElseStmtNode.new()}
        match('<', 'elseif', ',', :expr, '>', :block, :elseif_stmt) {|| IfElseStmtNode.new()}
        match('<', 'elseif', ',', :expr, '>', :block, :else_stmt) {|| IfElseStmtNode.new()}
      end

      rule :else_stmt do
        match('<', 'else', '>', :block) {|_, _, _, block| ElseStmtNode.new(block)}
      end

      rule :print_stmt do
        match('<', 'print', ',', :atom, '>') {|_, _, _, a| PrintNode.new([a])}
      end

      rule :read_stmt do
        match('<', 'read', ',', :identifier, '>') {|_, _, _, input| InputNode.new(input)}
      end

      rule :ins_stmt do
        match('<', 'ins', ',', :identifier, ',', :expr, '>') {|_, _, _, id, _, expr| InsertNode.new(id, expr)}
      end

      rule :rem_stmt do
        match('<', 'rem', ',', :identifier, ',', :expr, '>') {|_, _, _, id, _, expr| RemoveNode.new(id, expr)}
      end

      rule :func_stmt do
        match('<', 'func', ',', :identifier, ',', :type_list, '>', :block_stmt)
      end
      
      rule :type_list do
        match(:type)
        match(:type, ',', :type_list)
      end

      rule :assign_stmt do
        match('<', '=', :identifier, ',', :type, ',', :atom, '>') {|_, _, id, _, type, _, atom| IdentifierNode.new(id, type, atom);}
      end

      rule :return_stmt do
        match('<', 'return', ',', :expr, '>') {|_, _, _, expr| ReturnNode.new(expr)}
      end

      rule :at_stmt do
        match('<', 'at', ',', :integer, ',', :identifier, '>') 
      end

      rule :len_stmt do
        match('<', 'len', ',', :identifier, '>') {|_, _, _, id| LengthNode.new(id)}
      end

      rule :inc_decr_stmt do
        match('<', :incdecr_list, ',', :identifier, '>')
      end

      rule :incdecr_list do
        match('x++')
        match('++x')
        match('x--')
        match('--x')
      end

      rule :type do
        match('string')
        match('bool')
        match('list')
        match('int')
        match('float')
      end

      rule :declaration do
        match('<', :type, ',', :identifier, ',', :atom, '>') { |_,type,_,identifier,_,expr| IdentifierNode.new(identifier, type, expr) }
        match('<', :type, ',', :identifier, '>') { |_,type,_,identifier| IdentifierNode.new(identifier, type) }
      end

      rule :block do
        match('{', :block_item) { |_,stmt| stmt }
      end

      rule :block_item do
        match(:stmt, :block_item) { |stmt, stmts|
          # [stmt] + [stmts][0,[stmts].size-1].reverse
          puts "-----RULE BLOCK_ITEM-----"
          puts "stmt: ", stmt.inspect
          puts "stmts: ", stmts.inspect
          (stmts + [stmt]).reverse
        }
        match(:stmt, '}'){ |stmt,_| [stmt] }
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
          puts "#{num1} #{op} #{num2}"
          BinaryOperatorNode.new(num1, op, num2) }
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
        match(:term)
        match(:num, '+', :num) {|num1, _, num2| AddNode.new(num1, num2)}
        match(:num, '-', :num) {|num1, _, num2| SubtractNode.new(num1, num2)}
      end

      rule :num do
        match(:term)
        match(:num_expr)
      end

      rule :term do
        match(:factor)
        match(:factor, '*', :factor) {|num1, _, num2| MultiplyNode.new(num1, num2)}
        match(:factor, '/', :factor) {|num1, _, num2| DivisionNode.new(num1, num2)}
      end

      rule :factor do
        match('+', :factor) {|_, num1| UnaryPlusNode.new(num1)}
        match('-', :factor) {|_, num1| UnaryMinusNode.new(num1)}
        match(:power)
      end

      rule :power do
        match(:atom, '**', :term) {|num1, _, num2| PowerNode.new(num1, num2)}
        match(:stmt)
        match(:atom)
      end

      rule :atom do
        match(:float)
        match(:integer)
        match(:bool)
        match(:string)
        match(:identifier)
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
        match(/"[^"]*"/) {|s| StringNode.new(s) }
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
    print "[stuff] "
    str = gets
    if done(str) then
      puts "Bye."
    else
      puts "=> #{@ourParser.parse str}"
    end
  end
  
  def log(state = true)
    if state
      @ourParser.logger.level = Logger::DEBUG
    else
      @ourParser.logger.level = Logger::WARN
    end
  end
end

while true do
  OurStuff.new.prompt
end
