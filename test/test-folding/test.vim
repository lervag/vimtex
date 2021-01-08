set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set fillchars=fold:\ 
set number
set foldcolumn=4

nnoremap q :qall!<cr>

let g:vimtex_fold_enabled = 1
let g:vimtex_fold_types = {'comments' : {'enabled': 1}}

silent edit main.tex

if empty($INMAKE) | finish | endif


call vimtex#test#assert_equal(1, foldlevel(1))
call vimtex#test#assert_equal(2, foldlevel(2))
call vimtex#test#assert_equal(2, foldlevel(34))
call vimtex#test#assert_equal(2, foldlevel(48))
call vimtex#test#assert_equal(3, foldlevel(128))
call vimtex#test#assert_equal(2, foldlevel(144))

call vimtex#test#assert_equal(
      \ '      Preamble',
      \ foldtextresult(1))
call vimtex#test#assert_equal(
      \ '\usepackage[...]{biblatex}',
      \ foldtextresult(48))
call vimtex#test#assert_equal(
      \ '\newcommand*{\StoreCiteField}[3]{%',
      \ foldtextresult(63))
call vimtex#test#assert_equal(
      \ '\pgfplotstableread[col sep=semicolon,trim cells]{...}{\datatable}',
      \ foldtextresult(105))
call vimtex#test#assert_equal(
      \ '(sec:test1-longer label)',
      \ matchstr(foldtextresult(146), '(.*)$'))
call vimtex#test#assert_equal(
      \ '% {{{ Testing markers',
      \ foldtextresult(153))

" Test with different markers
let g:vimtex_fold_types = {'markers': {'open': '<<:', 'close': ':>>'}}
silent VimtexReload

call vimtex#test#assert_equal('Testing markers ', foldtextresult(158))
call vimtex#test#assert_equal('% <<: this fold worked before issue #1515', foldtextresult(163))

call vimtex#test#assert_equal(3, foldlevel(176))
call vimtex#test#assert_equal(5, foldlevel(179))
call vimtex#test#assert_equal(4, foldlevel(184))
call vimtex#test#assert_equal(3, foldlevel(186))
call vimtex#test#assert_equal(1, foldlevel(190))
call vimtex#test#assert_equal(2, foldlevel(202))

call vimtex#test#assert_equal(1, foldlevel(line('$')-1))

quit!

" vim: fdm=manual
