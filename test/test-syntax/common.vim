set nocompatible
set runtimepath^=../..
filetype plugin on
syntax enable

set nomore
set spell

nnoremap q :qall!<cr>

" Use a more colorful colorscheme
colorscheme morning

highlight Conceal ctermfg=4 ctermbg=7 guibg=NONE guifg=blue
highlight texCmdRef ctermfg=6 guifg=cyan

if empty($INMAKE)
  augroup Testing
    autocmd!
    autocmd CursorMoved * echo join(vimtex#syntax#stack(), ' -> ')
  augroup END
endif

function Edit(file) abort
  let g:vimtex_syntax_conceal_disable = 1
  execute 'silent edit' a:file
  set conceallevel=2
endfunction

function EditConcealed(file, bang) abort
  execute 'silent edit' a:file

  if a:bang
    split
  else
    vsplit
  endif

  silent wincmd w
  silent windo set scrollbind
  set conceallevel=2
endfunction

command! -nargs=1       Edit          call Edit(<q-args>)
command! -nargs=1 -bang EditConcealed call EditConcealed(<q-args>, <q-bang> == '!')
