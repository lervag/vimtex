" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#include#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'in_preamble' : 1,
      \ 'prefilter_cmds' : ['input', 'include', 'import', 'subfile'],
      \ 'priority' : 0,
      \ 're' : vimtex#re#tex_input . '\zs\f{-}\s*\ze\}',
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  let l:file = matchstr(a:context.line, self.re)
  if !vimtex#paths#is_abs(l:file[0])
    " Handle import and subfile package commands
    let l:root = a:context.line =~# '\\sub'
          \ ? fnamemodify(a:context.file, ':p:h')
          \ : b:vimtex.root
    let l:file = l:root . '/' . l:file
  endif
  let l:file = fnamemodify(l:file, ':~:.')
  if !filereadable(l:file) && filereadable(l:file . '.tex')
    let l:file .= '.tex'
  endif
  return {
        \ 'title'  : 'tex incl: ' . (strlen(l:file) < 70
        \               ? l:file
        \               : l:file[0:30] . '...' . l:file[-36:]),
        \ 'number' : '',
        \ 'file'   : l:file,
        \ 'line'   : 1,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'include',
        \ }
endfunction

" }}}1
