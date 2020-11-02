" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#moreverb#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'moreverb') | return | endif
  let b:vimtex_syntax.moreverb = 1

  syntax region texRegionVerb start="\\begin{verbatimtab}"   end="\\end{verbatimtab}" keepend contains=texCmdEnv,texArgEnvName
  syntax region texRegionVerb start="\\begin{verbatimwrite}" end="\\end{verbatimwrite}" keepend contains=texCmdEnv,texArgEnvName
  syntax region texRegionVerb start="\\begin{boxedverbatim}" end="\\end{boxedverbatim}" keepend contains=texCmdEnv,texArgEnvName
endfunction

" }}}1
