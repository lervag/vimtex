source common.vim

silent edit test-minted.tex

if empty($INMAKE) | finish | endif

" Minted inside \paragraphs (#1537)
call vimtex#test#assert(vimtex#util#in_syntax('javaScopeDecl', 72, 3))

" Doing :e should not destroy nested syntax and similar
call vimtex#test#assert(vimtex#util#in_syntax('pythonFunction', 38, 5))
edit
call vimtex#test#assert(vimtex#util#in_syntax('pythonFunction', 38, 5))

quit!
