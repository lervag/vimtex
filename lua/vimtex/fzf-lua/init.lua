local M = {}

-- A mapping of item types to Ansi color codes.
-- The values must correspond to the keys in `M.ansi_escseq`, cf.:
-- https://github.com/ibhagwan/fzf-lua/blob/caee13203d6143d691710c34f85ad6441fe3f535/lua/fzf-lua/utils.lua#L555C1-L574C1
local color_map = {
  content = "clear",
  include = "blue",
  label = "green",
  todo = "red",
}

---Format the section/subsection/... numbers corresponding to an item into a string.
---@param n table The TOC entry
---@return string number
local function format_number(n)
  local num = {
    n.chapter ~= 0 and n.chapter or nil,
    n.section ~= 0 and n.section or nil,
    n.subsection ~= 0 and n.subsection or nil,
    n.subsubsection ~= 0 and n.subsubsection or nil,
    n.subsubsubsection ~= 0 and n.subsubsubsection or nil,
  }
  num = vim.tbl_filter(function(t)
    return t ~= nil
  end, num)
  if vim.tbl_isempty(num) then
    return ""
  end

  -- Convert appendix items numbers to letters (e.g. 1 -> A, 2 -> B)
  if n.appendix ~= 0 then
    num[1] = string.char(num[1] + 64)
  end

  num = vim.tbl_map(function(t)
    return string.format(t)
  end, num)

  return table.concat(num, ".")
end

---Runs fzf-lua to select and navigate to from a list of TOC items.
---
---@param options table? Available options: 
---                      - layers: The layers to filter. Can be a substring of `ctli`
---                        corresponding to content, todos, labels, and includes.
---                      - fzf_opts: list of options for fzf_exec
---@return nil
M.run = function(options)
  local layers = "ctli"
  if options ~= nil and options["layers"] ~= nil then
    layers = options["layers"]
    options["layers"] = nil
  end

  local fzf = require "fzf-lua"
  local ansi = fzf.utils.ansi_codes

  local entries = vim.fn["vimtex#parser#toc"]()
  entries = vim.tbl_filter(function(t)
    return string.find(layers, t.type:sub(1, 1)) ~= nil
  end, entries)

  local fzf_entries = vim.tbl_map(function(v)
    return string.format(
      "%s:%d####%s####%s",
      v.file,
      v.line and v.line or 0,
      ansi[color_map[v.type]](v.title),
      format_number(v.number)
    )
  end, entries)

  local fzfoptions = {
    ["--delimiter"] = "####",
    ["--with-nth"] = "{2} {3}",
  }
  if options ~= nil and options["fzf_opts"] ~= nil then
    fzfoptions = vim.tbl_extend('force', fzfoptions, options["fzf_opts"])
  end

  fzf.fzf_exec(fzf_entries, {
    fzf_opts = fzfoptions,
    actions = {
      default = function(selection, o)
        local s = vim.tbl_map(function(t)
          return vim.split(t, "####")[1]
        end, selection)
        fzf.actions.file_edit(s, o)
      end,
    },
  })
end

return M
