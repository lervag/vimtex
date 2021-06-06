source common.vim

let s:fls = 'test-fls-reload.fls'

" Delete fls file (in case it is left over)
call delete(s:fls)

silent edit test-fls-reload.tex

" Class should load, but implied package is not loaded
call assert_true(b:vimtex_syntax.beamer.__loaded)
call assert_true(!b:vimtex_syntax.url.__loaded)

" Imitate compilation process -> implied package should also be loaded
call writefile(['INPUT /usr/share/texmf-dist/tex/latex/url/url.sty'], s:fls)
silent call vimtex#compiler#callback(1)
call assert_true(b:vimtex_syntax.url.__loaded)

call delete(s:fls)
call vimtex#test#finished()
