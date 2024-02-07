" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#comment#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'in_preamble' : 1,
      \ 'prefilter_cmds': ['begin'],
      \ 're': '^\s*\\begin{comment}',
      \ 're_end': '^\s*\\end{comment}',
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  let a:context.continue = 'comment'
  return {}
endfunction

" }}}1
function! s:matcher.continue(context) abort dict " {{{1
  if a:context.line =~# self.re_end
    unlet! a:context.continue
  endif
endfunction

" }}}1
