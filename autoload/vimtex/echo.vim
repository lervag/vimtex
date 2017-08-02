" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#echo#echo(message) " {{{1
  echohl VimtexMsg
  echo a:message
  echohl None
endfunction

" }}}1
function! vimtex#echo#input(opts) " {{{1
  if has_key(a:opts, 'info')
    call vimtex#echo#formatted(a:opts.info)
  endif

  let l:args = [get(a:opts, 'prompt', '> ')]
  if has_key(a:opts, 'complete')
    let l:args += ['', a:opts.complete]
  endif

  echohl VimtexMsg
  let l:reply = call('input', l:args)
  echohl None
  return l:reply
endfunction

" }}}1

function! vimtex#echo#formatted(parts) " {{{1
  echo ''
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

    " l:entry[0] == title
    " l:entry[1] == value
    for l:entry in a:list
      if l:entry[0] ==# 'name'
        let l:name = l:entry[1]
        break
      endif
      let l:index += 1
    endfor

    if empty(l:name)
      let l:list = a:list
    else
      let l:list = deepcopy(a:list)
      call remove(l:list, l:index)
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

" vim: fdm=marker sw=2
