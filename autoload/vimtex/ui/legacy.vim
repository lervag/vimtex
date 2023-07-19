" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#ui#legacy#confirm(prompt) abort " {{{1
  let l:prompt = type(a:prompt) == v:t_list ? a:prompt : [a:prompt]
  let l:prompt[-1] .= ' [y]es/[n]o: '

  while v:true
    redraw!
    call vimtex#ui#echo(l:prompt)

    let l:input = nr2char(getchar())
    if index(["\<c-c>", "\<esc>"], l:input) >= 0
      break
    endif

    if index(['y', 'Y', 'n', 'N'], l:input) >= 0
      echon l:input
      sleep 75m
      redraw!
      break
    endif
  endwhile

  return l:input ==? 'y'
endfunction

" }}}1
function! vimtex#ui#legacy#input(options) abort " {{{1
  if g:vimtex_echo_verbose_input && !empty(a:options.info)
    redraw!
    call vimtex#ui#echo(a:options.info)
  endif

  echohl VimtexMsg
  let l:input = has_key(a:options, 'completion')
        \ ? input(a:options.prompt, a:options.text, a:options.completion)
        \ : input(a:options.prompt, a:options.text)
  echohl None

  return l:input
endfunction

" }}}1
function! vimtex#ui#legacy#select(options, list) abort " {{{1
  let l:length = len(a:list)
  let l:digits = len(l:length)

  " Use simple menu when in operator mode
  if !empty(&operatorfunc)
    let l:choices = map(deepcopy(a:list), { i, x -> (i+1) . ': ' . x })
    let l:choice = inputlist(l:choices) - 1
    return l:choice >= 0 && l:choice < l:length
          \ ? [l:choice, a:list[l:choice]]
          \ : [-1, '']
  endif

  " Create the menu
  let l:menu = [a:options.prompt]
  let l:format = printf('%%%dd: ', l:digits)
  let l:i = 0
  for l:x in a:list
    let l:i += 1
    call add(l:menu, [
          \ ['VimtexWarning', printf(l:format, l:i)],
          \ type(l:x) == v:t_dict ? l:x.name : l:x
          \])
  endfor
  if !a:options.force_choice
    call add(l:menu, [
          \ ['VimtexWarning', repeat(' ', l:digits - 1) . 'x: '],
          \ 'Abort'
          \])
  endif

  " Loop to get a valid choice
  let l:value = ''
  while v:true
    redraw!

    for l:line in l:menu
      call vimtex#ui#echo(l:line)
    endfor

    let l:choice = vimtex#ui#get_number(
          \ l:length, l:digits, a:options.force_choice, v:true)

    if !a:options.force_choice && l:choice == -2
      break
    endif

    if l:choice >= 0 && l:choice < l:length
      let l:value = a:list[l:choice]
      break
    endif
  endwhile

  sleep 75m
  redraw!
  return [l:choice, l:value]
endfunction

" }}}1
