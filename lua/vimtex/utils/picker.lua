local M = {}

---Format the section numbers corresponding to an item into a string.
---
---@param n table The TOC entry
---@return string number
M.format_number = function(n)
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

return M
