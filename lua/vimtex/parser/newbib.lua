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

---@type string
local FILE

local identifier = g.alnum
  .. pc.many_flat(pc.shift:filter(function(result)
    return result:match "[%w.:/_-]"
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
  pc.sequence({
    g.whitespaces_maybe,
    g.at,
    g.letters,
  }):map(function(result)
    return result[3]
  end),
  pc.between(g.whitespaces_maybe + g.lb, g.whitespaces_maybe + g.rb)(
    pc.sequence {
      pc.right { g.whitespaces_maybe, pc.line_number },
      pc.left({ identifier, g.whitespaces_maybe, g.comma }):maybe "",
      pc.separated_by(g.whitespaces_maybe + g.comma)(tag_pair),
      pc.right { g.whitespaces_maybe, value_braced_content },
    }
  ),
}):map(function(results)
  local type = results[1]
  local lnum = results[2][1]
  local key = results[2][2]
  local tag_pairs = results[2][3]
  local unparsed_content = results[2][4]:gsub("^%s*", ""):gsub("%s*$", "")

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
  g.whitespaces_maybe,
  g.char "%",
  pc.many_flat(g.not_nl),
}):ignore()

local parser = pc.many1(pc.choice { entry, comment }):map(function(results)
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

local M = {}

---Parse bib entries from an input string
---@param input_string string
---@return BibReference[]
function M.parse(input_string)
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
function M.parse_file(filename)
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
