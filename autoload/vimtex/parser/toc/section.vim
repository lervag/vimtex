" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#section#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'prefilter_cmds' : [
      \   'part',
      \   'chapter',
      \   '%(sub)*section',
      \   '%(sub)?paragraph',
      \   'add%(part|chap|sec)',
      \ ],
      \ 'priority' : 0,
      \ 're' : '\v^\s*\\%(part|chapter|%(sub)*section|%(sub)?paragraph|add%(part|chap|sec))\*?\s*(\[|\{)',
      \ 're_starred' : '\v^\s*\\%(%(part|chapter|%(sub)*section)\*|add%(part|chap|sec))',
      \ 're_level' : '\v^\s*\\\zs%(part|chapter|%(sub)*section|%(sub)?paragraph|add%(part|chap|sec))',
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  let level = self.level(a:context.line)
  let type = matchlist(a:context.line, self.re)[1]
  let title = matchstr(a:context.line, self.re . '\zs.{-}\ze\%?\s*$')
  let number = ''

  let [l:end, l:count] = vimtex#parser#tex#find_closing(0, title, 1, type)
  if l:count == 0
    let title = s:parse_title(strpart(title, 0, l:end+1))
  else
    let self.type = type
    let self.count = l:count
    let a:context.continue = 'section'
  endif

  if a:context.line =~# self.re_starred
    call a:context.level.set_current(level)
  else
    call a:context.level.increment(level)
    if a:context.line !~# '\v^\s*\\%(sub)?paragraph'
      let number = deepcopy(a:context.level)
    endif
  endif

  return {
        \ 'title'  : title,
        \ 'number' : number,
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'content',
        \ }
endfunction

" }}}1
function! s:matcher.continue(context) abort dict " {{{1
  let [l:end, l:count] = vimtex#parser#tex#find_closing(
        \ 0, a:context.line, self.count, self.type)
  if l:count == 0
    let a:context.entry.title = s:parse_title(
          \ a:context.entry.title . strpart(a:context.line, 0, l:end+1))
    unlet! a:context.continue
  else
    let a:context.entry.title .= a:context.line
    let self.count = l:count
  endif
endfunction

" }}}1
function! s:matcher.level(line) abort dict " {{{1
  let level = matchstr(a:line, self.re_level)

  if level =~# '^add'
    let level = {
          \ 'addpart': 'part',
          \ 'addchap': 'chapter',
          \ 'addsec': 'section',
          \}[level]
  endif

  return level
endfunction

" }}}1

function! s:parse_title(title) abort " {{{1
  let l:title = substitute(a:title, '\v%(\]|\})\s*$', '', '')
  return vimtex#parser#tex#texorpdfstring(l:title)
endfunction

" }}}1
