set nocompatible
let &rtp = '.,' . &rtp
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin on
syntax enable

set nomore

nnoremap q :qall!<cr>

" Use a more colorful colorscheme
colorscheme morning

let g:tex_flavor = 'latex'
let g:vimtex_fold_enabled = 1

function! SynNames()
  return join(map(synstack(line('.'), col('.')),
        \ 'synIDattr(v:val, ''name'')'), ' -> ')
endfunction

silent edit minimal.tex

syntax sync fromstart

if empty($INMAKE)
  augroup Testing
    autocmd!
    autocmd CursorMoved * echo SynNames()
  augroup END

  finish
endif

call vimtex#test#assert_equal(len(keys(b:vimtex_syntax)), 21)

" PythonTeX inside tikzpictures (#1563)
call vimtex#test#assert(vimtex#util#in_syntax('pythonRawString', 251, 11))
call vimtex#test#assert(vimtex#util#in_syntax('pythonRawString', 256, 11))

" Minted inside \paragraphs (#1537)
call vimtex#test#assert(vimtex#util#in_syntax('javaScopeDecl', 355, 3))

" Doing :e should not destroy nested syntax and similar
call vimtex#test#assert(vimtex#util#in_syntax('pythonFunction', 321, 5))
edit
call vimtex#test#assert(vimtex#util#in_syntax('pythonFunction', 321, 5))

quit!
