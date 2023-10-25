set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0
let g:vimtex_parser_bib_backend = 'bibtex'
let g:vimtex_complete_bib = {'match_str_fmt':  '@key @author_all @year "@title"'}

silent edit test_matchstr.tex

if empty($INMAKE) | finish | endif

call assert_true(len(vimtex#test#completion('\cite{', '')) > 1)
call assert_equal(1, len(vimtex#test#completion('\cite{', 'Mü')))
call assert_equal(1, len(vimtex#test#completion('\cite{', 'muell')))
call assert_equal(1, len(vimtex#test#completion('\cite{', 'M.*2019')))
call assert_equal(1, len(vimtex#test#completion('\cite{', 'mu.*Gimp')))
call assert_equal(1, len(vimtex#test#completion('\cite{', 'CsrA')))

call vimtex#test#finished()
