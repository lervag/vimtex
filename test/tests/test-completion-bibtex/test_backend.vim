set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

if !empty($BACKEND)
  let g:vimtex_parser_bib_backend = $BACKEND
endif

silent edit test_backend.tex

if empty($INMAKE) | finish | endif

" Simplify test on basic systems
if empty(vimtex#kpsewhich#find('biblatex-example.bib'))
  let s:candidates = vimtex#test#completion('\cite{', '')
  call vimtex#test#assert_equal(len(s:candidates) >= 1, v:true)

  quit!
endif

let s:candidates = vimtex#test#completion('\cite{', '')
call vimtex#test#assert_equal(len(s:candidates), 94)

let s:candidates = vimtex#test#completion('\citet{', '.*ocal')
call vimtex#test#assert_equal(len(s:candidates), 2)

let s:candidates = vimtex#test#completion('\parencite[see][5--10]{', 'Arist.*1929')
call vimtex#test#assert_equal(len(s:candidates), 1)
call vimtex#test#assert_equal(s:candidates[0].word, 'aristotle:physics')

let g:vimtex_complete_bib.simple = 1
let s:candidates = vimtex#test#completion('\textcite[5--10]{', 'aristotle:p')
call vimtex#test#assert_equal(len(s:candidates), 2)
call vimtex#test#assert_equal(s:candidates[0].word, 'aristotle:physics')

quit!
