" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#include_bibtex#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'in_preamble' : 1,
      \ 'prefilter_cmds' : ['bibliography'],
      \ 'priority' : 0,
      \ 're' : '\v^\s*\\bibliography\s*\{\zs[^}]+\ze\}',
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  let l:entries = []

  for l:file in split(matchstr(a:context.line, self.re), ',')
    " Ensure that the file name has extension
    if l:file !~# '\.bib$'
      let l:file .= '.bib'
    endif

    if !filereadable(l:file)
      let l:file = vimtex#kpsewhich#find(l:file)
    endif

    call add(l:entries, {
          \ 'title'  : printf('bib incl: %-.67s', fnamemodify(l:file, ':t')),
          \ 'number' : '',
          \ 'file'   : l:file,
          \ 'line'   : 1,
          \ 'level'  : 0,
          \ 'rank'   : a:context.lnum_total,
          \ 'type'   : 'include',
          \ 'link'   : 1,
          \})
  endfor

  return l:entries
endfunction

" }}}1
