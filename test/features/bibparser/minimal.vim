set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

for s:e in vimtex#parser#bib('test.bib')
  echo s:e.type '|' s:e.key
  for [s:k, s:v] in items(s:e.content)
    echo '  ' . s:k . ':' s:v
  endfor
  echo ''
endfor

echo ''

quit!
