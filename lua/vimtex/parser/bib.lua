-- VimTeX - LaTeX plugin for Vim
--
-- Maintainer: Karl Yngve Lervåg
-- Email:      karl.yngve@gmail.com
--

local pc = require "vimtex.parser.combinators"
local g = require "vimtex.parser.general"

---@class BibReference
---@field type string
---@field key string
---@field source_lnum integer
---@field source_file string
---@field unparsed_content string?

---------------------------------
-- Parser generator elements here
---------------------------------

---@type string
local FILE

local identifier = g.alnum
  .. pc.many_flat(pc.shift:filter(function(result)
    local b = string.byte(result)
    return (b >= 45 and b <= 58)
      or (b >= 65 and b <= 90)
      or (b == 95)
      or (b >= 97 and b <= 122)
  end, "identifier: did not match"))

local value_quoted_single =
  pc.between(g.dq, g.dq)(pc.many_flat(pc.choice { g.dq_escaped, g.not_dq }))

local value_quoted = pc.separated_by1(
  pc.sequence { g.whitespaces_maybe, g.char "#", g.whitespaces_maybe }
)(pc.choice {
  value_quoted_single,
  identifier:map(function(result)
    return "##" .. result .. "##"
  end),
}):map(table.concat)

local value_braced_inc
value_braced_inc = pc.sequence_flat {
  g.lb,
  pc.many_flat(pc.choice {
    g.nb,
    pc.lazy(function()
      return value_braced_inc
    end),
  }),
  g.rb,
}
local value_braced_content = pc.many_flat(pc.choice { g.nb, value_braced_inc })
local value_braced = pc.between(g.lb, g.rb)(value_braced_content)

local value_parser = pc.choice { value_braced, g.digits, value_quoted }

local tag_pair = pc.sequence({
  g.whitespaces_maybe,
  identifier,
  g.whitespaces_maybe,
  g.eq,
  g.whitespaces_maybe,
  value_parser,
}):map(function(result)
  return { result[2], result[6] }
end)

local entry = pc.sequence({
  pc.between(g.at, g.whitespaces_maybe)(g.letters),
  pc.between(g.lb, g.rb)(
    pc.sequence {
      pc.line_number,
      g.whitespaces_maybe,
      pc.left({ identifier, g.whitespaces_maybe, g.comma }):maybe "",
      pc.separated_by(g.whitespaces_maybe + g.comma)(tag_pair),
      pc.right { g.whitespaces_maybe, value_braced_content },
    }
  ),
}):map(function(results)
  local type = results[1]
  local lnum = results[2][1]
  local key = results[2][3]
  local tag_pairs = results[2][4]
  local unparsed_content = results[2][5]:gsub("^%s*", ""):gsub("%s*$", "")

  local tag_pairs_parsed = {}
  for _, pair in ipairs(tag_pairs) do
    tag_pairs_parsed[pair[1]] = pair[2]
  end

  local bibref = {
    type = type,
    source_file = FILE,
    source_lnum = lnum,
    key = #key > 0 and key or nil,
    unparsed_content = #unparsed_content > 0 and unparsed_content or nil,
  }

  return vim.tbl_extend("keep", bibref, tag_pairs_parsed)
end)

local comment = pc.sequence({
  g.char "%",
  pc.many_flat(g.not_nl),
}):ignore()

local parser = pc.many1(pc.right {
  g.whitespaces_maybe,
  pc.choice { entry, comment },
}):map(function(results)
  local string_map = {}
  for _, bibstr in
    ipairs(vim.tbl_filter(function(e)
      return e.type == "string"
    end, results))
  do
    for key, value in pairs(bibstr) do
      if key ~= "type" then
        string_map[key] = value
      end
    end
  end

  ---@type BibReference[]
  local references = vim.tbl_filter(function(e)
    return e.type ~= "string" and e.type ~= "comment" and e.type ~= "preamble"
  end, results)

  for string_name, string_value in pairs(string_map) do
    for _, reference in ipairs(references) do
      for name, value in pairs(reference) do
        if type(value) == "string" then
          reference[name] =
            value:gsub("##" .. vim.pesc(string_name) .. "##", string_value)
        end
      end
    end
  end

  return references
end)

---------------------------------
-- Manual parser elements here
---------------------------------

---Get the index for an end of pattern match or -1
---@param string string
---@param pattern string
---@param start integer
---@return integer
local function matchend(string, pattern, start)
  local _, idx = string:find(pattern, start + 1)
  return idx or -1
end

---Parse input line as middle or tail part of an entry
---@param item table The current entry
---@param line string The new line to parse
---@return table item Current entry with updated body
local function parse_tail(item, line)
  item.level = item.level
    + line:gsub("[^{]", ""):len()
    - line:gsub("[^}]", ""):len()
  if item.level > 0 then
    item.body = item.body .. line
  else
    item.body = item.body .. line:match(".*}"):sub(1, -2)
    item.parsed = true
  end

  return item
end

---Parse the head part of an entry
---@param file string The path to the bibtex file-asd
---@param lnum integer The line number for the entry
---@param line string The line content of the entry
---@return table item Current entry with updated body
local function parse_head(file, lnum, line)
  local type, body = line:match "^@(%w+)%s*{%s*(.*)"
  if not type then
    return {}
  end

  type = type:lower()
  if type == "preamble" or type == "comment" then
    return {}
  end

  return parse_tail({
    level = 1,
    body = "",
    source_file = file,
    source_lnum = lnum,
    type = type,
  }, body)
end

---Parse the value part of a bib entry tag until separating comma or end.
---The value is likely a quoted string and may possibly be a concatenation of
---strings. The value may also contain abbreviations defined by @string
---entries.
---@param body string
---@param head integer
---@param strings table<string, string>
---@param pre_value string
---@return string value The parsed value
---@return integer new_head New head position
local function get_tag_value_concat(body, head, strings, pre_value)
  local value = ""
  local new_head = head

  local first_char = body:sub(head + 1, head + 1)
  if first_char == "{" then
    local sum = 1
    local i = head + 1
    local n = #body

    while sum > 0 and i <= n do
      local char = body:sub(i + 1, i + 1)
      if char == "{" then
        sum = sum + 1
      elseif char == "}" then
        sum = sum - 1
      end

      i = i + 1
    end

    value = body:sub(head + 2, i - 1)
    new_head = matchend(body, "^%s*", i)
  elseif first_char == '"' then
    local index = body:find('[^\\]"', head + 1)
    if index < 0 then
      return "bib.lua: get_tag_value_concat failed", -1
    end

    value = body:sub(head + 2, index)
    new_head = matchend(body, "^%s*", index + 1)
  elseif first_char:match "%w" then
    value = body:match("^%w[0-9a-zA-Z_-]*", head + 1)
    new_head = matchend(body, "^%s*", head + #value)
    value = strings[value] or ("@(" .. value .. ")")
  end

  if body:sub(new_head + 1, new_head + 1) == "#" then
    new_head = matchend(body, "^%s*", new_head + 1)
    return get_tag_value_concat(body, new_head, strings, pre_value .. value)
  end

  return pre_value .. value, matchend(body, "^,%s*", new_head)
end

---Parse the value part of a bib entry tag until separating comma or end.
---@param body string
---@param head integer
---@param strings table<string, string>
---@return string value The parsed value
---@return integer new_head New head position
local function get_tag_value(body, head, strings)
  -- First check if the value is simply a number
  local value = body:match("^%d+", head + 1)
  if value then
    -- -1 here
    local new_head = matchend(body, "^%s*,%s*", head + #value)
    return value, new_head
  end

  return get_tag_value_concat(body, head, strings, "")
end

---Parse tag from string (e.g. author, title, etc)
---@param body string Raw text in which to find tag
---@param head integer Where to start search for tag
---@return string tag_name The parsed tag
---@return integer new_head New head position
local function get_tag_name(body, head)
  local _, new_head, match = body:find("^([0-9a-zA-Z_:-]+)%s*=%s*", head + 1)
  if not new_head then
    return "", -1
  end

  return match:lower(), new_head
end

---Parse an item
---@param item table
---@param strings table<string, string>
---@return BibReference?
local function parse_item(item, strings)
  local key, body = item.body:match "^([^,%s]+)%s*,%s*(.*)"
  if not key then
    return nil
  end

  item.key = key
  item.level = nil
  item.parsed = nil
  item.body = nil

  local tag = ""
  local value
  local head = 0
  while head >= 0 do
    if #tag == 0 then
      tag, head = get_tag_name(body, head)
      if tag == "key" then
        tag = "keyfield"
      end
    else
      value, head = get_tag_value(body, head, strings)
      item[tag] = value
      tag = ""
    end
  end

  return item
end

---Parse a string entry
---@param raw_string string
---@return string key
---@return string value
local function parse_string(raw_string)
  local key, value = raw_string:match [[^%s*([^%s]+)%s*=%s*"(.*)"%s*$]]
  if key then
    return key, value
  end

  key, value = raw_string:match "^%s*([^%s]+)%s*=%s*{(.*)}%s*$"
  if key then
    return key, value
  end

  return "", ""
end

local M = {}

---Parse the specified bibtex file
---The parser adheres to the format description found here:
---http://www.bibtex.org/Format/
---@param filename string
---@return BibReference[]
function M.parse(filename)
  if not vim.fn.filereadable(filename) then
    return {}
  end

  local f = assert(io.open(filename, "r"))
  local lines = vim.split(f:read "*a", "\n")
  f:close()

  local items = {}
  local strings = {}

  local item = {}
  local key, value
  for lnum, line in ipairs(lines) do
    if vim.tbl_isempty(item) then
      item = parse_head(filename, lnum, line)
    else
      item = parse_tail(item, line)
    end

    if item.parsed then
      if item.type == "string" then
        key, value = parse_string(item.body)
        if key ~= "" then
          strings[key] = value
        end
      else
        items[#items + 1] = item
      end
      item = {}
    end
  end

  local result = {}
  for _, x in ipairs(items) do
    table.insert(result, parse_item(x, strings))
  end
  return result
end

---Parse bib entries from an input string
---@param input_string string
---@return BibReference[]
function M.pc_parse_string(input_string)
  FILE = "__string__"
  local parsed = parser:run(input_string)
  if parsed.error then
    return {}
  else
    return parsed.result
  end
end

---Parse bib entries from a specified file
---@param filename string
---@return BibReference[]
function M.pc_parse_file(filename)
  FILE = filename
  local file = assert(io.open(filename, "r"), "Could not read file")
  local parsed = parser:run(file:read "*a")
  file:close()

  if parsed.error then
    return {}
  else
    return parsed.result
  end
end

return M
