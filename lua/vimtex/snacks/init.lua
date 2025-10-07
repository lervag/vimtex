local utils = require "vimtex.utils.picker"
local snacks = require "snacks"

local M = {}

---@class VimtexSnacksOptions
---@field layers? string The layers to filter. Can be a substring of "ctli"
---                      corresponding to content, todos, labels, and includes.
---@field preview? snacks.picker.Preview
---@field confirm? snacks.picker.Action.spec

---Runs Snacks picker to select and navigate to from a list of TOC items.
---
---@param options VimtexSnacksOptions?
---@return nil
M.toc = function(options)
  local layers = options and options.layers or "ctli"
  local preview = options and options.preview
    or function(ctx)
      if ctx.item.file then
        snacks.picker.preview.file(ctx)
      else
        ctx.preview:reset()
        ctx.preview:set_title "No preview"
      end
    end
  local confirm = options and options.confirm
    or function(picker, item)
      picker:close()
      vim.cmd.edit(item.file)
      vim.api.nvim_win_set_cursor(0, item.pos)
      vim.cmd.normal "zz"
    end

  local entries = vim.fn["vimtex#parser#toc"]()
  entries = vim.tbl_filter(function(t)
    return string.find(layers, t.type:sub(1, 1)) ~= nil
  end, entries)

  local items = vim.tbl_map(function(v)
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

  snacks.picker.pick {
    source = "vimtex_toc",
    items = items,
    format = "text",
    layout = { preset = "ivy" },
    preview = preview,
    confirm = confirm,
  }
end

return M
