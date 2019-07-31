" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pythontex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'pythontex') | return | endif
  let b:vimtex_syntax.pythontex = 1

  unlet b:current_syntax
  syntax include @PYTHON syntax/python.vim
  let b:current_syntax = 'tex'

  syntax cluster PYTHON remove=pythonEscape
  syntax cluster PYTHON remove=pythonBEscape
  syntax cluster PYTHON remove=pythonBytesEscape

  syntax match texStatement /\\py[bsc]\?/ contained nextgroup=texPythontexArg
  syntax region texPythontexArg matchgroup=Delimiter
        \ start='{' end='}'
        \ contained contains=@PYTHON
  syntax region texPythontexArg matchgroup=Delimiter
        \ start='\z([#@]\)' end='\z1'
        \ contained contains=@PYTHON

  call vimtex#syntax#add_to_clusters('texZonePythontex')
  syntax region texZonePythontex
        \ start='\\begin{pyblock}'rs=s
        \ end='\\end{gnuplot}'re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,texBeginEndModifier,@PYTHON
  syntax region texZonePythontex
        \ start='\\begin{pycode}'rs=s
        \ end='\\end{pycode}'re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,texBeginEndModifier,@PYTHON
endfunction

" }}}1
