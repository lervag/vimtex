if exists('b:_loaded_markdown_vimtex')
  finish
endif
let b:_loaded_markdown_vimtex = 1

if !exists('b:current_syntax')
  runtime! syntax/markdown.vim
endif

unlet! b:current_syntax
syntax include @tex syntax/tex.vim
let b:current_syntax = 'markdown'

syntax region mkdMath start="\\\@<!\$" end="\$" skip="\\\$" contains=@tex keepend
syntax region mkdMath start="\\\@<!\$\$" end="\$\$" skip="\\\$" contains=@tex keepend
syntax region mkdMath start="\\\@<!\\(" end="\\\@<!\\)" contains=@tex keepend
