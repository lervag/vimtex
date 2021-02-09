" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#include_graphics#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'prefilter_cmds' : ['includegraphics'],
      \ 'priority' : 1,
      \ 're' : '\v^\s*\\includegraphics\*?%(\s*\[[^]]*\]){0,2}\s*\{\zs[^}]*',
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  let l:file = matchstr(a:context.line, self.re)
  if !vimtex#paths#is_abs(l:file)
    let l:file = vimtex#misc#get_graphicspath(l:file)
  endif
  let l:file = fnamemodify(l:file, ':~:.')
  let l:ext = fnamemodify(l:file, ':e')

  return !filereadable(l:file) || index(['asy', 'tikz'], l:ext) < 0
        \ ? {}
        \ : {
        \     'title'  : 'fig incl: ' . (strlen(l:file) < 70
        \                   ? l:file
        \                   : l:file[0:30] . '...' . l:file[-36:]),
        \     'number' : '',
        \     'file'   : l:file,
        \     'line'   : 1,
        \     'level'  : a:context.max_level - a:context.level.current,
        \     'rank'   : a:context.lnum_total,
        \     'type'   : 'include',
        \     'link'   : 1,
        \   }
endfunction

" }}}1
