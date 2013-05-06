# -*- coding: utf-8 -*-

$debug = 1;
require 'pp'

# Define exceptions that will be used to signal errors

class VarNotFound < StandardError
end

class FuncNotFound < StandardError
end

class ObjAlreadyDefined < StandardError
end

class NoValueError < StandardError
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
        puts "Shadowing variable #{var.name.eval} from previous scope" if $debug
      end
    end
    @scope_var[var.name] = var.value
    puts "-----ADD_VAR IN SCOPE-----" if $debug if $debug
    puts "added #{var.name.inspect} with value #{var.value.inspect}" if $debug if $debug
  end

  def get_var(name)
    #puts "-----GET_VAR IN SCOPE-----" if $debug
    # We start searching from ourselves
    scope = self
    # dynamic scope, iterate backwards through scopes until we find the variable
    while not scope.parent.nil? and not scope.scope_var.has_key? name do
      scope = scope.parent
    end

    # if we have the key, we return it.
    # if we don't, we know we've iterated to nil and we can raise an exception
   #puts "#{name.inspect} return #{scope.scope_var[name].inspect}" if $debug and
      #scope.scope_var.has_key? name
    return scope.scope_var[name] if scope.scope_var.has_key? name

    raise VarNotFound, "Unable to find variable with name #{name.inspect}"
  end

  # name will be a NameNode
  def update_var(name, value)
    puts "-----UPDATE VAR IN SCOPE-----" if $debug if $debug
    temp = self
    while not temp.parent.nil? and not temp.scope_var.has_key? name do
      temp = temp.parent
    end
    if $debug and temp != self then
      puts "Updated variable in older scope" if $debug
    end

    if not temp.nil? and temp.scope_var.has_key? name then
      puts "updated #{name.inspect} with #{value.inspect}" if $debug if $debug
      temp.scope_var[name] = value
    end
  end

  def add_func(func)
    if $debug then
      temp = self
      while not temp.parent.nil? and not temp.scope_func.has_key? func.name do
        temp = temp.parent
      end
      if temp != self then
        puts "Shadowing function #{func.name} from previous scope" if $debug
      end
    end
    @scope_func[func.id] = func
  end

  def get_func(name)
    temp = self
    # dynamic scope, iterate backwards through scopes until we find the variable
    while not temp.parent.nil? and not temp.scope_func.has_key? name do
      temp = temp.parent
    end

    # if we have the key, we return it.
    # if we don't, we know we've iterated to nil and we can cast an exception
    if temp.scope_func.has_key? name then
      return temp.scope_func[name]
    end

    raise FuncNotFound, "Scope: Couldn't find function #{name.inspect}"
  end
end

# A helper function that takes a scope and a variable as a argument.
# Will return a value based on the type of object, or nil if there is no value.
def get_var(scope, var)
  puts "-----GET_VAR() OUTSIDE SCOPE-----" if $debug
  puts "var: #{var.inspect}" if $debug
  if var.is_a? NameNode then
    puts "namenode" if $debug
    return get_var(scope, scope.get_var(var))
  elsif var.is_a? IdentifierNode then
    puts "identnode" if $debug
    return get_var(scope, scope.get_var(var))
  elsif var.is_a? ValueNode or var.is_a? BinaryOperatorNode then
    puts "valuenode or binaryoperatornode" if $debug
    res = var
    puts "returning #{res.inspect}" if $debug
    return res
  else
    return var
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
    puts "----------" if $debug
    puts "begin eval in programroot" if $debug
    puts "----------" if $debug
    puts "\n"*50 if $debug
    puts @stmt_list, "\n" if $debug
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
      puts "--------------------PRINT" if $debug
      stmt = get_var(scope, stmt)
      if stmt.is_a? Array then
        stmt.each { |item| puts item.eval(scope) }
      elsif stmt.is_a? ValueNode then
        puts(stmt)
      else
        puts(stmt.eval(scope)) if stmt
      end
      puts "--------------------------------------------------" if $debug
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
          puts detail.message if $debug
          puts detail.backtrace if $debug
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
    puts "-----INSERTNODE EVAL-----" if $debug
    new_list = get_var(scope, @id)
    # new_list might be nil
    # new_list.size could be the new last index, so (size + 1) would be too much
    if (not new_list.nil?) and (not @index.nil?) and
        (@index.abs > (new_list.size + 1)) then
      raise(IndexError, "Index out of bounds")
    end

    puts "\t#{new_list.class} #{new_list.inspect}" if $debug

    if new_list.nil? then
      new_list = [@expr.eval(scope)]
    elsif @index then
      new_list.insert(@index, get_var(scope, @expr).eval(scope))
    else
      new_list.insert(new_list.size, get_var(scope, @expr).eval(scope))
    end

    scope.update_var(@id, ListNode.new(new_list))
  end
end

# A node handling removal of items from the built-in list
# A index of -1 will remove the last item
class RemoveNode
  def initialize(id, index = nil)
    @id, @index = id, index
  end

  def eval(scope)
    puts "-----REMOVENODE EVAL-----" if $debug
    new_list = get_var(scope, @id)
    if @index.nil? then
      new_list.delete_at new_list.size -  1
    else
      temp = get_var(scope, @index)
      raise(IndexError, "Out of bounds") if temp.abs > (new_list.size)
      new_list.delete_at temp
    end
    scope.update_var(@id, new_list)
  end
end

class AtNode
  def initialize(id, index = nil)
    @id, @index = id, index
  end

  def eval(scope)
    new_list = get_var(scope, @id)
    num_index = if @index.nil?then new_list.size else get_var(scope, @index) end
    puts "index: #{@index.inspect}, num_index: #{num_index.inspect}" if $debug
    raise IndexError, "Index out of bounds" if num_index.abs > new_list.size - 1
    return new_list[num_index]
  end
end

class LengthNode
  def initialize(id)
    @id = id
  end

  def eval(scope)
    IntegerNode.new(get_var(scope, @id).size)
  end
end

class IfElseifElseNode
  def initialize(parts)
    @parts = parts
  end

  def eval(scope)
    @parts.each { |stmt|
      break if (stmt.eval(scope) if stmt)
    }
  end
end

class IfStmtNode
  def initialize(cond = nil, stmts)
    @cond, @stmts = cond, stmts
  end

  def eval(scope)
    @child_scope = Scope.new(scope)
    # if the IfNode has a condition. else-branch will have a empty condition
    # and is always last in the code.
    if @cond then
      # If the condition is evaluated to true
      if @cond.eval(@child_scope) then
        @stmts.each do |stmt|
          stmt.eval(@child_scope)
        end
        # Will break the chain of if-elseif-...-elseif-else
        return true
      else
        # Continue with next elseif/else
        return false
      end
    else
      # We've reached the else-branch
      @stmts.each do |stmt|
        stmt.eval(@child_scope)
      end
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
    @new_scope = Scope.new(scope)
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
    @new_scope = Scope.new(scope)
    while @expr.eval(@new_scope) do
      #puts "-----IN WHILESTMTNODE EVAL-----"
      #puts "expr eval: #{@expr.eval(@new_scope)}"
      #sleep(5)
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

class IncrementNode
  def initialize(id, incr_decr, expr = nil)
    @id, @incr_decr, @expr = id, incr_decr, expr
  end

  def eval(scope)
    puts "-----INCREMENTNODE EVAL-----" if $debug
    old_val = scope.get_var(@id)
    new_val = 0
    case @incr_decr
    when :pleq # plus equals(+=)
      new_val = old_val.eval(scope) + @expr.eval(scope)
    when :mieq # minus equals(-=)
      new_val = old_val.eval(scope) - @expr.eval(scope)
    when :mueq
      new_val = old_val.eval(scope) * @expr.eval(scope)
    when :dieq
      new_val = old_val.eval(scope) / @expr.eval(scope)
    end
    new_val = old_val.class.new(new_val)
    scope.update_var(@id, new_val)
  end
end

class AssignmentNode
  def initialize(name, val)
    @name, @val = name, val
  end

  def eval(scope)
    puts "-----ASSIGNMENT EVAL-----" if $debug
    new_val = @val.eval(scope)
    puts "new_val: #{new_val.inspect}" if $debug
    scope.update_var(@name, new_val)
  end
end

# Data types

# A simple, constant node
class ValueNode
  attr_reader :val

  def initialize(val = nil)
    @val = val
  end

  def to_s
    "#{@val}"
  end

  def eval(scope)
    puts "in valuenode eval()" if $debug
    puts "val: #{@val}" if $debug
    raise NoValueError, "Attempted to use a variable without value" if @val.nil?
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

class FunctionNode
  attr_reader :id, :ret_type, :idlist, :block
  
  def initialize(id, ret_type, idlist, block)
    @id, @ret_type, @idlist, @block = id, ret_type, idlist, block
  end

  def eval(scope)
    puts "-----FUNCTIONNODE EVAL-----" if $debug
    scope.add_func(self)
  end
end

class FuncCallNode
  def initialize(id, args)
    @id, @args = id, args
  end

  def eval(scope)
    puts "-----FUNCCALLNDODE EVAL-----" if $debug
    new_scope = Scope.new(scope)
    func_obj = scope.get_func(@id)
    raise(ArgumentError,
          "Wrong number of arguments") if @args.size != func_obj.idlist.size
    @args.zip(func_obj.idlist).each do |arg1, arg2|
      #puts "arg1: #{arg1.inspect}", "arg2: #{arg2.inspect}"
      arg1_t = if arg1.is_a? NameNode then
                 puts "getting arg1 type" if $debug
                 arg1.get_type(scope)
               else
                 arg1.eval(scope).class
               end
      arg2_t = arg2.value.class
      raise(ArgumentError,
            "type #{arg1_t} is not equal to #{arg2_t}") if arg1_t != arg2_t
    end

    puts "INSTANTIATING EMPTY VARIABLES" if $debug
    puts "AND SETTING VALUES" if $debug

    @args.zip(func_obj.idlist).each do |arg1,arg2|
      puts "adding variable #{arg2.inspect}" if $debug
      arg2.eval(new_scope)
      arg1_v = scope.get_var(arg1)
      puts "#{arg2.inspect} updated with #{arg1_v.inspect}" if $debug
      new_scope.update_var(arg2.name, arg1_v)
    end

    puts "NEW_SCOPE" if $debug
    PP.pp new_scope if $debug
    puts "\n"*3 if $debug

    func_obj.block.each do |stmt|
      stmt.eval(new_scope)
    end
  end
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

  def get_type(scope)
    return scope.get_var(self).class
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
    if value.nil? then
      case type
      when "int"
        value = IntegerNode.new(value)
      when "float"
        value = FloatNode.new(value)
      when "string"
        value = StringNode.new(value)
      when "bool"
        value = BoolNode.new(value)
      when "list"
        value = ListNode.new([])
      end
    end
    @name, @value = name, value
  end

  def ===(op2)
    @name === op2.name
  end

  def eval(scope)
    puts "-----IDENTIFIERNODE EVAL-----" if $debug
    puts "adding: #{self.inspect}" if $debug
    scope.add_var(self)
  end

  def get_val(scope)
    @value.eval(scope)
  end
end

# Boolean statements and Numerical statements

# This function will, given a value, ``calculate'' whether it's true or false.
def val_to_bool(value, scope)
  puts "-----VAL_TO_BOOL-----" if $debug
  puts "value.class: #{value.class}" if $debug
  res = nil
  if value.is_a? NameNode then
    # Next time value_to_boolean() evaluates it won't get a IdentifierNode
    res = val_to_bool(scope.get_var(value), scope)
  elsif value.is_a? IntegerNode then
    res = value.eval(scope) > 0
  elsif value.is_a? FloatNode then
    # Doesn't make a lot of sense. Provided as a convenience.
    res = value.eval(scope) > 0
  elsif value.is_a? StringNode then
    # Convenience.
    res = value.eval(scope).size > 0
  elsif value.is_a? BoolNode then
    # SHOULD already be a boolean value
    res = value.eval(scope)
  elsif value.is_a? ListNode then
    res = value.eval(scope).size > 0
  end
  puts "res: #{res.inspect}" if $debug
  return res
end

class BinaryComparisonNode
  def initialize(op1, oper, op2)
    @op1, @oper, @op2 = op1, oper, op2
  end

  def eval(scope)
    puts "-----BINARYCOMPARISON EVAL-----" if $debug
    op1 = get_var(scope, @op1)
    op2 = get_var(scope, @op2)
    puts "ope1: #{op1.inspect}" if $debug
    puts "oper: #{@oper.inspect}" if $debug
    puts "ope2: #{op2.inspect}" if $debug
    get_var(scope, @op1).send(@oper, get_var(scope, @op2))
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
    puts "-----BINARYOPERATORNODE EVAL-----" if $debug
    puts "OP1 #{@op1.inspect}" if $debug
    puts "OPER #{@oper.inspect}" if $debug
    puts "OP2 #{@op2.inspect}" if $debug
    op1 = get_var(scope, @op1).eval(scope)
    op2 = get_var(scope, @op2).eval(scope)
    IntegerNode.new(get_var(scope, op1).send(@oper, get_var(scope, op2)))
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
