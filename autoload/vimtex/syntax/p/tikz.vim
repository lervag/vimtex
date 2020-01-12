" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tikz#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'tikz') | return | endif
  let b:vimtex_syntax.tikz = 1

  call vimtex#syntax#misc#add_to_section_clusters('texTikzSet')
  call vimtex#syntax#misc#add_to_section_clusters('texTikzpicture')

  " Define clusters
  syntax cluster texTikz contains=texTikzEnv,texBeginEnd,texStatement,texTikzSemicolon,texComment,@texVimtexGlobal
  syntax cluster texTikzOS contains=texTikzOptsCurly,texTikzEqual,texMathZoneX,texTypeSize,texStatement,texLength,texComment

  " Define tikz option groups
  syntax match texTikzSet /\\tikzset\>/
        \ contains=texStatement skipwhite nextgroup=texTikzOptsCurly
  syntax region texTikzOpts matchgroup=Delimiter
        \ start='\[' end='\]' contained contains=@texTikzOS
  syntax region texTikzOptsCurly matchgroup=Delimiter
        \ start='{'  end='}'  contained contains=@texTikzOS

  syntax region texTikzpicture
        \ start='\\begin{tikzpicture}'rs=s
        \ end='\\end{tikzpicture}'re=e
        \ keepend
        \ transparent
        \ contains=@texTikz
  syntax match texTikzEnv /\v\\begin\{tikzpicture\}/
        \ contains=texBeginEnd nextgroup=texTikzOpts skipwhite

  syntax match texTikzEqual /=/ contained
  syntax match texTikzSemicolon /;/ contained

  highlight def link texTikzEqual Operator
  highlight def link texTikzSemicolon Delimiter
endfunction

" }}}1

