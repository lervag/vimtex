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
      \ 'prefilter_cmds': ['begin'],
      \ 'priority': 0,
      \ 're': '^\s*\\begin{frame}',
      \ 're_end': '^\s*\\end{frame}',
      \ 're_match': '^\s*\\begin{frame}\%(\[[^]]\+\]\)\?{\zs.*\ze}\s*$',
      \}
function! s:matcher.init() abort dict " {{{1
  let self.number = 0
  let self.title = ''
  let self.subtitle = ''
endfunction

" }}}1
function! s:matcher.get_entry(context) abort dict " {{{1
  let self.number += 1
  let self.title = ''
  let self.subtitle = ''

  " Handle subtitles, e.g. \begin{frame}{title}{subtitle}
  let l:parts = split(matchstr(a:context.line, self.re_match), '}\s*{')
  if len(l:parts) > 1
    let self.title = vimtex#util#trim(l:parts[0])
    let self.subtitle = vimtex#util#trim(l:parts[1])
  elseif len(l:parts) > 0
    let self.title = vimtex#util#trim(l:parts[0])
  endif

  if empty(self.title)
    let a:context.continue = 'beamer_frame'
  endif

  return {
        \ 'title'  : self.get_title(),
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'content',
        \ }
endfunction

" }}}1
function! s:matcher.get_title() abort dict " {{{1
  if !empty(self.title) && !empty(self.subtitle)
    let l:title = ': ' . self.title . ' - ' . self.subtitle
  elseif !empty(self.title)
    let l:title = ': ' . self.title
  elseif !empty(self.subtitle)
    let l:title = ': ' . self.subtitle
  else
    let l:title = ''
  endif

  return printf("Frame %d%s", self.number, l:title)
endfunction

" }}}1
function! s:matcher.continue(context) abort dict " {{{1
  if empty(self.title)
    let self.title = vimtex#util#trim(
          \ matchstr(a:context.line, '^\s*\\frametitle\s*{\zs[^}]*'))
  endif
  if empty(self.subtitle)
    let self.subtitle = vimtex#util#trim(
          \ matchstr(a:context.line, '^\s*\\framesubtitle\s*{\zs[^}]*'))
  endif

  if (!empty(self.title) && !empty(self.subtitle))
        \ || a:context.line =~# self.re_end
    let a:context.entry.title = self.get_title()
    unlet! a:context.continue
  endif
endfunction

" }}}1
