" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pgfplots#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'pgfplots') | return | endif
  let b:vimtex_syntax.pgfplots = 1

  " Define tikz and pgfplot option groups
  syntax cluster texTikzOS contains=texTikzOptsCurly,texTikzEqual,texMathZoneX,texTypeSize,texStatement,texLength
  syntax match texTikzSet /\\\%(tikz\|pgfplots\)set\>/
        \ contains=texStatement skipwhite nextgroup=texTikzOptsCurly
  syntax region texTikzOpts matchgroup=Delimiter
        \ start='\[' end='\]' contained contains=@texTikzOS
  syntax region texTikzOptsCurly matchgroup=Delimiter
        \ start='{'  end='}'  contained contains=@texTikzOS
  syntax match texTikzEqual /=/ contained

  " All tikz and pgfplots are captured in a tikzpicture environment
  syntax cluster texTikz contains=texTikzEnv,texBeginEnd,texStatement,texAxisStatement,texTikzSemicolon
  call vimtex#syntax#misc#add_to_section_clusters('texTikzpicture')
  syntax region texTikzpicture
        \ start='\\begin{tikzpicture}'rs=s
        \ end='\\end{tikzpicture}'re=e
        \ keepend
        \ transparent
        \ contains=@texTikz

  syntax match texTikzEnv /\v\\begin\{%(tikzpicture|%(log)*axis)\}/
        \ contains=texBeginEnd nextgroup=texTikzOpts skipwhite

  syntax match texTikzSemicolon /;/ contained
  syntax match texAxisStatement /\\addplot3\>/
        \ contained skipwhite nextgroup=texTikzOpts

  highlight def link texTikzEqual Operator
  highlight def link texTikzSemicolon Delimiter
  highlight def link texAxisStatement texStatement
endfunction

" }}}1
