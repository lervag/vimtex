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

  if empty(l:title)
    let l:title = 'Frame'
    let a:context.__title = ''
    let a:context.__subtitle = ''
    let a:context.continue = 'beamer_frame'
  else
    let l:title = 'Frame: ' . l:title
  endif

  return {
        \ 'title'  : l:title,
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'content',
        \ }
endfunction

" }}}1
function! s:matcher.continue(context) abort dict " {{{1
  if empty(a:context.__title)
    let a:context.__title = vimtex#util#trim(
          \ matchstr(a:context.line, '^\s*\\frametitle\s*{\zs[^}]*'))
  endif
  if empty(a:context.__subtitle)
    let a:context.__subtitle = vimtex#util#trim(
          \ matchstr(a:context.line, '^\s*\\framesubtitle\s*{\zs[^}]*'))
  endif

  if !empty(a:context.__title) && !empty(a:context.__subtitle)
    unlet! a:context.continue
    let a:context.entry.title .= ': ' . a:context.__title . ' - ' . a:context.__subtitle
  endif

  if a:context.line =~# '\\end\s*{\s*frame\s*}'
    unlet! a:context.continue
    if !empty(a:context.__title) || !empty(a:context.__subtitle)
      let a:context.entry.title .= ': ' . a:context.__title . ' - ' . a:context.__subtitle
    endif
  endif
endfunction

" }}}1
