set nocompatible
set runtimepath^=../..
filetype plugin on
syntax on

nnoremap q :qall!<cr>

" Use a temporary cache root, which is removed when the editor exits. Note
" that VimTeX writes its persistent caches on exit, after the test has
" finished.
let g:vimtex_cache_root = tempname()
let g:vimtex_preview_delay = 0

silent edit test.tex

if empty($INMAKE) | finish | endif

if !has('nvim-0.13') || !executable('pdflatex') || !executable('pdftocairo')
  call vimtex#test#finished()
endif

" Record image calls instead of writing to the terminal
lua << EOF
_G.images = {}
vim.ui.img = {
  set = function(data, opts)
    if type(data) == "number" then
      local image = _G.images[data]
      image.opts = vim.tbl_extend("force", image.opts, opts)
      return data
    end
    table.insert(_G.images, { opts = opts })
    return #_G.images
  end,
  del = function(id)
    _G.images[id].deleted = true
  end,
}

function _G.png_size(path)
  local bytes = vim.fn.readblob(path)
  local function u32(i)
    local a, b, c, d = bytes:byte(i, i + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end
  return { u32(17), u32(21) }
end
EOF

function! s:extmarks() abort
  return nvim_buf_get_extmarks(0, -1, 0, -1, {'details': 1})
endfunction

call vimtex#preview#clear_cache()
call cursor(10, 5)
VimtexPreviewToggle

" Enabling an active preview does nothing
call vimtex#preview#enable()
call assert_true(luaeval('require("vimtex.preview").is_active()'))
call assert_true(exists('#vimtex_preview#WinScrolled'))

call assert_equal(0, wait(10000, {-> !empty(s:extmarks())}))

" A cached PNG was created, and the image is placed below the fragment and
" the top border
let s:png = glob(g:vimtex_cache_root . '/preview/*.png', 0, 1)
call assert_equal(1, len(s:png))

" The image is padded to a whole number of cells (24 px x 12 px by default),
" and shown with exactly that size
let [s:width, s:height] = luaeval('_G.png_size(_A)', s:png[0])
call assert_equal(0, s:height % 24)
call assert_equal(0, s:width % 12)
call assert_equal(s:height / 24, luaeval('_G.images[1].opts.height'))
call assert_equal(s:width / 12, luaeval('_G.images[1].opts.width'))
call assert_equal(11 + 2, luaeval('_G.images[1].opts.row'))
call assert_equal(10, s:extmarks()[0][1])

" Leaving the fragment removes the preview
normal! gg
doautocmd CursorMoved
call assert_equal(0, wait(1000, {-> empty(s:extmarks())}))
call assert_true(luaeval('_G.images[1].deleted'))

" A compilation that is replaced by a newer one is killed and cleaned up
function! s:other_files() abort
  return filter(glob(g:vimtex_cache_root . '/preview/*', 0, 1),
        \ { _, x -> x !~# '\.png$' })
endfunction
call cursor(14, 5)
doautocmd CursorMoved
" Wait until the compilation has started, then move to another fragment
call assert_equal(0, wait(5000, {-> !empty(s:other_files())}))
call cursor(19, 5)
doautocmd CursorMoved
call assert_equal(0, wait(10000, {-> !empty(s:extmarks())}))
call assert_equal(0, wait(5000, {-> empty(s:other_files())}))
" Only the previous image and the image for the last fragment exist, i.e. the
" first compilation did not finish
call assert_equal(2, len(glob(g:vimtex_cache_root . '/preview/*.png', 0, 1)))

normal! gg
doautocmd CursorMoved
call assert_equal(0, wait(1000, {-> empty(s:extmarks())}))

" Compilation errors are shown below the fragment
call append(27, ['\[ \frac{1} \]'])
call cursor(28, 5)
doautocmd CursorMoved
call assert_equal(0, wait(10000, {-> !empty(s:extmarks())}))
let s:virt_lines = get(s:extmarks()[0][3], 'virt_lines', [[['']]])
call assert_match('VimTeX preview failed', s:virt_lines[0][0][0])

VimtexPreviewToggle
call assert_equal([], s:extmarks())

" The global autocommands are removed with the last active preview
call assert_false(exists('#vimtex_preview#WinScrolled'))

call vimtex#test#finished()
