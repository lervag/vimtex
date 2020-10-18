source common.vim

silent edit test-markdown.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texRegionMarkdown', 7, 1))
call vimtex#test#assert(vimtex#syntax#in('markdownItalic', 7, 1))
call vimtex#test#assert(vimtex#syntax#in('markdownLink', 11, 12))
call vimtex#test#assert(vimtex#syntax#in('texInputFileArg', 16, 16))

quit!
