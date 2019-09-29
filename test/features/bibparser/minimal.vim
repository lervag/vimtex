set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

function! TestBackend(backend) abort
  let g:vimtex_parser_bib_backend = a:backend

  echo 'Testing backend:' a:backend
  for s:e in vimtex#parser#bib(s:bib)
    echo '@' . s:e.type
    unlet s:e.type

    for s:k in ['key', 'title', 'author', 'year']
      echo '  ' . s:k . ':' get(s:e, s:k, '--')
      silent! unlet! s:e[s:k]
    endfor

    for [s:k, s:v] in items(s:e)
      echo '  ' . s:k . ':' s:v
    endfor

    echo ' '
  endfor
endfunction

let s:bib = 'test.bib'
" let s:bib = '/usr/share/texmf-dist/bibtex/bib/biblatex/biblatex/biblatex-examples.bib'

call TestBackend('bibtex')
call TestBackend('bibparse')
call TestBackend('vim')

quit!
