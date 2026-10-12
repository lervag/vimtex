-- Live preview of the LaTeX code under the cursor with the vim.ui.img API.
--
-- Only one preview is shown at a time. The Vimscript side
-- (autoload/vimtex/preview.vim) finds the fragment and builds the LaTeX
-- document; this module compiles it to a PNG, caches the result, and places
-- the image below the fragment. Virtual lines are used to make room for the
-- image, since the image itself is drawn by the terminal on top of the grid.

local M = {}

local ns = vim.api.nvim_create_namespace "vimtex_preview"
local group = vim.api.nvim_create_augroup("vimtex_preview", { clear = true })
local timer = assert(vim.uv.new_timer())

---Buffers with an active preview, mapped to the TeX engine
---@type table<integer, string?>
local active = {}

---Documents that failed to compile, keyed by hash
---@type table<string, boolean>
local failed = {}

---The current preview
---@class vimtex.preview.State
---@field buf? integer
---@field win? integer
---@field lnum_start? integer
---@field lnum_end? integer
---@field key? string Hash of the wanted document
---@field shown? { bytes: string, rows: integer, size: table } Displayed image
---@field img? integer Image id from vim.ui.img
---@field line_count? integer Number of lines in the buffer
local state = {}

---The running compilation, if any
---@type { key: string, obj: vim.SystemObj }?
local job = nil

---Where the current preview is shown
---@class vimtex.preview.Target
---@field buf integer
---@field win integer
---@field lnum integer Last line of the fragment
---@field info vim.fn.getwininfo.ret.item

---@return vimtex.preview.Target?
local function get_target()
  local buf, win, lnum = state.buf, state.win, state.lnum_end
  if not buf or not win or not lnum or not vim.api.nvim_win_is_valid(win) then
    return nil
  end

  local info = vim.fn.getwininfo(win)[1]
  if not info then
    return nil
  end

  return { buf = buf, win = win, lnum = lnum, info = info }
end

---The height of a terminal cell in pixels
---@return integer
local function get_cell_height()
  return math.max(1, math.floor(vim.g.vimtex_preview_cell_height))
end

---The resolution of the rendered images. One row (12 bp, see show()) should
---be one terminal cell high.
---@return integer
local function get_dpi()
  return 6 * get_cell_height()
end

local function cache_dir()
  local dir = vim.fn["vimtex#cache#path"] "preview"
  vim.fn.mkdir(dir, "p")
  return dir
end

---@return string
local function get_color()
  local color = vim.g.vimtex_preview_color
  if color ~= "" then
    return (color:gsub("^#", ""))
  end

  local hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  if hl.fg then
    return string.format("%06X", hl.fg)
  end

  return vim.o.background == "dark" and "FFFFFF" or "000000"
end

---Read width and height from the IHDR chunk of a PNG file
---@param bytes string
---@return integer, integer
local function png_size(bytes)
  if #bytes < 24 or bytes:sub(1, 8) ~= "\137PNG\r\n\26\n" then
    return 0, 0
  end

  local function u32(i)
    local a, b, c, d = bytes:byte(i, i + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end
  return u32(17), u32(21)
end

local function hide_image()
  if state.img then
    pcall(vim.ui.img.del, state.img)
  end
  state.img = nil
end

---Reserve space for the image (or show a message) below the fragment
---@param rows integer
---@param msg? string
local function set_virt_lines(rows, msg)
  -- Changing the virtual lines may move parts of the screen, so we must hide
  -- the image first (see the comment in place())
  hide_image()

  local target = get_target()
  if not target then
    return
  end

  local width = target.info.width - target.info.textoff
  local border = { { string.rep("╌", width), "VimtexPreviewBorder" } }

  local lines
  if msg then
    lines = { { { msg, "VimtexPreviewError" } } }
  else
    lines = { border }
    for _ = 1, rows do
      table.insert(lines, { { "" } })
    end
    table.insert(lines, border)
  end

  pcall(vim.api.nvim_buf_set_extmark, target.buf, ns, target.lnum - 1, 0, {
    id = 1,
    virt_lines = lines,
  })
end

---Place the image below the fragment, or hide it if it does not fit
local function place()
  local shown = state.shown
  if not shown then
    return hide_image()
  end

  -- Images are attached to terminal cells and move when Neovim scrolls parts
  -- of the screen, e.g. to insert lines. Some terminals (e.g. WezTerm) then
  -- fail to remove the moved image, so we hide the image before anything that
  -- may scroll the screen, and place it again here after a redraw.
  vim.cmd.redraw()

  local target = get_target()
  if not target then
    return hide_image()
  end

  local info = target.info
  local line = vim.api.nvim_buf_get_lines(
    target.buf,
    target.lnum - 1,
    target.lnum,
    false
  )[1] or ""
  local anchor = vim.fn.screenpos(target.win, target.lnum, math.max(#line, 1))

  -- The image starts below the last screen line of the fragment and the top
  -- border
  local row = anchor.row + 2
  local col = info.wincol + info.textoff
  if
    anchor.row == 0 or row + shown.rows - 1 > info.winrow + info.height - 1
  then
    return hide_image()
  end

  -- The image would be drawn on top of the completion menu
  local pum = vim.fn.pum_getpos()
  if
    not vim.tbl_isempty(pum)
    and pum.row < row + shown.rows - 1
    and pum.row + pum.height >= row
    and pum.col < col + shown.size.width - 1
    and pum.col + pum.width + (pum.scrollbar and 1 or 0) >= col
  then
    return hide_image()
  end

  local opts = { row = row, col = col }
  if state.img then
    pcall(vim.ui.img.set, state.img, opts)
  else
    opts = vim.tbl_extend("force", opts, shown.size)
    local ok, id = pcall(vim.ui.img.set, shown.bytes, opts)
    if not ok then
      return
    end
    state.img = id
  end
end

---Show a new image, replacing the current one
---@param bytes string
local function show(bytes)
  local width, height = png_size(bytes)
  if height == 0 then
    return
  end

  local target = get_target()
  if not target then
    return
  end

  -- The image has the same size as the source text, i.e. one row per 12 bp
  -- (the line height of 10 pt text). We assume that cells are twice as high
  -- as they are wide, and the image is rendered and padded such that it fits
  -- a whole number of cells (see get_dpi() and vimtex#preview#get_document()).
  -- Thus, if the cell height option is correct, the terminal does not need to
  -- scale the image. We specify both the width and the height, since
  -- terminals differ in how they scale an image if only one of them is given.
  local cell = get_cell_height()
  local available = math.max(1, target.info.width - target.info.textoff - 1)
  local function round(x)
    return math.max(1, math.floor(x + 0.5))
  end
  local rows = round(height / cell)
  local cols = round(2 * width / cell)
  if cols > available then
    cols = available
    rows = round(cols * height / width / 2)
  end
  local size = { width = cols, height = rows }

  state.shown = { bytes = bytes, rows = rows, size = size }
  set_virt_lines(rows)
  place()
end

---@param key string
local function show_png(key)
  if state.key ~= key then
    return
  end

  local ok, bytes = pcall(vim.fn.readblob, cache_dir() .. "/" .. key .. ".png")
  if ok and type(bytes) == "string" then
    show(bytes)
  end
end

---@param key string
local function show_error(key)
  -- Keep showing the previous image (if any), since errors are common while
  -- typing
  if state.key ~= key or state.shown then
    return
  end

  local log = vim.fn.fnamemodify(cache_dir() .. "/" .. key .. ".log", ":~")
  set_virt_lines(0, "VimTeX preview failed, see " .. log)
end

---Compile the document to a PNG file in the cache directory
---@param key string
---@param lines string[]
---@param engine string
---@param dpi integer
local function compile(key, lines, engine, dpi)
  if job then
    if job.key == key then
      return
    end
    job.obj:kill(15)
  end

  local dir = cache_dir()
  local base = dir .. "/" .. key
  vim.fn.writefile(lines, base .. ".tex")

  local this = { key = key }

  ---@param success boolean
  local function finish(success)
    -- If another job has replaced this one, then this job was killed, and we
    -- only clean up
    local killed = job ~= this
    if not killed then
      job = nil
    end

    for _, file in ipairs(vim.fn.glob(base .. ".*", true, true)) do
      local keep = vim.endswith(file, ".png")
        or (not success and not killed and vim.endswith(file, ".log"))
      if not keep then
        vim.fn.delete(file)
      end
    end

    if killed then
      return
    elseif success then
      show_png(key)
    else
      failed[key] = true
      show_error(key)
    end
  end

  this.obj = vim.system({
    engine,
    "-interaction=nonstopmode",
    "-halt-on-error",
    "-output-directory=" .. dir,
    base .. ".tex",
  }, { cwd = vim.fn.eval "b:vimtex.root", timeout = 30000 }, function(res)
    if res.code ~= 0 then
      return vim.schedule(function()
        finish(false)
      end)
    end

    vim.system({
      "pdftocairo",
      "-png",
      "-singlefile",
      "-transp",
      "-r",
      tostring(dpi),
      base .. ".pdf",
      base,
    }, {}, function(res_png)
      vim.schedule(function()
        finish(res_png.code == 0)
      end)
    end)
  end)
  job = this
end

local function update()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  -- Only the first character matters, e.g. the mode is "ic" while the
  -- completion menu is visible
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  local engine = active[buf]
  if not engine or (mode ~= "n" and mode ~= "i") then
    return M.clear()
  end

  local fragment = vim.fn["vimtex#preview#get_fragment"]()
  if vim.tbl_isempty(fragment) then
    return M.clear()
  end

  -- Moving to a different fragment removes the current preview. Otherwise,
  -- we keep it until a new one is ready.
  if
    state.buf ~= buf
    or state.win ~= win
    or state.lnum_start ~= fragment.lnum_start
  then
    M.clear()
    state.buf = buf
    state.win = win
    state.lnum_start = fragment.lnum_start
  end

  local moved = state.lnum_end ~= fragment.lnum_end
  state.lnum_end = fragment.lnum_end
  state.line_count = vim.api.nvim_buf_line_count(buf)

  local lines = vim.fn["vimtex#preview#get_document"](fragment, get_color())
  local dpi = get_dpi()
  local key = vim.fn.sha256(
    table.concat({ engine, dpi, table.concat(lines, "\n") }, "\n")
  )
  if key == state.key then
    if moved and state.shown then
      set_virt_lines(state.shown.rows)
    end
    return place()
  end
  state.key = key

  if vim.uv.fs_stat(cache_dir() .. "/" .. key .. ".png") then
    show_png(key)
  elseif failed[key] then
    show_error(key)
  else
    compile(key, lines, engine, dpi)
  end
end

local function update_debounced()
  timer:stop()
  timer:start(vim.g.vimtex_preview_delay, 0, vim.schedule_wrap(update))
end

---Remove the current preview, the cached images, and the list of documents
---that failed to compile
function M.clear_cache()
  M.clear()
  failed = {}
  vim.fn.delete(cache_dir(), "rf")
end

---Remove the current preview
function M.clear()
  timer:stop()
  hide_image()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  end
  state = {}
end

---@return boolean
function M.is_active()
  return active[vim.api.nvim_get_current_buf()] ~= nil
end

---Id of the global autocommand that moves the image when windows change
---@type integer?
local global_autocmd = nil

---Create or remove the global autocommand, depending on whether there are
---any buffers with an active preview
local function update_global_autocmd()
  if next(active) and not global_autocmd then
    global_autocmd = vim.api.nvim_create_autocmd(
      { "WinScrolled", "WinResized", "VimResized" },
      {
        group = group,
        callback = function()
          if state.shown then
            set_virt_lines(state.shown.rows)
            place()
          end
        end,
      }
    )
  elseif not next(active) and global_autocmd then
    pcall(vim.api.nvim_del_autocmd, global_autocmd)
    global_autocmd = nil
  end
end

---Enable the preview for the current buffer
---@param engine string The TeX engine executable
function M.enable(engine)
  local buf = vim.api.nvim_get_current_buf()
  if active[buf] then
    return
  end

  active[buf] = engine
  update_global_autocmd()
  vim.api.nvim_create_autocmd(
    { "CursorMoved", "CursorMovedI", "ModeChanged" },
    { group = group, buffer = buf, callback = update_debounced }
  )
  vim.api.nvim_create_autocmd("CompleteChanged", {
    group = group,
    buffer = buf,
    -- The completion menu is not yet shown when this event is triggered
    callback = vim.schedule_wrap(place),
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = buf,
    callback = function()
      -- Added or removed lines may scroll the screen in the following redraw,
      -- so we hide the image now (see the comment in place())
      if state.line_count ~= vim.api.nvim_buf_line_count(buf) then
        hide_image()
      end
      update_debounced()
    end,
  })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = group,
    buffer = buf,
    callback = M.clear,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function()
      active[buf] = nil
      update_global_autocmd()
    end,
  })
  update()
end

---Disable the preview for the current buffer
function M.disable()
  local buf = vim.api.nvim_get_current_buf()
  active[buf] = nil
  update_global_autocmd()
  vim.api.nvim_clear_autocmds { group = group, buffer = buf }
  M.clear()
end

return M
