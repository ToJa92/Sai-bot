# -*- coding: utf-8 -*-

# Define exceptions that will be used to signal errors

class ObjNotCreated < StandardError
end

class ObjAlreadyDefined < StandardError
end

# Create some basic classes so that we can do something

class SCOPE
  def initialize
    @count = 0
    @stack = []
    push_frame
  end

  # would probably be called whenever curly braces are found
  def push
    @count += 1
    @stack << {}
  end

  def pop
    @count -= 1
    @stack.pop
  end

  def add_obj(obj)
    # If everything goes correctly, this should not happen.
    # For instance, assignment should not be handled by adding a object
    raise(ObjAlreadyDefined, "#{obj.name} already defined") if @stack[@count].has_key? obj.name
    @stack[@count][obj.name] << obj
  end

  def get_obj(name)
    raise(ObjNotCreated, "Object #{name} can't be found") unless @stack[@count].has_key? name
    @stack[@count][name]
  end

  def update_obj(name, obj)
    @stack[@count][name] = obj
  end

  def obj_in_curr_scope?(name)
    @stack[@count].has_key? name
  end

  def to_s
    "scope with #{@count} frames."
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

class PRINT < FUNC
  
end
