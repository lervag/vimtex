local utils = require "vimtex.utils.picker"
local fzf = require "fzf-lua"

---@type table<string, fun(string: string):string>
local ansi = fzf.utils.ansi_codes

-- A mapping of item types to Ansi color codes.
-- The values must correspond to the keys in `M.ansi_escseq`, cf.:
-- https://github.com/ibhagwan/fzf-lua/blob/caee13203d6143d691710c34f85ad6441fe3f535/lua/fzf-lua/utils.lua#L555C1-L574C1
local color_map = {
  content = "clear",
  include = "blue",
  label = "green",
  todo = "red",
}

local M = {}

---@class VimtexFzfLuaOptions
---@field layers? string The layers to filter. Can be a substring of "ctli"
---                      corresponding to content, todos, labels, and includes.
---@field fzf_opts? table<string, string> list of options for fzf_exec

---Runs fzf-lua to select and navigate to from a list of TOC items.
---
---@param options VimtexFzfLuaOptions?
---@return nil
M.run = function(options)
  local layers = options and options.layers or "ctli"
  local fzf_options = vim.tbl_extend("force", {
    ["--delimiter"] = "####",
    ["--with-nth"] = "{2} {3}",
  }, options and options.fzf_opts or {})

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
      utils.format_number(v.number)
    )
  end, entries)

  fzf.fzf_exec(fzf_entries, {
    fzf_opts = fzf_options,
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
