-- VimTeX - LaTeX plugin for Vim
--
-- Maintainer: Karl Yngve Lervåg
-- Email:      karl.yngve@gmail.com
--

local M = {}

---@param title string?
function M.time(title)
  local t1 = vim.uv.hrtime()/1000000000
  if M.t0 then
    if title then
      print("dt " .. title .. " = " .. (t1 - M.t0))
    else
      print("dt = " .. (t1 - M.t0))
    end
  end
  M.t0 = t1
end

return M
