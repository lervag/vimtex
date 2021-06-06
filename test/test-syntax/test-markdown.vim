source common.vim

silent edit test-markdown.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texMarkdownZone', 7, 1))
call assert_true(vimtex#syntax#in('markdownItalic', 7, 1))
call assert_true(vimtex#syntax#in('markdownLink', 11, 12))
call assert_true(vimtex#syntax#in('texFileArg', 16, 16))

call vimtex#test#finished()
