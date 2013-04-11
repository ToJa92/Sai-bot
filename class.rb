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

class PRINT < FUNC
  def initialize(input)
    super(
  end
end
