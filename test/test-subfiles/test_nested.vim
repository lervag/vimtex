set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit test_nested/parts/chapter.tex
call assert_equal(expand('%:p:h:h'), b:vimtex.root)
silent VimtexToggleMain
call assert_equal(expand('%:p:h'), b:vimtex.root)

silent edit test_nested/parts/sections/first.tex
call assert_equal(expand('%:p:h:h:h'), b:vimtex.root)
silent VimtexToggleMain
call assert_equal(expand('%:p:h'), b:vimtex.root)

call vimtex#test#finished()
