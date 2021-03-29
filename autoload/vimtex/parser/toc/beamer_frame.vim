" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#beamer_frame#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'prefilter_cmds' : ['begin'],
      \ 'priority' : 0,
      \ 're' : '^\s*\\begin{frame}',
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  let l:title = vimtex#util#trim(
        \ matchstr(a:context.line, self.re . '\%(\[[^]]\+\]\)\?{\zs.*\ze}\s*$'))

  " Handle subtitles, e.g. \begin{frame}{title}{subtitle}
  let l:title = substitute(l:title, '}\s*{', ' - ', '')

  return {
        \ 'title'  : 'Frame' . (empty(l:title) ? '' : ': ' . l:title),
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'content',
        \ }
endfunction

" }}}1
