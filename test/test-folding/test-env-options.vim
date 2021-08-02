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


call assert_equal(
  \ '\begin{defn}[Definition 1]                            (defn:definition_1)',
  \ foldtextresult(4))

call assert_equal(
  \ '\begin{figure}     Simple figure                      (fig:simple_figure)',
  \ foldtextresult(9))

" TODO: This fails now -- see #2117
" call assert_equal(
"   \ '\begin{thm}[Example Title of Theorem]      (thm:example_title_of_theorem)',
"   \ foldtextresult(16))

call assert_equal(
  \ '  \begin{figure}   A visual proof of Example Theorem (fig:visual_theorem)',
  \ foldtextresult(27))

call assert_equal(
  \ '\begin{defn}[…]    A caption for an environment typi… (defn:definition_2)',
  \ foldtextresult(35))


call vimtex#test#finished()
