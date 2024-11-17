-- VimTeX - LaTeX plugin for Vim
--
-- Maintainer: Karl Yngve Lervåg
-- Email:      karl.yngve@gmail.com
--

local pc = require "vimtex.parser.combinators"
local g = require "vimtex.parser.general"

---@class BibString
---@field type "string"
---@field name string
---@field value string

---@class BibComment
---@field type "comment"
---@field comment string

---@class BibPreamble
---@field type "preamble"
---@field preamble string

---@class BibReference
---@field type string
---@field key string
---@field source_lnum integer
---@field source_file string

---@class BibReferenceFailed: BibReference
---@field unparsed_content string

---@type string
local FILE

local identifier = g.alnum
  .. pc.many_flat(pc.shift:filter(function(result)
    return result:match "[%w.:/_-]"
  end, "identifier: did not match"))

local value_quoted_single =
  pc.between(g.dq, g.dq)(pc.many_flat(pc.choice { g.dq_escaped, g.not_dq }))

local value_quoted = pc.separated_by1(
  g.whitespaces_maybe .. g.char "#" .. g.whitespaces_maybe
)(pc.choice {
  identifier:map(function(result)
    return "##" .. result .. "##"
  end),
  value_quoted_single,
})
  :map(table.concat)

local value_braced_inc
value_braced_inc = pc.sequence_flat {
  g.lb,
  pc.many_flat(pc.choice {
    pc.lazy(function()
      return value_braced_inc
    end),
    g.not_rb,
  }),
  g.rb,
}
local value_braced_content =
  pc.many_flat(pc.choice { value_braced_inc, g.not_rb })
local value_braced = pc.between(g.lb, g.rb)(value_braced_content)

local value_parser = pc.right(
  g.whitespaces_maybe,
  pc.choice { g.digits, value_quoted, value_braced }
)

local tag_pair = pc.sequence({
  g.whitespaces_maybe,
  identifier,
  g.whitespaces_maybe,
  g.eq,
  value_parser,
}):map(function(result)
  return { result[2], result[5] }
end)

---Parse an entry with the provided content parser
---@param content_parser Parser Content parser for the entry
---@param type_name string? Entry name filter
---@return Parser
local function entry_parser(content_parser, type_name)
  ---@type Parser
  local header
  if type_name then
    header = pc.right(g.at, g.letters):filter(function(value)
      return value:lower() == type_name:lower()
    end)
  else
    header = pc.right(g.at, g.letters)
  end
  return pc.sequence {
    header,
    pc.between(g.whitespaces_maybe + g.lb, g.whitespaces_maybe + g.rb)(
      content_parser
    ),
  }
end

local commentstring = (g.whitespaces_maybe .. g.char "%" .. pc.many_flat(
  g.not_nl
)):map(function()
  return nil
end)

local bibstring = entry_parser(tag_pair, "string"):map(function(result)
  ---@type BibString
  return {
    type = "string",
    name = result[2][1],
    value = result[2][2],
  }
end)

local bibcomment = entry_parser(value_braced_content, "comment"):map(
  function(result)
    ---@type BibComment
    return {
      type = "comment",
      comment = result[2],
    }
  end
)

local bibpreamble = entry_parser(value_braced_content, "preamble"):map(
  function(result)
    ---@type BibPreamble
    return {
      type = "preamble",
      preamble = result[2],
    }
  end
)

local bibreference = entry_parser(pc.sequence {
  g.whitespaces_maybe,
  pc.line_number,
  identifier,
  pc.separated_by_preceeding(g.whitespaces_maybe .. g.comma)(tag_pair),
}):map(function(result)
  local pairs = {}
  for _, pair in ipairs(result[2][4]) do
    pairs[pair[1]] = pair[2]
  end

  ---@type BibReference
  local bibref = {
    type = result[1],
    key = result[2][3],
    source_lnum = result[2][2],
    source_file = FILE,
  }

  return vim.tbl_extend("keep", bibref, pairs)
end)

local bibreference_failed = entry_parser(pc.sequence {
  g.whitespaces_maybe,
  pc.line_number,
  identifier,
  pc.separated_by_preceeding(g.whitespaces_maybe .. g.comma)(tag_pair),
  value_braced_content,
}):map(function(result)
  local pairs = {}
  for _, pair in ipairs(result[2][4]) do
    pairs[pair[1]] = pair[2]
  end

  ---@type BibReferenceFailed
  local bibref = {
    type = result[1],
    key = result[2][3],
    source_lnum = result[2][2],
    source_file = FILE,
    unparsed_content = result[2][5]:gsub("^%s*", ""):gsub("%s*$", ""),
  }

  return vim.tbl_extend("keep", bibref, pairs)
end)

local entry = pc.choice {
  commentstring,
  bibstring,
  bibcomment,
  bibpreamble,
  bibreference,
  bibreference_failed,
}

local parse_string = pc.many1(pc.right(g.whitespaces_maybe, entry))
  :map(function(results)
    local string_map = {}
    for _, bibstr in
      ipairs(vim.tbl_filter(function(e)
        return e.type == "string"
      end, results))
    do
      string_map[bibstr.name] = bibstr.value
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
  local parsed = parse_string:run(input_string)
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
  -- local profiler = require "vimtex.parser.profiler"
  -- profiler.start()
  FILE = filename
  local file = assert(io.open(filename, "r"), "Could not read file")
  local parsed = parse_string:run(file:read "*a")
  file:close()
  -- profiler.stop()
  -- local log = assert(io.open("trace-new.log", "w"), "Could not read file")
  -- log:write(profiler.report(40))
  -- log:close()

  if parsed.error then
    return {}
  else
    return parsed.result
  end
end

return M
