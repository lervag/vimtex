" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#parts#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 're' : '\v^\s*\\\zs((front|main|back)matter|appendix)>',
      \ 'prefilter_cmds' : ['%(front|main|back)matter', 'appendix'],
      \ 'priority' : 0,
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  call a:context.level.reset(
        \ matchstr(a:context.line, self.re),
        \ a:context.max_level)
  return {}
endfunction

" }}}1
