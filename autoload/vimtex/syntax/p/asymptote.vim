" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#asymptote#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'asymptote') | return | endif
  let b:vimtex_syntax.asymptote = 1

  call vimtex#syntax#misc#add_to_section_clusters('texZoneAsymptote')

  let l:asypath = globpath(&runtimepath, 'syntax/asy.vim')
  if !empty(l:asypath)
    unlet b:current_syntax
    syntax include @ASYMPTOTE syntax/asy.vim
    let b:current_syntax = 'tex'

    syntax region texZoneAsymptote
          \ start='\\begin{asy\z(def\)\?}'rs=s
          \ end='\\end{asy\z1}'re=e
          \ keepend
          \ transparent
          \ contains=texBeginEnd,@ASYMPTOTE
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
