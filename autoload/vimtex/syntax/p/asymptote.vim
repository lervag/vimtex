" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#asymptote#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'asymptote') | return | endif
  let b:vimtex_syntax.asymptote = 1

  if !empty(vimtex#syntax#nested#include('asy'))
    syntax region texRegionAsymptote
          \ start="\\begin{asy\z(def\)\?}"
          \ end="\\end{asy\z1}"
          \ transparent
          \ keepend contains=texCmdEnv,@vimtex_nested_asy
  else
    syntax region texRegionAsymptote
          \ start="\\begin{asy\z(def\)\?}"
          \ end="\\end{asy\z1}"
          \ keepend contains=texCmdEnv
    highlight def link texRegionAsymptote texRegion
  endif
endfunction

" }}}1
