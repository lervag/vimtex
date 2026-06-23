" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#todo_fixme#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = { 'priority' : 2 }

function! s:matcher.init() abort dict " {{{1
  " Build the command/environment patterns and the prefilter from the
  " registered fixme authors. The prefilter must include the author command
  " prefixes, because the ToC parser gates each line on the (precompiled)
  " prefilter before applying the matcher.
  "
  " See also vimtex#parser#fixme#authors().
  let l:authors = vimtex#parser#fixme#authors()

  let self.re_cmd = '\v\\%(' . join(l:authors.cmd, '|')
        \ . ')%(warning|error|fatal|note)'
        \ . '\*?%(\[[^]]*\])?\{\zs.*'
  let self.re_env = '\v\\begin\s*\{%('
        \ . join(l:authors.env, '|')
        \ . ')%(warning|error|fatal|note)\*?\}'
  let self.re = self.re_cmd . '|' . self.re_env

  let self.prefilter_cmds = ['begin']
  for l:prefix in l:authors.cmd
    let self.prefilter_cmds += [l:prefix . '%(warning|error|fatal|note)']
  endfor
endfunction

" }}}1
function! s:matcher.get_entry(context) abort dict " {{{1
  if a:context.line =~# self.re_cmd
    let title = matchstr(a:context.line, self.re_cmd)
    let label = matchstr(a:context.line, '\v\\\zs\a+%(note|warning|error|fatal)')
  else
    let title = matchstr(a:context.line, self.re_env . '\s*\{\zs.*')
    let label = matchstr(a:context.line, '\v\a+%(note|warning|error|fatal)')
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
