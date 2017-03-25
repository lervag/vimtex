" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#echo#init_buffer() " {{{1
endfunction

" }}}1

function! vimtex#echo#wait() " {{{1
  if get(g:, 'vimtex_echo_ignore_wait') | return | endif

  if filereadable(expand('%'))
    echohl VimtexMsg
    call input('Press ENTER to continue')
    echohl None
  else
    sleep 1
  endif
endfunction

function! vimtex#echo#echo(message) " {{{1
  echohl VimtexMsg
  echo a:message
  echohl None
endfunction

function! vimtex#echo#warning(message) " {{{1
  call vimtex#echo#formatted([
        \ ['VimtexWarning', 'vimtex warning: '],
        \ ['VimtexMsg', a:message]])
endfunction

function! vimtex#echo#info(message) " {{{1
  call vimtex#echo#formatted([
        \ ['VimtexInfo', 'vimtex: '],
        \ ['VimtexMsg', a:message]])
endfunction

function! vimtex#echo#formatted(parts) " {{{1
  echon "\r"
  try
    for part in a:parts
      if type(part) == type('')
        echohl VimtexMsg
        echon part
      else
        execute 'echohl' part[0]
        echon part[1]
      endif
      unlet part
    endfor
  finally
    echohl None
  endtry
endfunction

function! vimtex#echo#status(parts) " {{{1
  echon "\r"
  call vimtex#echo#formatted(a:parts)
endfunction

" }}}1
function! vimtex#echo#pair(title, Value, ...) " {{{1
  let l:indent = a:0 > 0 ? repeat(' ', 2*a:1) : ''

  if type(a:Value) == type([])
    let l:format = a:Value[0]
    let l:Value = a:Value[1]
  else
    let l:format = 'None'
    let l:Value = a:Value
  endif

  if type(l:Value) == type(function('tr'))
    let l:value = string(l:Value)
  else
    let l:value = l:Value
  endif

  call vimtex#echo#formatted([l:indent . a:title . ': ',
        \ [l:format, l:value . "\n"]])
endfunction

" }}}1
function! vimtex#echo#pprint(item, ...) abort " {{{1
  if empty(a:item) | return | endif
  let l:indent = a:0 > 0 ? a:1 : 0

  if type(a:item) == type({})
    call s:pprint_dict(a:item, l:indent)
    return
  endif

  if type(a:item) == type([])
    for [l:title, l:Value] in a:item

      if type(l:Value) == type({})
        call s:pprint_dict(l:Value, l:indent, l:title)
      elseif type(l:Value) == type([])
        call s:pprint_list(l:Value, l:indent, l:title)
      else
        call vimtex#echo#pair(l:title, l:Value, l:indent)
      endif

      unlet l:Value
    endfor
  endif
endfunction

" }}}1

function! s:pprint_dict(dict, indent, ...) abort " {{{1
  if empty(a:dict) | return | endif
  let l:dict = a:dict
  let l:indent = a:indent

  if a:0 > 0
    let l:title = a:1
    let l:name = ''
    if has_key(a:dict, 'name')
      let l:dict = deepcopy(a:dict)
      let l:name = remove(l:dict, 'name')
    endif
    call vimtex#echo#pair(l:title, ['VimtexInfo', l:name], l:indent)
    let l:indent += 1
  endif

  let l:items = has_key(l:dict, 'pprint_items')
        \ ? l:dict.pprint_items() : items(l:dict)

  call vimtex#echo#pprint(l:items, l:indent)
endfunction

" }}}1
function! s:pprint_list(list, indent, title) abort " {{{1
  if empty(a:list) | return | endif

  if type(a:list[0]) == type([])
    let l:name = ''
    let l:index = 0
    for [l:title, l:value] in a:list
      if l:title ==# 'name'
        let l:name = l:value
        break
      endif
      let l:index += 1
    endfor
    if !empty(l:name)
      let l:list = deepcopy(a:list)
      call remove(l:list, l:index)
    else
      let l:list = a:list
    endif

    call vimtex#echo#pair(a:title, ['VimtexInfo', l:name], a:indent)
    call vimtex#echo#pprint(l:list, a:indent+1)
  else
    call vimtex#echo#pair(a:title, '', a:indent)

    let l:indent = repeat(' ', 2*a:indent) . '  '
    for l:value in a:list
      call vimtex#echo#formatted([['None', l:indent . l:value . "\n"]])
    endfor
  endif
endfunction

" }}}1


" {{{1 Initialize options

call vimtex#util#set_default('g:vimtex_echo_ignore_wait', 0)

" }}}1
" {{{1 Initialize module

call vimtex#util#set_highlight('VimtexMsg', 'ModeMsg')
call vimtex#util#set_highlight('VimtexSuccess', 'Statement')
call vimtex#util#set_highlight('VimtexWarning', 'WarningMsg')
call vimtex#util#set_highlight('VimtexInfo', 'Question')

" }}}1

" vim: fdm=marker sw=2
