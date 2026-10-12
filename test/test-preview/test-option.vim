set nocompatible
set runtimepath^=../..
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_preview_enabled = 1

silent edit test.tex

if empty($INMAKE) | finish | endif

" The option is reset with a warning for unsupported versions
if has('nvim-0.13')
  call assert_equal(1, g:vimtex_preview_enabled)
  call assert_equal(2, exists(':VimtexPreviewToggle'))

  " Loading the Lua module does not create any autocommands
  call assert_false(luaeval('require("vimtex.preview").is_active()'))
  call assert_false(exists('#vimtex_preview#WinScrolled'))
else
  call assert_equal(0, g:vimtex_preview_enabled)
  call assert_equal(0, exists(':VimtexPreviewToggle'))
  call assert_match('requires Neovim 0.13',
        \ join(map(vimtex#log#get(), 'join(v:val.msg)')))
endif

call vimtex#test#finished()
