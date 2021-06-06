source common.vim

silent edit test-wiki.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texWikiZone', 6, 1))
" call assert_true(vimtex#syntax#in('markdownHeader', 7, 1))

call vimtex#test#finished()
