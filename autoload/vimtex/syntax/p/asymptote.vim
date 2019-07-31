" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#asymptote#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'asymptote') | return | endif
  let b:vimtex_syntax.asymptote = 1

  call vimtex#syntax#misc#add_to_section_clusters('texZoneAsymptote')

  if !empty(vimtex#syntax#misc#include('asy'))
    syntax region texZoneAsymptote
          \ start='\\begin{asy\z(def\)\?}'rs=s
          \ end='\\end{asy\z1}'re=e
          \ keepend
          \ transparent
          \ contains=texBeginEnd,@vimtex_nested_asy
  else
    syntax region texZoneAsymptote
          \ start='\\begin{asy\z(def\)\?}'rs=s
          \ end='\\end{asy\z1}'re=e
          \ keepend
          \ contains=texBeginEnd
    highlight def link texZoneAsymptote texZone
  endif
endfunction

" }}}1
