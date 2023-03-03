source common.vim

let g:vimtex_syntax_conceal = {
      \ 'sections' : 1,
      \}

EditConcealed! test-hyperref.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texUrlArg', 6, 25))
call assert_true(vimtex#syntax#in('texRefArg', 17, 35))

call vimtex#test#finished()
