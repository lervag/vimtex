set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set fillchars=fold:\ 
set number
set foldcolumn=2

nnoremap q :qall!<cr>

let g:vimtex_fold_enabled = 1

silent edit test-env-options.tex

if empty($INMAKE) | finish | endif

let s:width = winwidth(0)
      \ - (&number ? &numberwidth : 0)
      \ - str2nr(matchstr(&foldcolumn, '\d\+$')) - 1
call assert_equal(s:width, strlen(foldtextresult(4)))

call assert_match(
  \ '\\begin{defn}\[Definition 1\]\s\+(defn:definition_1)',
  \ foldtextresult(4))

call assert_match(
  \ '\\begin{figure}     Simple figure\s\+(fig:simple_figure)',
  \ foldtextresult(9))

call assert_match(
  \ '\\begin{thm}\[Example Title of Theorem\]\s\+(thm:example_title_of_theorem)',
  \ foldtextresult(16))

call assert_match(
  \ '  \\begin{figure}   A visual proof of Example .*(fig:visual_theorem)',
  \ foldtextresult(27))

call assert_match(
  \ '\\begin{defn}\[…\]    A caption for an environment .*(defn:definition_2)',
  \ foldtextresult(35))


call vimtex#test#finished()
