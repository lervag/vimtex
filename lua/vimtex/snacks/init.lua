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

    local entries = vim.fn["vimtex#parser#toc"]()
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
  preview = function(ctx)
    if ctx.item.file then
      Snacks.picker.preview.file(ctx)
    else
      ctx.preview:reset()
      ctx.preview:set_title "No preview"
    end
  end,
  confirm = {
    "yank",
    function(picker, item)
      picker:close()
      vim.cmd.edit(item.file)
      vim.api.nvim_win_set_cursor(0, item.pos)
      vim.cmd.normal "zz"
    end,
  },
}

function M.register()
  local ok, picker = pcall(require, "snacks.picker")
  if not ok then
    return
  end

  ---@cast picker SnacksPickerStub
  if not picker.sources then
    return
  end

  picker.sources.vimtex_toc = M.source
end

function M.toc(options)
  local ok, picker = pcall(require, "snacks.picker")
  ---@cast picker SnacksPickerStub

  if ok and picker and picker.sources then
    if not picker.sources.vimtex_toc then
      M.register()
    end

    ---@diagnostic disable-next-line: call-non-callable
    return picker("vimtex_toc", options)
  end
end

return M
