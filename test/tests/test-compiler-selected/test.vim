set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

silent edit test.tex

call vimtex#parser#selection_to_texfile({
      \ 'range': [14, 16],
      \ 'name': 'output1',
      \})

call vimtex#parser#selection_to_texfile({
      \ 'range': [14, 16],
      \ 'name': 'output2',
      \ 'template': 'NONE',
      \})

quitall!
