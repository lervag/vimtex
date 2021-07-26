" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#amsthm#load(cfg) abort " {{{1
  call s:gather_newtheorems()

  syntax match texCmdNewthm "\\newtheorem\*"
        \ nextgroup=texNewthmArgName skipwhite skipnl

  syntax match texProofEnvBegin "\\begin{proof}"
        \ nextgroup=texProofEnvOpt
        \ skipwhite
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texProofEnvOpt', {
        \ 'contains': 'TOP,@NoSpell'
        \})

  call vimtex#syntax#core#new_opt('texTheoremEnvOpt', {
        \ 'contains': 'TOP,@NoSpell'
        \})

  for l:envname in b:vimtex.syntax.amsthm
    execute 'syntax match texTheoremEnvBgn'
          \ printf('"\\begin{%s}"', l:envname)
          \ 'nextgroup=texTheoremEnvOpt skipwhite'
          \ 'contains=texCmdEnv'
  endfor

  highlight def link texProofEnvOpt texEnvOpt
  highlight def link texTheoremEnvOpt texEnvOpt
endfunction

" }}}1

function! s:gather_newtheorems() abort " {{{1
  if has_key(b:vimtex.syntax, 'amsthm') | return | endif

  let l:lines = vimtex#parser#preamble(b:vimtex.tex)
  let b:vimtex.syntax.amsthm = l:lines

  call filter(l:lines, {_, x -> x =~# '^\s*\\newtheorem\>'})
  call map(l:lines, {_, x -> matchstr(x, '^\s*\\newtheorem\>\*\?{\zs[^}]*')})
endfunction

" }}}1
