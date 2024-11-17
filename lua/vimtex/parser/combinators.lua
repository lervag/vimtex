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

---@class ParserStateNewlines
---@field index integer
---@field count integer

---@class ParserState
---@field index integer
---@field prev_newlines ParserStateNewlines
---@field result any?
---@field error string?
local ParserState = {}
ParserState.__index = ParserState

---Create new state
---@param index integer
---@param prev_newlines ParserStateNewlines
---@param result any?
---@param error string?
---@return ParserState
function ParserState.new(index, prev_newlines, result, error)
  return setmetatable({
    index = index,
    prev_newlines = prev_newlines,
    result = result,
    error = error,
  }, ParserState)
end

---Create initial parser state
---@param target string
---@return ParserState
function ParserState.initial(target)
  TARGET = target
  return ParserState.new(1, { index = 1, count = 0 })
end

---Use index as result and shift
---@return ParserState
function ParserState:shift()
  return ParserState.new(
    self.index + 1,
    self.prev_newlines,
    TARGET:sub(self.index, self.index)
  )
end

---Create new state with specified result
---@param result any
---@return ParserState
function ParserState:with_result(result)
  return ParserState.new(self.index, self.prev_newlines, result, self.error)
end

---Create new state with specified error
---@param error string
---@return ParserState
function ParserState:with_error(error)
  return ParserState.new(self.index, self.prev_newlines, self.result, error)
end

---Create new state with specified result that drops error
---@param result any
---@return ParserState
function ParserState:succeed(result)
  return ParserState.new(self.index, self.prev_newlines, result)
end

---Pretty print the parser state
---@return string
function ParserState:__tostring()
  if self.error then
    local index = self.index
    local length = 40
    local start = 1
    local indicator = ("━"):rep(self.index - 1) .. "┑"
    if self.index > length / 2 then
      index = length / 2
      start = self.index - index + 1
      indicator = "┉" .. ("━"):rep(index - 2) .. "┑"
    end
    local sub_target = TARGET:sub(start, start + length):gsub("\n", "↵")

    return table.concat({
      "Error at index " .. self.index .. " — " .. self.error,
      indicator,
      sub_target,
    }, "\n")
  end

  if type(self.result) == "string" then
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
  local parser = { parser_fn = parser_fn }
  return setmetatable(parser, Parser)
end

---Run parser on specified input
---
---On success, return the result. On error, return the parser state.
---@param input any
---@return any
function Parser:run(input)
  return self(ParserState.initial(input))
end

---Call parser function on given state
---@param state ParserState
---@return ParserState
function Parser:__call(state)
  return self.parser_fn(state)
end

---Apply a function on the parser state result
---@param f fun(result): any
---@return Parser
function Parser:map(f)
  ---@param state ParserState
  ---@return ParserState
  local parser_fn = function(state)
    local next_state = self(state)
    if not next_state.error then
      next_state.result = f(next_state.result)
    end
    return next_state
  end

  return Parser:new(parser_fn)
end

---Apply a function on the parser state error
---@param f fun(error: string, index: integer): any
---@return Parser
function Parser:map_error(f)
  ---@param state ParserState
  ---@return ParserState
  local parser_fn = function(state)
    local next_state = self(state)
    if next_state.error then
      next_state.error = f(next_state.error, next_state.index)
    end
    return next_state
  end

  return Parser:new(parser_fn)
end

---Ignore result of parser
---@return Parser
function Parser:ignore()
  return self:map(function()
    return nil
  end)
end

---Combine a sequence of parsers
---@param parsers Parser[]
---@return Parser
local function sequence(parsers)
  local parser_fn = function(state)
    local results = {}
    local next_state = state
    for _, parser in ipairs(parsers) do
      next_state = parser(next_state)
      if next_state.error then
        break
      end
      results[#results + 1] = next_state.result
    end

    return next_state:with_result(results)
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

---Combine two or more parsers and grab the left/first result
---@param parsers Parser[]
---@return Parser
local function left(parsers)
  return sequence(parsers):map(function(results)
    return results[1]
  end)
end

---Combine two or more parsers and grab the right/last result
---@param parsers Parser[]
---@return Parser
local function right(parsers)
  return sequence(parsers):map(function(results)
    return results[#parsers]
  end)
end

---Combine two or more parsers and grab the nth result
---@param parsers Parser[]
---@param n integer
---@return Parser
local function nth(parsers, n)
  return sequence(parsers):map(function(results)
    return results[n]
  end)
end

---Accept first successful parser
---@param parsers Parser[]
---@return Parser
local function choice(parsers)
  local parser_fn = function(state)
    for _, parser in ipairs(parsers) do
      local next_state = parser(state)
      if not next_state.error then
        return next_state
      end
    end

    return state:with_error "choice: unable to match with any parser"
  end

  return Parser:new(parser_fn)
end

---Apply a parser zero or more times greedily
---@param parser Parser
---@return Parser
local function many(parser)
  local parser_fn = function(state)
    local results = {}
    local next_state = state

    while true do
      next_state = parser(next_state)
      if next_state.error then
        break
      end

      results[#results + 1] = next_state.result
    end

    return next_state:succeed(results)
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
  local parser_fn = function(state)
    local results = {}
    local next_state = parser(state)

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

    return next_state:succeed(results)
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
    local parser_fn = function(state)
      local results = {}
      local next_state = state

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

      return next_state:succeed(results)
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
    local parser_fn = function(state)
      local results = {}
      local next_state = state

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
        return state:with_error "separated_by1: unable to capture any results"
      end

      return next_state:succeed(results)
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
---@param result_if_failed any
---@return Parser
function Parser:maybe(result_if_failed)
  local parser_fn = function(state)
    local next_state = self(state)
    if next_state.error then
      return state:with_result(result_if_failed)
    end

    return next_state
  end

  return Parser:new(parser_fn)
end

---Parser to check for end of input
local eof = Parser:new(function(state)
  if #TARGET < state.index then
    return state:with_result(nil)
  end

  return state:with_error "eof: not end of file"
end)

---Parser that puts current state to value and nothing more
local peek = Parser:new(function(state)
  if #TARGET < state.index then
    return state:with_error "peek: unexpected end of input"
  end

  return state:with_result(TARGET:sub(state.index, state.index))
end)

---Parser that accepts next input
local shift = Parser:new(function(state)
  if #TARGET < state.index then
    return state:with_error "shift: unexpected end of input"
  end

  return state:shift()
end)

---Parser to insert current line number
local line_number = Parser:new(function(state)
  local count = state.prev_newlines.count

  for i = state.prev_newlines.index, state.index do
    if TARGET:sub(i, i) == "\n" then
      count = count + 1
    end
  end

  local new_state = state:with_result(count)
  new_state.prev_newlines = { index = state.index, count = count }
  return new_state
end)

---Apply a result predicate on a parser
---@param predicate fun(result): boolean
---@param error string? The error message if the predicate fails
---@return fun(parser: Parser): Parser
local function filter(predicate, error)
  return function(parser)
    local parser_fn = function(state)
      local next_state = parser(state)
      if next_state.error then
        return next_state
      end

      if predicate(next_state.result) then
        return next_state
      end

      return state:with_error(error or "filter: predicate returned false")
    end

    return Parser:new(parser_fn)
  end
end

---Filter on parser with predicate
---@param predicate fun(result): boolean
---@param error string? The error message if the predicate fails
---@return Parser
function Parser:filter(predicate, error)
  return filter(predicate, error)(self)
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
  local parser_fn = function(state)
    local parser = parser_thunk()
    return parser(state)
  end

  return Parser:new(parser_fn)
end

local pc = {}

pc.eof = eof
pc.peek = peek
pc.shift = shift
pc.line_number = line_number
pc.filter = filter

pc.left = left
pc.first = left
pc.right = right
pc.last = right
pc.nth = nth

pc.between = between
pc.between_inclusive = between_inclusive
pc.between_inclusive_flat = between_inclusive_flat
pc.separated_by = separated_by
pc.separated_by1 = separated_by1

pc.choice = choice
pc.many = many
pc.many_flat = many_flat
pc.many1 = many1
pc.many1_flat = many1_flat
pc.sequence = sequence
pc.sequence_flat = sequence_flat

pc.lazy = lazy

return pc
