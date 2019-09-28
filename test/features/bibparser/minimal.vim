set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

for s:e in vimtex#parser#bib(
      \ '/usr/share/texmf-dist/bibtex/bib/biblatex/biblatex/biblatex-examples.bib')
      \ + vimtex#parser#bib('test.bib')
  echo printf('%-20S %-20S %-10S', s:e.type, s:e.key, get(s:e, 'year', '----'))
  echo '  ' . get(s:e, 'author', 'Unknown')
  echo '  ' . get(s:e, 'title', 'No Title')
  echo ' '
endfor

quit!
