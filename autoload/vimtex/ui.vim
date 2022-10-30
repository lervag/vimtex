" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#ui#echo(input, ...) abort " {{{1
  if empty(a:input) | return | endif
  let l:opts = extend({'indent': 0}, a:0 > 0 ? a:1 : {})

  if type(a:input) == v:t_string
    call s:echo_string(a:input, l:opts)
  elseif type(a:input) == v:t_list
    call s:echo_formatted(a:input, l:opts)
  elseif type(a:input) == v:t_dict
    call s:echo_dict(a:input, l:opts)
  else
    call vimtex#log#warn('Argument not supported: ' . type(a:input))
  endif
endfunction

" }}}1
function! vimtex#ui#input(opts) abort " {{{1
  let l:opts = extend({'prompt': '> ', 'text': ''}, a:opts)

  if g:vimtex_echo_verbose_input && has_key(l:opts, 'info')
    redraw!
    call vimtex#ui#echo(l:opts.info)
  endif

  echohl VimtexMsg
  let l:reply = has_key(l:opts, 'completion')
        \ ? input(l:opts.prompt, l:opts.text, l:opts.completion)
        \ : input(l:opts.prompt, l:opts.text)
  echohl None
  return l:reply
endfunction

" }}}1
function! vimtex#ui#input_quick_from(prompt, choices) abort " {{{1
  while v:true
    redraw!
    call vimtex#ui#echo(a:prompt)
    let l:input = nr2char(getchar())

    if index(["\<C-c>", "\<Esc>"], l:input) >= 0
      echon 'aborted!'
      return ''
    endif

    if index(a:choices, l:input) >= 0
      echon l:input
      return l:input
    endif
  endwhile
endfunction

" }}}1
function! vimtex#ui#confirm(prompt) abort " {{{1
  if type(a:prompt) != v:t_list
    let l:prompt = [a:prompt]
  else
    let l:prompt = a:prompt
  endif
  let l:prompt[-1] .= ' [y]es/[n]o: '

  return vimtex#ui#input_quick_from(l:prompt, ['y', 'n']) ==# 'y'
endfunction

" }}}1
function! vimtex#ui#menu(actions) abort " {{{1
  " Argument: The 'actions' argument is a dictionary/object which contains
  "   a list of menu items and corresponding actions (dict functions).
  "   Something like this:
  "
  "   let a:actions = {
  "         \ 'prompt': 'Prompt string for menu',
  "         \ 'menu': [
  "         \   {'name': 'My first action',
  "         \    'func': 'action1'},
  "         \   {'name': 'My second action',
  "         \    'func': 'action2'},
  "         \   ...
  "         \ ],
  "         \ 'action1': Func,
  "         \ 'action2': Func,
  "         \ ...
  "         \}
  if empty(a:actions) | return | endif

  let l:choice = vimtex#ui#select(a:actions.menu, {
        \ 'prompt': a:actions.prompt,
        \})
  if empty(l:choice) | return | endif

  try
    call a:actions[l:choice.func]()
  catch
    " error here
  endtry
endfunction

" }}}1
function! vimtex#ui#select(container, ...) abort " {{{1
  if empty(a:container) | return '' | endif

  let l:options = extend(
        \ {
        \   'abort': v:true,
        \   'prompt': 'Please choose item:',
        \   'return': 'value',
        \ },
        \ a:0 > 0 ? a:1 : {})

  let [l:index, l:value] = s:choose_from(
        \ type(a:container) == v:t_dict ? values(a:container) : a:container,
        \ l:options)
  sleep 75m
  redraw!

  if l:options.return ==# 'value'
    return l:value
  endif

  if type(a:container) == v:t_dict
    return l:index >= 0 ? keys(a:container)[l:index] : ''
  endif

  return l:index
endfunction

" }}}1

function! vimtex#ui#get_winwidth() abort " {{{1
  let l:numwidth = (&number || &relativenumber)
        \ ? max([&numberwidth, strlen(line('$')) + 1])
        \ : 0
  let l:foldwidth = str2nr(matchstr(&foldcolumn, '\d\+$'))

  " Get width of signcolumn
  " Note: A signcolumn is 2-char wide, so in some cases we multiply by 2
  if &signcolumn ==# 'yes'
    let l:signwidth = 2
  elseif &signcolumn =~# 'yes'
    let l:signwidth = 2*split(&signcolumn, ':')[1]
  elseif &signcolumn ==# 'auto'
    let l:signlist = split(execute(
          \ printf('sign place %s buffer=%d',
          \   has('nvim-0.4.2') || has('patch-8.1.614') ? 'group=*' : '',
          \   bufnr())), "\n")
    let l:signwidth = len(l:signlist) > 2 ? 2 : 0
  elseif &signcolumn =~# 'auto'
    " Get number of signs on each line that has a sign
    let l:sign_lenths = map(
          \ sign_getplaced(bufnr(), {'group': '*'})[0].signs,
          \ { _, x -> len(
          \   sign_getplaced(bufnr(),
          \                  {'group': '*', 'lnum': x.lnum})[0].signs)})
    let l:signwidth = 2*max(l:sign_lenths)
  else
    let l:signwidth = 0
  endif

  return winwidth(0) - l:numwidth - l:foldwidth - l:signwidth
endfunction

" }}}1

function! s:echo_string(msg, opts) abort " {{{1
  echohl VimtexMsg
  echo repeat(' ', a:opts.indent) . a:msg
  echohl None
endfunction

" }}}1
function! s:echo_formatted(parts, opts) abort " {{{1
  echo repeat(' ', a:opts.indent)
  try
    for l:part in a:parts
      if type(l:part) == v:t_string
        echohl VimtexMsg
        echon l:part
      else
        execute 'echohl' l:part[0]
        echon l:part[1]
      endif
      unlet l:part
    endfor
  finally
    echohl None
  endtry
endfunction

" }}}1
function! s:echo_dict(dict, opts) abort " {{{1
  for [l:key, l:val] in items(a:dict)
    call s:echo_formatted([['Label', l:key . ': '], l:val], a:opts)
  endfor
endfunction

" }}}1

function! s:choose_from(list, options) abort " {{{1
  let l:length = len(a:list)
  let l:digits = len(l:length)
  if l:length == 1 | return [0, a:list[0]] | endif

  " Create the menu
  let l:menu = []
  let l:format = printf('%%%dd', l:digits)
  let l:i = 0
  for l:x in a:list
    let l:i += 1
    call add(l:menu, [
          \ ['VimtexWarning', printf(l:format, l:i) . ': '],
          \ type(l:x) == v:t_dict ? l:x.name : l:x
          \])
  endfor
  if a:options.abort
    call add(l:menu, [
          \ ['VimtexWarning', repeat(' ', l:digits - 1) . 'x: '],
          \ 'Abort'
          \])
  endif

  " Loop to get a valid choice
  while 1
    redraw!

    call vimtex#ui#echo(a:options.prompt)
    for l:line in l:menu
      call vimtex#ui#echo(l:line)
    endfor

    try
      let l:choice = s:get_number(l:length, l:digits, a:options.abort)
      if a:options.abort && l:choice == -2
        return [-1, '']
      endif

      if l:choice >= 0 && l:choice < len(a:list)
        return [l:choice, a:list[l:choice]]
      endif
    endtry
  endwhile
endfunction

" }}}1
function! s:get_number(max, digits, abort) abort " {{{1
  let l:choice = ''
  echo '> '

  while len(l:choice) < a:digits
    if len(l:choice) > 0 && (l:choice . '0') > a:max
      return l:choice - 1
    endif

    let l:input = nr2char(getchar())

    if index(["\<C-c>", "\<Esc>"], l:input) >= 0
      echon 'aborted!'
      return -2
    endif

    if a:abort && l:input ==# 'x'
      echon l:input
      return -2
    endif

    if len(l:choice) > 0 && l:input ==# "\<cr>"
      return l:choice - 1
    endif

    if l:input !~# '\d' | continue | endif

    if (l:choice . l:input) > 0
      let l:choice .= l:input
      echon l:input
    endif
  endwhile

  return l:choice - 1
endfunction

" }}}1
