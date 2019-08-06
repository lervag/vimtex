" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#echo#echo(message) abort " {{{1
  echohl VimtexMsg
  echo a:message
  echohl None
endfunction

" }}}1
function! vimtex#echo#input(opts) abort " {{{1
  if g:vimtex_echo_verbose_input
        \ && has_key(a:opts, 'info')
    call vimtex#echo#formatted(a:opts.info)
  endif

  let l:args = [get(a:opts, 'prompt', '> ')]
  let l:args += [get(a:opts, 'default', '')]
  if has_key(a:opts, 'complete')
    let l:args += [a:opts.complete]
  endif

  echohl VimtexMsg
  let l:reply = call('input', l:args)
  echohl None
  return l:reply
endfunction

" }}}1
function! vimtex#echo#choose(list_or_dict, prompt) abort " {{{1
  if empty(a:list_or_dict) | return '' | endif

  return type(a:list_or_dict) == type({})
        \ ? s:choose_dict(a:list_or_dict, a:prompt)
        \ : s:choose_list(a:list_or_dict, a:prompt)
endfunction

" }}}1
function! vimtex#echo#formatted(parts) abort " {{{1
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

" }}}1

function! s:choose_dict(dict, prompt) abort " {{{1
  if len(a:dict) == 1
    return values(a:dict)[0]
  endif

  while v:true
    redraw!
    if !empty(a:prompt)
      echohl VimtexMsg
      unsilent echo a:prompt
      echohl None
    endif

    let l:choice = 0
    for l:x in values(a:dict)
      let l:choice += 1
      unsilent call vimtex#echo#formatted([['VimtexWarning', l:choice], ': ', l:x])
    endfor

    try
      let l:choice = str2nr(input('> ')) - 1
      if l:choice >= 0 && l:choice < len(a:dict)
        return keys(a:dict)[l:choice]
      endif
    endtry
  endwhile
endfunction

" }}}1
function! s:choose_list(list, prompt) abort " {{{1
  if len(a:list) == 1 | return a:list[0] | endif

  while v:true
    redraw!
    if !empty(a:prompt)
      echohl VimtexMsg
      unsilent echo a:prompt
      echohl None
    endif

    let l:choice = 0
    for l:x in a:list
      let l:choice += 1
      unsilent call vimtex#echo#formatted([['VimtexWarning', l:choice], ': ', l:x])
    endfor

    try
      let l:choice = str2nr(input('> ')) - 1
      if l:choice >= 0 && l:choice < len(a:list)
        return a:list[l:choice]
      endif
    endtry
  endwhile
endfunction

" }}}1
