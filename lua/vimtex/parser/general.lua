-- VimTeX - LaTeX plugin for Vim
--
-- Maintainer: Karl Yngve Lervåg
-- Email:      karl.yngve@gmail.com
--

local pc = require "vimtex.parser.combinators"

---Create parser to match a specified character
---@param character string
---@return Parser
local function char(character)
  return pc.shift:filter(function(result)
    return result == character
  end, "char: unable to match '" .. character .. "'")
end

---Create parser to match anything that is not a specified character
---@param character string
---@return Parser
local function not_char(character)
  return pc.shift:filter(function(result)
    return result ~= character
  end, "not char: matched '" .. character .. "'")
end

---Create parser to match anything that is not a specified character
---@param characters string[]
---@return Parser
local function not_chars(characters)
  return pc.shift:filter(function(result)
    for _, c in ipairs(characters) do
      if result == c then
        return false
      end
    end

    return true
  end, "not chars: matched one of '" .. table.concat(characters) .. "'")
end

---Create parser to match a specified string
---@param input_string string
---@return Parser
local function str(input_string)
  local parsers = {}
  for i = 1, #input_string do
    parsers[#parsers + 1] = char(input_string:sub(i, i))
  end

  return pc.sequence_flat(parsers):map_error(function(_, index)
    return "str: unable to match '" .. input_string .. "' at index " .. index
  end)
end

---Parser to match a specified letter
local letter = pc.shift:filter(function(result)
  local b = string.byte(result)
  return (b >= 65 and b <= 90) or (b >= 97 and b <= 122)
end, "letter: did not match")

---Parser to match a specified digit
local digit = pc.shift:filter(function(result)
  local b = string.byte(result)
  return b >= 48 and b <= 57
end, "digit: did not match")

---Parser to match white space
local whitespace = pc.shift:filter(function(result)
  local b = string.byte(result)
  return (b >= 9 and b <= 13) or b == 32
end, "whitespace: did not match")

local parsers = {}

-- General
parsers.char = char
parsers.not_char = not_char
parsers.not_chars = not_chars
parsers.str = str

-- Text
parsers.letter = letter
parsers.letters = pc.many1_flat(letter)
parsers.alnum = pc.choice({ letter, digit }):map_error(function()
  return "alnum: did not match"
end)
parsers.alnums = pc.many1_flat(parsers.alnum)
parsers.whitespace = whitespace
parsers.whitespaces = pc.many1_flat(whitespace)
parsers.whitespaces_maybe = pc.many_flat(whitespace)
parsers.nl = char "\n"
parsers.not_nl = not_char "\n"
parsers.dot = char "."
parsers.eq = char "="
parsers.colon = char ":"
parsers.comma = char ","
parsers.at = char "@"
parsers.dq = char '"'
parsers.dq_escaped = char "\\" .. char '"'
parsers.not_dq = not_char '"'
parsers.sq = char "'"
parsers.lb = char "{"
parsers.rb = char "}"
parsers.nb = not_chars { "{", "}" }
parsers.lp = char "("
parsers.rp = char ")"
parsers.np = not_chars { "(", ")" }

-- Numbers
parsers.digit = digit
parsers.digits = pc.many1_flat(digit)
parsers.decimal = pc.choice {
  pc.sequence_flat { parsers.digits, parsers.dot, parsers.digits },
  pc.sequence_flat { parsers.digits, parsers.dot },
  pc.sequence_flat { parsers.dot, parsers.digits },
}
parsers.integer = parsers.digits:map(function(s)
  return tonumber(s) or 0
end)
parsers.float = parsers.decimal:map(function(s)
  return tonumber(s) or 0
end)
parsers.number = pc.choice { parsers.integer, parsers.float }

return parsers
