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
function! vimtex#echo#choose(container, ...) abort " {{{1
  if empty(a:container) | return '' | endif

  if type(a:container) == v:t_dict
    let l:choose_list = values(a:container)
    let l:return_list = keys(a:container)
  else
    let l:choose_list = a:container
    let l:return_list = a:container
  endif

  let l:options = extend(
        \ {
        \   'prompt': 'Please choose item:',
        \   'abort': v:true,
        \ },
        \ a:0 > 0 ? a:1 : {})

  let l:index = s:choose_from(l:choose_list, l:options)
  if l:index < 0 | return '' | endif
  return l:return_list[l:index]
endfunction

" }}}1
function! vimtex#echo#formatted(parts) abort " {{{1
  echo ''
  try
    for part in a:parts
      if type(part) == v:t_string
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

function! s:choose_from(list, options) abort " {{{1
  if len(a:list) == 1 | return a:list[0] | endif

  while 1
    redraw!
    echohl VimtexMsg
    unsilent echo a:options.prompt
    echohl None

    let l:choices = 0
    if a:options.abort
      unsilent call vimtex#echo#formatted(
            \ [['VimtexWarning', '0'], ': Abort'])
    endif
    for l:x in a:list
      let l:choices += 1
      unsilent call vimtex#echo#formatted(
            \ [['VimtexWarning', l:choices], ': ', l:x])
    endfor

    try
      let l:choice = l:choices > 9
              \ ? s:_get_choice_many()
              \ : s:_get_choice_few()
      if a:options.abort && l:choice == 0
        echon l:choice
        return -1
      endif
      let l:choice -= 1
      if l:choice >= 0 && l:choice < len(a:list)
        echon l:choice
        return l:choice
      endif
    endtry
  endwhile
endfunction

" }}}1

function! s:_get_choice_few() abort " {{{1
  echo '> '
  return nr2char(getchar())
endfunction

" }}}1
function! s:_get_choice_many() abort " {{{1
  return str2nr(input('> '))
endfunction

" }}}1
