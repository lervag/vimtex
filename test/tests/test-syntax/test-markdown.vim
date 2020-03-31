source common.vim

silent edit test-markdown.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#util#in_syntax('texZoneMarkdown', 7, 1))
call vimtex#test#assert(vimtex#util#in_syntax('markdownItalic', 7, 1))
call vimtex#test#assert(vimtex#util#in_syntax('markdownLink', 11, 12))
call vimtex#test#assert(vimtex#util#in_syntax('texInputFileArg', 16, 16))

quit!
