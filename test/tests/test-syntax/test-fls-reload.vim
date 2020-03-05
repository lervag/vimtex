source common.vim

let s:fls = 'test-fls-reload.fls'

" Delete fls file (in case it is left over)
call delete(s:fls)

silent edit test-fls-reload.tex

" Class should load, but implied package is not loaded
call vimtex#test#assert(has_key(b:vimtex_syntax, 'beamer'))
call vimtex#test#assert(!has_key(b:vimtex_syntax, 'url'))

" Imitate compilation process -> implied package should also be loaded
call writefile(['INPUT /usr/share/texmf-dist/tex/latex/url/url.sty'], s:fls)
silent call vimtex#compiler#callback(1)
call vimtex#test#assert(has_key(b:vimtex_syntax, 'url'))

call delete(s:fls)
quit!
