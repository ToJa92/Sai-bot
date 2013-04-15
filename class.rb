# -*- coding: utf-8 -*-

# Define exceptions that will be used to signal errors

class ObjNotCreated < StandardError
end

class ObjAlreadyDefined < StandardError
end

# Create some basic classes so that we can do something

class ProgramRoot
  def initialize(stmt_list)
    @stmt_list = stmt_list
  end

  def eval(stack)
    @stmt_list.each do |stmt|
      stmt.eval(stack)
    end
  end
end

class CALLSTACK
  def initialize
    # count will determine the number of top-level
    @count = 0
    @nest = 0
    @stack = []
    push_frame
  end

  # adds a new top-level stack
  def push
    @count += 1
    @nest += 1
    @stack << []
  end

  # adds a new `nested' stack, IE. a list in the current list
  def nest
    @nest += 1
    @stack[@count] << []
  end

  def add_obj(obj)
    @stack[@count] << obj
  end

  def to_s
    "callstack with #{@count} frames."
  end
end

class FUNC
  attr_reader :name, :args, :body
  def initialize(name, args, body)
    @name = name
    @args = args
    @body = body
  end

  def to_s
    "function #{@name} with args #{@args} and body #{@body}"
  end
end

class VAR
  attr_reader :type, :identifier, :value
  def initialize(type, identifier, value)
    @type = type
    @identifier = identifier
    @value = value
  end

  def to_s
    "variable #{@identifier} with type #{@type} and value #{@value}"
  end
end

# Implementation of common functions

# A basic node handling output
class PrintNode
  def initialize(input)
    @input = input
  end

  # TODO: must somehow get variable names etc. Maybe current scope can be passed to eval?
  def eval
    @input.each do |stmt|
      puts(stmt)
    end
    true
  end
end

# A basic node allowing input to be retrieved
class InputNode
  def initialize(input)
    @input = input
  end

  # TODO: stmt should probably be looked-up in the scope so we assign the correct var
  def eval
    @input.each do |stmt|
      stmt = gets
    end
  end
end

class InsertNode
  def initialize(id, expr)
    @id = id
    @expr = expr
  end

  def eval
    # getVarById(@id) << expr.eval
  end
end

# A node handling removal of items from the built-in list
# A index of -1 will remove the last item
class RemoveNode
  def initialize(id, index)
    @id, @index = id, index
  end

  def eval
    # array indexes can have a -(minus) prepended which will cause Ruby
    # to select the element from the right side
    # raise "index out of bounds" if @index.abs > lst.size
    # lst = getVarById(@id,scope)
    # lst.delete_at @index
    # saveVarById(@id, scope, lst);
  end
end

#class InsertNodeWithoutIndex ?
class InsertNode
  def initialize(id, expr, index)
    @id, @expr, @index = id, expr, index
  end

  def eval
    #lst = getVarById(@id, scope)
    #raise "index out of bounds" if @index.abs > lst.size
    #lst.insert(@index, @expr.eval(scope))
  end
end

class AtNode
  def initialize(id, index)
    @id, @index = id, index
  end

  def eval
    #lst = getVarById(@id, scope)
    #raise "index out of bounds" if @index.abs > lst.size
    #return lst[@index]
  end
end

class LengthNode
  def initialize(id)
    @id = id
  end

  def eval
    #return getVarById(@id, scope).size
  end
end

class IfStmtNode
  def initialize(cond, stmts)
    @cond, @stmts = cond, stmts
  end

  def eval
    if @cond.eval then
      @stmts.each do |stmt|
        stmt.eval
      end
    end
  end
end

class IfElseStmtNode
  def initialize(cond, stmts)
    @cond, @stmts = cond, stmts
  end

  def eval
    if @cond.eval then
      @stmts.each do |stmt|
        stmt.eval
      end
    end
  end
end

class ElseStmtNode
  def initialize(stmts)
    @stmts = stmts
  end

  def eval
    @stmts.each do |stmt|
      stmt.eval
    end
  end
end

# TODO: Limit iterations on ForStmt and WhileStmt?

class ForStmtNode
  def initialize(assign_stmt, test_stmt, incr_expr, stmts)
    @assign_stmt, @test_stmt, @incr_expr, @stmts = assign_stmt, test_stmt, incr_expr, stmts
  end

  def eval
    @new_scope = createChildScope(scope)
    @assign_stmt.eval(@new_scope) # should somehow be added to the scope in which test_stmt is eval'd
    while @test_stmt.eval(@new_scope) do
      @stmts.each do |stmt|
        stmt.eval(@new_scope)
      end
      # simply eval incr_expr after each round to make sure something's happening
      @incr_expr.eval(@new_scope)
    end
  end
end

class WhileStmtNode
  def initialize(expr, stmts)
    @expr, @stmts = expr, stmts
  end

  def eval
    @new_scope = createChildScope(scope)
    while @expr.eval(@new_scope) do
      @stmts.each do |stmt|
        stmt.eval(@new_scope)
      end
    end
  end
end

class ReturnNode
  def eval
    #getCurrScopeFunc.return?
  end
end

# Data types

# constant number node, also used for floating point numbers(?)
class NumberNode
  def initialize(num)
    @num = num
  end

  def eval
    @num
  end
end

class IdentifierNode
  def initialize(id, val = nil)
     @id, @val = id, val
  end

  def eval
    scope.addVar(@id, @val)
  end
end

class StringNode
  def initialize(val)
    @val = val
  end

  def eval
    @val
  end
end

class BoolNode
  def initialize(val)
    @val = val
  end

  def eval
    @val
  end
end

class ListNode
  def initialize(val)
    @val = val
  end

  def eval
    @val
  end
end

# Boolean statements and Numerical statements

class AndNode
  def initialize(op1, op2)
    @op1, @op2 = op1, op2
  end

  def eval
    @op1.eval(scope) and @op2.eval(scope)
  end
end

class OrNode
  def initialize(op1, op2)
    @op1, @op2 = op1, op2
  end

  def eval
    @op1.eval(scope) or @op2.eval(scope)
  end
end

class NotNode
  def initialize(op1)
    @op1 = op1
  end

  def eval
    not @op1.eval(scope)
  end
end

class ComparisonNode
  def initialize(op1, oper, op2)
    @op1, @oper, @op2 = op1, oper, op2
  end

  def eval
    @op1.eval @oper @op2.eval
  end
end

class AddNode

end

class SubtractNode

end

class MultiplyNode

end

class DivisionNode

end

class UnaryPlusNode

end

class UnaryMinusNode

end

class PowerNode

end
