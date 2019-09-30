set nocompatible
let &rtp = '../../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

if !empty($BACKEND)
  let g:vimtex_parser_bib_backend = $BACKEND
endif

silent edit main.tex

if empty($MAKE) | finish | endif

let s:candidates = vimtex#test#completion('\cite{', '')
call vimtex#test#assert(len(s:candidates), 94)

let s:candidates = vimtex#test#completion('\citet{', '.*ocal')
call vimtex#test#assert(len(s:candidates), 2)

let s:candidates = vimtex#test#completion('\parencite[see][5--10]{', 'Arist.*1929')
call vimtex#test#assert(len(s:candidates), 1)
call vimtex#test#assert(s:candidates[0].word, 'aristotle:physics')

let g:vimtex_complete_bib.simple = 1
let s:candidates = vimtex#test#completion('\textcite[5--10]{', 'aristotle:p')
call vimtex#test#assert(len(s:candidates), 2)
call vimtex#test#assert(s:candidates[0].word, 'aristotle:physics')

quit!
