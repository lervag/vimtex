-- VimTeX - LaTeX plugin for Vim
--
-- Maintainer: Karl Yngve Lervåg
-- Email:      karl.yngve@gmail.com
--

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
---@return nil
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

---Read content of file filename
---@param filename string
---@return string[]
local function readfile(filename)
  local f = assert(io.open(filename, "r"))
  local lines = vim.split(f:read "*a", "\n")
  f:close()

  return lines
end

local M = {}

---Parse the specified bibtex file
---The parser adheres to the format description found here:
---http://www.bibtex.org/Format/
---@param filename string
---@return table[]
M.parse = function(filename)
  if not vim.fn.filereadable(filename) then
    return {}
  end
  local items = {}
  local strings = {}

  local item = {}
  local key, value
  for lnum, line in ipairs(readfile(filename)) do
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

return M
