source common.vim

silent edit test-minted.tex

if empty($INMAKE) | finish | endif

" Minted inside \paragraphs (#1537)
call assert_true(vimtex#syntax#in('javaScopeDecl', 72, 3))

" Newminted on unrecognized languages (#1616)
call assert_true(vimtex#syntax#in('texMintedZoneLog', 112, 1))
call assert_true(vimtex#syntax#in('texMintedZoneShellsession', 116, 1))

" " Doing :e should not destroy nested syntax and similar
" call assert_true(vimtex#syntax#in('pythonFunction', 38, 5))
" edit
" call assert_true(vimtex#syntax#in('pythonFunction', 38, 5))

call vimtex#test#finished()
