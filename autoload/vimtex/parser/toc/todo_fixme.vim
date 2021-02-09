" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#todo_fixme#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'prefilter_cmds' : ['begin', 'fx%(warning|error|fatal|note)'],
      \ 'priority' : 2,
      \ 're_cmd' : '\v\\fx%(warning|error|fatal|note)\*?%(\[[^]]*\])?\{\zs.*',
      \ 're_env' : '\v\\begin\s*\{anfx%(warning|error|fatal|note)\*?\}',
      \}
function! s:matcher.init() abort dict " {{{1
  let self.re = self.re_cmd . '|' . self.re_env
endfunction

" }}}1
function! s:matcher.get_entry(context) abort dict " {{{1
  if a:context.line =~# self.re_cmd
    let title = matchstr(a:context.line, self.re_cmd)
    let label = matchstr(a:context.line, '\\\zsfx\w*')
  else
    let title = matchstr(a:context.line, self.re_env . '\s*\{\zs.*')
    let label = matchstr(a:context.line, 'anfx\w*')
  endif

  let [l:end, l:count] = vimtex#parser#tex#find_closing(0, title, 1, '{')
  if l:count == 0
    let title = strpart(title, 0, l:end)
  else
    let self.count = l:count
    let a:context.continue = 'todo_fixme'
  endif

  return {
        \ 'title'  : label . ': ' . title,
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level - a:context.level.current,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'todo',
        \ }
endfunction

" }}}1
function! s:matcher.continue(context) abort dict " {{{1
  let [l:end, l:count] = vimtex#parser#tex#find_closing(
        \ 0, a:context.line, self.count, '{')
  if l:count == 0
    let a:context.entry.title .= strpart(a:context.line, 0, l:end)
    unlet! a:context.continue
  else
    let a:context.entry.title .= a:context.line
    let self.count = l:count
  endif
endfunction

" }}}1
