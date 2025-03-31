local M = {}

-- the mapping of item types to ansi color codes
-- Can be any of the keys in
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
    n["chapter"] ~= 0 and n["chapter"] or nil,
    n["section"] ~= 0 and n["section"] or nil,
    n["subsection"] ~= 0 and n["subsection"] or nil,
    n["subsubsection"] ~= 0 and n["subsubsection"] or nil,
    n["subsubsubsection"] ~= 0 and n["subsubsubsection"] or nil,
  }
  if vim.tbl_isempty(num) then
    return ""
  end
  num = vim.tbl_filter(function(t)
    return t ~= nil
  end, num)

  -- for appendix items, we convert them into a letter 1 -> A, 2 -> B, etc.
  if n.appendix ~= 0 then
    local ind = table.sort(vim.tbl_keys(num))[1]
    num[ind] = string.char(num[ind] + 64)
  end

  num = vim.tbl_map(function(t)
    return string.format(t)
  end, num)

  return table.concat(num, ".")
end


---Runs Fzf-Lua for getting a list of TOC items. Upon selection, opens the file(s) at the correct lines.
---@param layers string the layers to filter. Can be a substring of `ctli` corresponding to
---                     content, todos, labels, and includes.
---@return nil
M.run = function(layers)
  if layers == nil then
    layers = "ctli"
  end

  local fzf = require "fzf-lua"
  local ansi = fzf.utils.ansi_codes

  local entries = vim.fn["vimtex#parser#toc"]()
  entries = vim.tbl_filter(function(t)
    return string.find(layers, t.type:sub(1,1)) ~= nil
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

  fzf.fzf_exec(fzf_entries, {
    fzf_opts = {
      ["--delimiter"] = "####",
      ["--with-nth"] = "{2} {3}",
    },
    actions = {
      ["default"] = function(selection, o)
        local s = vim.tbl_map(function(t)
          return vim.split(t, "####")[1]
        end, selection)
        fzf.actions.file_edit(s, o)
      end,
    },
  })
end

return M
