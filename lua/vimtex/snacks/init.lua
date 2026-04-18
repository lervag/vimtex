local utils = require "vimtex.utils.picker"

---@class VimtexSnacksOptions: snacks.picker.Config
---@field layers? string The layers to filter. Can be a substring of "ctli"
---                      corresponding to content, todos, labels, and includes.

---@class SnacksPickerStub
---@field sources table<string, VimtexSnacksOptions>

local M = {}

M.source = {
  source = "vimtex_toc",
  finder = function(opts)
    local layers = (opts and opts.layers) or "ctli"

    local ok, entries = pcall(vim.fn["vimtex#parser#toc"])
    if not ok then
      return {}
    end

    ---@cast entries table
    entries = vim.tbl_filter(function(t)
      return string.find(layers, t.type:sub(1, 1)) ~= nil
    end, entries)

    return vim.tbl_map(function(v)
      local section_num = utils.format_number(v.number)
      local display = section_num ~= "" and (section_num .. " " .. v.title)
        or v.title

      return {
        text = display,
        file = v.file,
        pos = { v.line or 1, 0 },
        type = v.type,
      }
    end, entries)
  end,
  format = "text",
  preview = "file",
  confirm = "jump",
}

function M.register()
  local ok, picker = pcall(require, "snacks.picker")
  if ok and picker then
    ---@diagnostic disable-next-line: undefined-field
    picker.sources.vimtex_toc = M.source
  end
end

function M.toc(options)
  local ok, picker = pcall(require, "snacks.picker")
  if ok and picker then
    ---@diagnostic disable-next-line: call-non-callable
    return picker("vimtex_toc", options)
  end
end

return M
