# -*- coding: utf-8 -*-

$debug = 1;

# Define exceptions that will be used to signal errors

class VarNotFound < StandardError
end

class ObjAlreadyDefined < StandardError
end

class Scope
  # Ugly solution, might be able to fix it later
  attr_accessor :scope_var, :scope_func, :parent

  def initialize(parent = nil)
    @scope_var, @scope_func, @parent = {}, {}, parent
  end

  def add_var(var)
    if $debug then
      temp = self
      while not temp.parent.nil? and not temp.scope_var.has_key? var.name do
        temp = temp.parent
      end
      if temp != nil and temp != self then
        puts "Shadowing variable #{var.name.eval} from previous scope"
      end
    end
    @scope_var[var.name] = var.value
    puts "-----add_var-----" if $debug
    puts "var #{var.name.inspect} with value #{var.value.inspect}" if $debug
  end

  def get_var(name)
    puts "-----get_var-----" if $debug
    puts "IN SCOPE" if $debug
    # We start searching from ourselves
    scope = self    
    # dynamic scope, iterate backwards through scopes until we find the variable
    while not scope.parent.nil? and not scope.scope_var.has_key? name do
      scope = scope.parent
    end

    puts "inspection #{scope.inspect}"

    # if we have the key, we return it.
    # if we don't, we know we've iterated to nil and we can raise an exception
    puts "#{name.inspect} return #{scope.scope_var[name].inspect}" if $debug and
      scope.scope_var.has_key? name
    return scope.scope_var[name] if scope.scope_var.has_key? name

    raise VarNotFound, "Unable to find variable with name #{name.inspect}"
  end

  # name will be a NameNode
  def update_var(name, value)
    temp = self
    name = name.eval
    while not temp.parent.nil? and not temp.scope_var.has_key? name do
      temp = temp.parent
    end
    if $debug and temp != self then
      puts "Updated variable in older scope"
    end
    if not temp.nil? and temp.scope_var.has_key? name then
      puts "-----update_var-----" if $debug
      puts "updated #{name.inspect} with #{value.inspect}" if $debug
      temp.scope_var[name] = value
    end
  end

  def add_func(func)
    if $debug then
      temp = self
      while not temp.nil? and not temp.scope_func.has_key? func.name do
        temp = temp.parent
      end
      if temp != self then
        puts "Shadowing function #{func.name} from previous scope"
      end
    end
    @scope_func[func.name] = [func.type, func.body]
  end

  def get_func(name)
    temp = self
    name = name.eval
    # dynamic scope, iterate backwards through scopes until we find the variable
    while not temp.nil? and not temp.scope_func.has_key? name do
      temp = temp.parent
    end

    # if we have the key, we return it.
    # if we don't, we know we've iterated to nil and we can cast an exception
    if temp.scope_func.has_key? name then
      return temp.scope_func[name]
    end

    raise VarNotFound, "In Scope: Unable to find function with name #{name}"
  end
end

# A helper function that takes a scope and a variable as a argument.
# Will return a value based on the type of object, or nil if there is no value.
def get_var(scope, var)
  puts "in get_var()"
  puts "var: #{var.inspect}"
  if var.is_a? NameNode then
    puts "namenode"
    return get_var(scope, scope.get_var(var))
  elsif var.is_a? IdentifierNode then
    puts "identnode"
    return get_var(scope, scope.get_var(var))
  elsif var.is_a? ValueNode then
    puts "valuenode"
    puts var.eval(scope).class
    puts var.eval(scope)
    return var.eval(scope)
  else
    return var.eval(scope)
  end

  return nil
end

# ProgramRoot will act as the root node of the program tree
class ProgramRoot
  def initialize(stmt_list)
    @stmt_list = stmt_list
    @scope = Scope.new
  end

  def eval
    puts "----------"
    puts "begin eval in programroot"
    puts "----------"
    puts "\n\n\n"
    puts @stmt_list
    puts "\n\n\n"
    @stmt_list.each do |stmt|
      stmt.eval(@scope)
    end
  end
end

# Implementation of common functions

# A basic node handling output
class PrintNode
  def initialize(input)
    @input = input
  end

  def eval(scope)
    @input.each do |stmt|
      puts "-----PRINT-----" if $debug
      stmt = get_var(scope, stmt)
      puts(stmt) if stmt
    end
  end
end

# A basic node allowing input to be retrieved
class InputNode
  def initialize(input)
    @input = input
  end

  # TODO: Get previous type of the variable so that we save the correct type
  def eval(scope)
    @input.each do |stmt|
      old_val = scope.get_var(stmt)
      puts "-----INPUT-----" if $debug
      invalid = 1
      while invalid do
        begin
          user_input = gets
          if old_val.is_a? IntegerNode
            new_node = IntegerNode.new(Integer(user_input))
          elsif old_val.is_a? FloatNode
            new_node = FloatNode.new(Float(user_input))
          elsif old_val.is_a? StringNode
            new_node = StringNode.new(String(user_input))
          end
          invalid = nil
        rescue ArgumentError => detail
          puts detail.message
          puts detail.backtrace
        end
      end
      scope.update_var(NameNode.new(stmt), new_node)
    end
  end
end

class InsertNode
  def initialize(id, expr, index = nil)
    @id, @expr, @index = id, expr, index
  end

  def eval(scope)
    new_list = get_var(scope, @id).eval(scope)
    # new_list might be nil
    # new_list.size could be the new last index, so (size + 1) would be too much
    if (not new_list.nil?) and (not @index.nil?) and
        (@index.abs > (new_list.size + 1)) then
      raise(IndexError, "Index out of bounds")
    end

    puts "\t#{new_list.class} #{new_list.inspect}"

    if new_list.nil? then
      new_list = [@expr.eval(scope)]
    elsif @index then
      new_list.insert(@index, get_var(scope, @expr))
    else
      new_list.insert(new_list.size, get_var(scope, @expr))
    end

    scope.update_var(@id, new_list)
  end
end

# A node handling removal of items from the built-in list
# A index of -1 will remove the last item
class RemoveNode
  def initialize(id, index)
    @id, @index = id, index
  end

  def eval(scope)
    new_list = get_var(scope, @id)
    # array indexes can have a -(minus) prepended which will cause Ruby
    # to select the element from the right side
    raise(IndexError, "Index out of bounds") if @index.abs > (new_list.size - 1)
    new_list.delete_at @index
    scope.update_var(@id, new_list)
  end
end

class AtNode
  def initialize(id, index)
    @id, @index = id, index
  end

  def eval(scope)
    new_list = get_var(scope, @id).eval(scope)
    num_index = get_var(scope, @index).eval(scope)
    puts "index: #{@index.inspect}, num_index: #{num_index.inspect}"
    raise IndexError, "Index out of bounds" if num_index.abs > new_list.size - 1
    return new_list[num_index]
  end
end

class LengthNode
  def initialize(id)
    @id = id
  end

  def eval(scope)
    get_var(scope, @id).size
  end
end

class IfStmtNode
  def initialize(cond, stmts)
    @cond, @stmts = cond, stmts
  end

  def eval(scope)
    @child_scope = Scope.new(scope)
    puts "-----IFSTMTNODE-----"
    puts "stmts: #{@stmts.inspect}"
    if @cond.eval(@child_scope) then
      @stmts.each do |stmt|
        stmt.eval(@child_scope)
      end
    end
  end
end

class IfElseStmtNode
  def initialize(cond, stmts)
    @cond, @stmts = cond, stmts
  end

  def eval(scope)
    @child_scope = Scope(scope)
    if @cond.eval then
      @stmts.each do |stmt|
        stmt.eval(@child_scope)
      end
    end
  end
end

class ElseStmtNode
  def initialize(stmts)
    @stmts = stmts
  end

  def eval(scope)
    @child_scope = Scope(scope)
    @stmts.each do |stmt|
      stmt.eval(@child_scope)
    end
  end
end

class ForStmtNode
  def initialize(assign_stmt, test_stmt, incr_expr, stmts)
    @assign_stmt, @test_stmt = assign_stmt, test_stmt
    @incr_expr, @stmts = incr_expr, stmts
  end

  def eval(scope)
    # We want the execution to take place in its own scope
    @new_scope = Scope(scope)
    @assign_stmt.eval(@new_scope)
    while @test_stmt.eval(@new_scope) do
      @stmts.each do |stmt|
        stmt.eval(@new_scope)
      end
      # eval @incr_expr after each loop as to (hopefully) avoid an infinite loop
      @incr_expr.eval(@new_scope)
    end
  end
end

class WhileStmtNode
  def initialize(expr, stmts)
    @expr, @stmts = expr, stmts
  end

  def eval(scope)
    @new_scope = Scope(scope)
    while @expr.eval(@new_scope) do
      @stmts.each do |stmt|
        stmt.eval(@new_scope)
      end
    end
  end
end

# TODO: Create this function.
#       Maybe it can be empty, and we instead check if we find a ReturnNode
#       where appropriate(in WhileStmtNode etc.)
class ReturnNode
  def initialize(expr)
    @expr = expr
  end

  def eval(scope)
    @expr.eval(scope)
  end
end

# Data types

# A simple, constant node
class ValueNode
  def initialize(val = nil)
    raise ArgumentError, "Can't make a constant variable without val" if not val
    @val = val
  end

  def to_s
    @val
  end

  def eval(scope)
    puts "in valuenode eval()"
    puts "val: #{@val}"
    @val
  end
end

class IntegerNode < ValueNode
end

class FloatNode < ValueNode
end

class StringNode < ValueNode
end

class BoolNode < ValueNode
end

class ListNode < ValueNode
end

class NameNode
  attr_reader :name
  
  def initialize(name)
    @name = name
  end

  def eql?(op2)
    return @name == op2.name
  end

  def hash
    return @name.hash
  end

  def eval
    @name
  end
end

class IdentifierNode
  attr_reader :name, :value

  # TODO: Type safety
  def initialize(name, type, value = nil)
    # Encapsulates the value in the appropriate node
    # if value then
    #   case type
    #   when "int"
    #     value = IntegerNode.new(value)
    #   when "float"
    #     value = FloatNode.new(value)
    #   when "string"
    #     value = StringNode.new(value)
    #   when "bool"
    #     value = BoolNode.new(value)
    #   when "list"
    #     value = ListNode.new(value)
    #   end
    # end
    @name, @value = name, value
  end

  def eval(scope)
    scope.add_var(self)
  end

  def get_val(scope)
    @value.eval(scope)
  end
end

# Boolean statements and Numerical statements

# This function will, given a value, ``calculate'' whether it's true or false.
def val_to_bool(value, scope)
  case value.is_a?
  when NameNode
    identifier = scope.get_var(value.name)
    # Next time value_to_boolean() evaluates it won't have a IdentifierNode
    return value_to_boolean(identifier.get_val(scope), scope)
  when IntegerNode
    return value.eval(scope) > 0
  when FloatNode
    # Doesn't make a lot of sense. Provided as a convenience.
    return value.eval(scope) > 0
  when StringNode
    # Convenience.
    return value.eval(scope).size > 0
  when BoolNode
    # SHOULD already be a boolean value
    return value.eval(scope)
  when ListNode
    return value.eval(scope).size > 0
  end
end

class BinaryBooleanNode
  def initialize(op1, oper, op2)
    @op1, @oper, @op2 = op1, oper, op2
  end
  
  def eval(scope)
    # Works like this:
    # 1. get boolean value of @op1
    # 2. We then use send to send the following parameters:
    #     The first is a lookup of what operator to use
    #     Then we get the boolean value and send this to the operator
    # We are left with a boolean value which is returned
    val_to_bool(@op1, scope).send(@oper, val_to_bool(@op2, scope))
  end
end

class AndNode < BinaryBooleanNode
  def initialize(op1, op2)
    super(op1, :&, op2)
  end
end

class OrNode < BinaryBooleanNode
  def initialize(op1, op2)
    super(op1, :|, op2)
  end
end

class UnaryBooleanNode
  def initialize(op1, oper, op2)
    @op1, @oper = op1, oper
  end
  
  def eval(scope)
    val_to_bool(@op1, scope).send(@oper)
  end
end


class NotNode < UnaryBooleanNode
  def initialize(op1)
    super(op1, :!)
  end
end

class BinaryOperatorNode
  def initialize(op1, oper, op2)
    @op1, @oper, @op2 = op1, oper, op2
  end

  def eval(scope)
    puts @op1
    puts @oper
    puts @op2
    get_var(scope, @op1).send(@oper, get_var(scope, @op2))
  end
end

class AddNode < BinaryOperatorNode
  def initialize(op1, op2)
    super(op1, :+, op2)
  end
end

class SubtractNode < BinaryOperatorNode
  def initialize(op1, op2)
    super(op1, :-, op2)
  end
end

class MultiplyNode < BinaryOperatorNode
  def initialize(op1, op2)
    super(op1, :*, op2)
  end
end

class DivisionNode < BinaryOperatorNode
  def initialize(op1, op2)
    super(op1, :/, op2)
  end
end

class PowerNode < BinaryOperatorNode
  def initialize(op1, op2)
    super(op1, :**, op2)
  end
end

class UnaryOperatorNode
  def initialize(op1, oper)
    @op1, @oper = op1, oper
  end

  def eval(scope)
    @op1.send(@oper)
  end
end

class UnaryPlusNode < UnaryOperatorNode
  def initialize(op1)
    super(op1, :+@)
  end
end

class UnaryMinusNode < UnaryOperatorNode
def initialize(op1)
    super(op1, :-@)
  end
end
