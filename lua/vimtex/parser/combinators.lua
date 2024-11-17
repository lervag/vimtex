-- VimTeX - LaTeX plugin for Vim
--
-- Maintainer: Karl Yngve Lervåg
-- Email:      karl.yngve@gmail.com
--
-- The following code is based on the implementation given here:
-- https://github.com/jacoblusk/lua-parser-combinators
--

---@type string
local TARGET

---@class ParserState
---@field index integer
---@field result any?
---@field error string?
local ParserState = {}
ParserState.__index = ParserState

---Create new parser state
---@param index integer
---@param result any?
---@param error string?
---@return ParserState
function ParserState.new(index, result, error)
  ---@type ParserState
  local state = {
    index = index,
    result = result,
    error = error or nil,
  }
  setmetatable(state, ParserState)

  return state
end

---Create new next state with specified result
---@param result any
---@return ParserState
function ParserState:copy_with_result(result)
  return ParserState.new(self.index, result, self.error)
end

---Create new next state with specified error
---@param error string
---@return ParserState
function ParserState:copy_with_error(error)
  return ParserState.new(self.index, self.result, error)
end

---Create new next state with specified result that drops error
---@param result any
---@return ParserState
function ParserState:succeed_with_result(result)
  return ParserState.new(self.index, result)
end

---Pretty print the parser state
---@return string
function ParserState:__tostring()
  if self.error then
    if type(TARGET) == "string" and not TARGET:match "\n" then
      return table.concat({
        "Error while parsing: " .. TARGET,
        (" "):rep(20 + self.index) .. "^",
        "At index: " .. self.index,
        self.error,
        "Current result: " .. vim.inspect(self.result),
      }, "\n")
    else
      return table.concat({
        "Error while parsing: " .. TARGET,
        "At index: " .. self.index,
        self.error,
        "Current result: " .. vim.inspect(self.result),
      }, "\n")
    end
  elseif type(self.result) == "string" then
    return self.result
  end

  return vim.inspect(self.result)
end

---@class Parser
---@field parser_fn fun(ParserState): ParserState
local Parser = {}
Parser.__index = Parser

---Create new parser
---@param parser_fn fun(input: ParserState): ParserState
---@return Parser
function Parser:new(parser_fn)
  ---@type Parser
  local parser = { parser_fn = parser_fn }
  setmetatable(parser, Parser)

  return parser
end

---Run parser on specified input
---
---On success, return the result. On error, return the parser state.
---@param input any
---@return any
function Parser:run(input)
  TARGET = input
  local initial_state = ParserState.new(1, nil)
  return self(initial_state)
end

---Call parser function on given state
---@param state ParserState
---@return ParserState
function Parser:__call(state)
  return self.parser_fn(state)
end

---Apply a function on the parser state result
---@param fn fun(result): any
---@return Parser
function Parser:map(fn)
  ---Parser function
  ---@param initial_state ParserState
  ---@return ParserState
  local parser_fn = function(initial_state)
    local next_state = self(initial_state)
    if next_state.error then
      return next_state
    end

    next_state.result = fn(next_state.result)
    return next_state
  end

  return Parser:new(parser_fn)
end

---Apply a function on the parser state error
---@param fn fun(error: string, index: integer): any
---@return Parser
function Parser:map_error(fn)
  ---Parser function
  ---@param initial_state ParserState
  ---@return ParserState
  local parser_fn = function(initial_state)
    local next_state = self(initial_state)
    if not next_state.error then
      return next_state
    end

    next_state.error = fn(next_state.error, next_state.index)
    return next_state
  end

  return Parser:new(parser_fn)
end

---Chain a parser based on the result
---
---Useful when combined with `succeed` or `fail`, e.g.:
---  ```lua
---  my_parser:chain(function(result)
---    if condition(result) then
---      return Parsers:succeed(result)
---    else
---      return Parsers:fail("Message")
---    end
---  end
---  ```
---@param fn fun(result): Parser
---@return Parser
function Parser:chain(fn)
  local parser_fn = function(initial_state)
    local next_state = self(initial_state)
    if next_state.error then
      return next_state
    end

    local next_parser = fn(next_state.result)
    return next_parser(next_state)
  end

  return Parser:new(parser_fn)
end

---Combine a sequence of parsers
---@param parsers Parser[]
---@return Parser
local function sequence(parsers)
  local parser_fn = function(initial_state)
    local results = {}
    local next_state = initial_state
    for _, parser in ipairs(parsers) do
      next_state = parser(next_state)
      if next_state.error then
        break
      end
      results[#results + 1] = next_state.result
    end

    return next_state:copy_with_result(results)
  end

  return Parser:new(parser_fn)
end

---Combine a sequence of parsers and flatten
---@param parsers Parser[]
---@return Parser
local function sequence_flat(parsers)
  return sequence(parsers):map(table.concat)
end

---Combine sequence of two parsers
---@param other Parser
---@return Parser
function Parser:__add(other)
  return sequence { self, other }
end

---Combine sequence of two parsers flattened
---@param other Parser
---@return Parser
function Parser:__concat(other)
  return sequence_flat { self, other }
end

---Combine two parsers and grab the left result
---@param p1 Parser
---@param p2 Parser
---@return Parser
local function left(p1, p2)
  return sequence({ p1, p2 }):map(function(results)
    return results[1]
  end)
end

---Combine two parsers and grab the right result
---@param p1 Parser
---@param p2 Parser
---@return Parser
local function right(p1, p2)
  return sequence({ p1, p2 }):map(function(results)
    return results[2]
  end)
end

---Accept first successful parser
---@param parsers Parser[]
---@return Parser
local function choice(parsers)
  local parser_fn = function(initial_state)
    for _, parser in ipairs(parsers) do
      local next_state = parser(initial_state)
      if not next_state.error then
        return next_state
      end
    end

    return initial_state:copy_with_error "choice: unable to match with any parser."
  end

  return Parser:new(parser_fn)
end

---Apply a parser zero or more times greedily
---@param parser Parser
---@return Parser
local function many(parser)
  local parser_fn = function(initial_state)
    local results = {}
    local next_state = initial_state

    while true do
      next_state = parser(next_state)
      if next_state.error then
        break
      end

      results[#results + 1] = next_state.result
    end

    return next_state:succeed_with_result(results)
  end

  return Parser:new(parser_fn)
end

---Apply a parser zero or more times greedily and flatten
---@param parser Parser
---@return Parser
local function many_flat(parser)
  return many(parser):map(table.concat)
end

---Apply a parser one or more times greedily
---@param parser Parser
---@return Parser
local function many1(parser)
  local parser_fn = function(initial_state)
    local results = {}
    local next_state = parser(initial_state)

    if next_state.error then
      return next_state
    end

    results[#results + 1] = next_state.result

    while true do
      next_state = parser(next_state)
      if next_state.error then
        break
      end

      results[#results + 1] = next_state.result
    end

    return next_state:succeed_with_result(results)
  end

  return Parser:new(parser_fn)
end

---Apply a parser one or more times greedily
---@param parser Parser
---@return Parser
local function many1_f(parser)
  local parser_fn = function(initial_state)
    local results = {}
    local next_state = parser(initial_state)

    if next_state.error then
      return next_state
    end

    results[#results + 1] = next_state.result

    while true do
      next_state = parser(next_state)
      if next_state.error then
        break
      end

      results[#results + 1] = next_state.result
    end

    return next_state:copy_with_result(results)
  end

  return Parser:new(parser_fn)
end

---Apply a parser one or more times greedily and flatten
---@param parser Parser
---@return Parser
local function many1_flat(parser)
  return many1(parser):map(table.concat)
end

---Capture states from value parser, skip results from separator parser
---@param separator_parser Parser
---@return fun(value_parser: Parser): Parser
local function separated_by(separator_parser)
  return function(value_parser)
    local parser_fn = function(initial_state)
      local results = {}
      local next_state = initial_state

      while true do
        local capture_state = value_parser(next_state)
        if capture_state.error then
          break
        end

        results[#results + 1] = capture_state.result
        next_state = capture_state

        local separator_state = separator_parser(next_state)
        if separator_state.error then
          break
        end

        next_state = separator_state
      end

      return next_state:succeed_with_result(results)
    end

    return Parser:new(parser_fn)
  end
end

---Capture states from value parser, skip results from separator parser
---Needs at least 1 value to succeed!
---@param separator_parser Parser
---@return fun(value_parser: Parser): Parser
local function separated_by1(separator_parser)
  return function(value_parser)
    local parser_fn = function(initial_state)
      local results = {}
      local next_state = initial_state

      while true do
        local capture_state = value_parser(next_state)
        if capture_state.error then
          break
        end

        results[#results + 1] = capture_state.result
        next_state = capture_state

        local separator_state = separator_parser(next_state)
        if separator_state.error then
          break
        end

        next_state = separator_state
      end

      if #results == 0 then
        return initial_state:copy_with_error "separated_by1: unable to capture any results"
      end

      return next_state:succeed_with_result(results)
    end

    return Parser:new(parser_fn)
  end
end

---Capture states from value parser, skip results from separator parser
---Requires a preceding separator
---@param separator_parser Parser
---@return fun(value_parser: Parser): Parser
local function separated_by_preceeding(separator_parser)
  return function(value_parser)
    local parser_fn = function(initial_state)
      local results = {}
      local next_state = initial_state

      local separator_state = separator_parser(next_state)
      if separator_state.error then
        return initial_state:copy_with_error "separated_by_preceeding: no preceeding found"
      end
      next_state = separator_state

      while true do
        local capture_state = value_parser(next_state)
        if capture_state.error then
          break
        end

        results[#results + 1] = capture_state.result
        next_state = capture_state

        separator_state = separator_parser(next_state)
        if separator_state.error then
          break
        end
        next_state = separator_state
      end

      return next_state:succeed_with_result(results)
    end

    return Parser:new(parser_fn)
  end
end

---Create parser for delimited content that excludes delimiters
---@param left_parser Parser
---@param right_parser Parser
---@return fun(content: Parser): Parser
local function between(left_parser, right_parser)
  return function(content_parser)
    return sequence({ left_parser, content_parser, right_parser }):map(
      function(results)
        return results[2]
      end
    )
  end
end

---Create parser for delimited content that includes delimiters
---@param left_parser Parser
---@param right_parser Parser
---@return fun(content: Parser): Parser
local function between_inclusive(left_parser, right_parser)
  return function(content_parser)
    return sequence { left_parser, content_parser, right_parser }
  end
end

---Create parser for delimited content that includes delimiters
---
---Returns flattened result.
---@param left_parser Parser
---@param right_parser Parser
---@return fun(content: Parser): Parser
local function between_inclusive_flat(left_parser, right_parser)
  return function(content_parser)
    return sequence({ left_parser, content_parser, right_parser }):map(
      table.concat
    )
  end
end

---Parser short circuit for success
---@param result any
---@return Parser
local function succeed(result)
  return Parser:new(function(initial_state)
    return initial_state:succeed_with_result(result)
  end)
end

---Parser short circuit for fail with error
---@param error string
---@return Parser
local function fail(error)
  return Parser:new(function(initial_state)
    return initial_state:copy_with_error(error)
  end)
end

---Parser to check for end of input
local eof = Parser:new(function(initial_state)
  if #TARGET < initial_state.index then
    return ParserState.new(initial_state.index, initial_state.result)
  end

  return initial_state:copy_with_error "eof: not end of file."
end)

---Parser that puts current state to value and nothing more
local peek = Parser:new(function(initial_state)
  if #TARGET < initial_state.index then
    return initial_state:copy_with_error "peek: unexpected end of input."
  end

  return initial_state:copy_with_result(
    TARGET:sub(initial_state.index, initial_state.index)
  )
end)

---Parser that accepts next input
local shift = Parser:new(function(initial_state)
  if #TARGET < initial_state.index then
    return initial_state:copy_with_error "shift: unexpected end of input."
  end

  local c = TARGET:sub(initial_state.index, initial_state.index)
  return ParserState.new(initial_state.index + 1, c)
end)

---Parser to insert current line number
local line_number = Parser:new(function(initial_state)
  if #TARGET < initial_state.index then
    return initial_state:copy_with_error "letter: unexpected end of input."
  end

  return initial_state:copy_with_result(
    vim.fn.count(TARGET:sub(1, initial_state.index), "\n") + 1
  )
end)

---Apply a result predicate on a parser
---@param predicate fun(result): boolean
---@param fail_msg string?
---@return fun(parser: Parser): Parser
local function filter(predicate, fail_msg)
  return function(parser)
    local parser_fn = function(initial_state)
      local next_state = parser(initial_state)
      if next_state.error then
        return next_state
      end

      if predicate(next_state.result) then
        return next_state
      end

      return initial_state:copy_with_error(
        fail_msg or "filter: predicate returned false"
      )
    end

    return Parser:new(parser_fn)
  end
end

---Filter on parser with predicate
---@param predicate fun(result): boolean
---@param fail_msg string?
---@return Parser
function Parser:filter(predicate, fail_msg)
  return filter(predicate, fail_msg)(self)
end

---Create a lazy parser
---
---This is very useful for recursive macros, such as:
---  ```lua
---  local nested_parser
---  nested_parser = pc.sequence(
---    g.char "(",
---    pc.many1(pc.choice(
---      pc.lazy(function() return nested_parser end),
---      g.letters
---    )),
---    g.char ")"
---  )
---  ```
---@param parser_thunk fun(): Parser
---@return Parser
local function lazy(parser_thunk)
  local parser_fn = function(initial_state)
    local parser = parser_thunk()
    return parser(initial_state)
  end

  return Parser:new(parser_fn)
end

---Create contextual parser
---
---See https://github.com/jacoblusk/lua-parser-combinators for an example of
---how to use this.
local function contextual(generator_fn)
  return succeed(nil):chain(function()
    local function run_step(next_value)
      local status, result = coroutine.resume(generator_fn, next_value)
      if status == "dead" or getmetatable(result) ~= Parser then
        return succeed(result)
      end

      local next_parser = result
      return next_parser:chain(run_step)
    end

    return run_step(nil)
  end)
end

local pc = {}

pc.Parser = Parser
pc.ParserState = ParserState

pc.eof = eof
pc.peek = peek
pc.shift = shift
pc.line_number = line_number
pc.filter = filter
pc.fail = fail
pc.succeed = succeed

pc.left = left
pc.right = right
pc.between = between
pc.between_inclusive = between_inclusive
pc.between_inclusive_flat = between_inclusive_flat
pc.delimited = between
pc.delimited_inclusive = between_inclusive
pc.delimited_inclusive_flat = between_inclusive_flat

pc.choice = choice
pc.separated_by = separated_by
pc.separated_by1 = separated_by1
pc.separated_by_preceeding = separated_by_preceeding
pc.many = many
pc.many_flat = many_flat
pc.many1 = many1
pc.many1_flat = many1_flat
pc.many1_f = many1_f
pc.sequence = sequence
pc.sequence_flat = sequence_flat

pc.lazy = lazy
pc.contextual = contextual

return pc
