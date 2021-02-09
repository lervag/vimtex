" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#todo_notes#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'prefilter_cmds' : ['todo'],
      \ 'priority' : 2,
      \ 're' : g:vimtex#re#not_comment . '\\\w*todo\w*%(\[[^]]*\])?\{\zs.*',
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  let title = matchstr(a:context.line, self.re)

  let [l:end, l:count] = vimtex#parser#tex#find_closing(0, title, 1, '{')
  if l:count == 0
    let title = strpart(title, 0, l:end)
  else
    let self.count = l:count
    let a:context.continue = 'todo_notes'
  endif

  let l:label = get(g:vimtex_toc_todo_labels, 'TODO', 'TODO: ')

  return {
        \ 'title'  : l:label . title,
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
