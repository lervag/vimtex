local M = {}

---Attach a buffer listener that sends incremental changes to TeXpresso.
---Returns a function that disables the listener on the next change event.
---@return fun(): nil
function M.attach()
  local stopped = false
  vim.api.nvim_buf_attach(0, false, {
    on_lines = function(_, buf, _tick, first, oldlast, newlast)
      if stopped then
        return true
      end
      local compiler = vim.b[buf].vimtex and vim.b[buf].vimtex.compiler
      if not compiler or not compiler.job then
        return
      end
      local path = vim.api.nvim_buf_get_name(buf)
      local count = oldlast - first
      local lines = ""
      if first < newlast then
        lines = table.concat(
          vim.api.nvim_buf_get_lines(buf, first, newlast, false),
          "\n"
        ) .. "\n"
      end
      local msg = vim.json.encode { "change-lines", path, first, count, lines }
      vim.api.nvim_chan_send(compiler.job, msg .. "\n")
    end,
  })
  return function()
    stopped = true
  end
end

return M
