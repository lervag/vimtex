" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#include_biblatex#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'in_preamble' : 1,
      \ 'in_content' : 0,
      \ 'prefilter_cmds' : ['add%(global|section)?bib'],
      \ 'priority' : 0,
      \ 're' : '\v^\s*\\add(bibresource|globalbib|sectionbib)\s*\{\zs[^}]+\ze\}',
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  let l:file = matchstr(a:context.line, self.re)

  if !filereadable(l:file)
    let l:file = vimtex#kpsewhich#find(l:file)
  endif

  return {
        \ 'title'  : printf('bib incl: %-.67s', fnamemodify(l:file, ':t')),
        \ 'number' : '',
        \ 'file'   : l:file,
        \ 'line'   : 1,
        \ 'level'  : 0,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'include',
        \ 'link'   : 1,
        \}
endfunction

" }}}1
