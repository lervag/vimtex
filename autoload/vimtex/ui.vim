" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#ui#choose(container, ...) abort " {{{1
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

  sleep 50m
  redraw!

  return l:index < 0 ? '' : l:return_list[l:index]
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

  let l:choice = vimtex#ui#choose(a:actions.menu, {
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

function! s:choose_from(list, options) abort " {{{1
  if len(a:list) == 1 | return a:list[0] | endif

  while 1
    redraw!
    unsilent call vimtex#echo#echo(a:options.prompt)

    let l:choices = 0
    if a:options.abort
      unsilent call vimtex#echo#formatted([['VimtexWarning', '0'], ': Abort'])
    endif
    for l:x in a:list
      let l:choices += 1
      unsilent call vimtex#echo#formatted(
            \ [['VimtexWarning', l:choices], ': ',
            \  type(l:x) == v:t_dict ? l:x.name : l:x]
            \)
    endfor

    try
      let l:choice = l:choices > 9
              \ ? s:_get_choice_many()
              \ : s:_get_choice_few()

      if a:options.abort && l:choice == 0
        return -1
      endif

      let l:choice -= 1
      if l:choice >= 0 && l:choice < len(a:list)
        return l:choice
      endif
    endtry
  endwhile
endfunction

" }}}1

function! s:_get_choice_few() abort " {{{1
  echo '> '
  let l:choice = nr2char(getchar())
  echon l:choice
  return l:choice
endfunction

" }}}1
function! s:_get_choice_many() abort " {{{1
  return str2nr(input('> '))
endfunction

" }}}1
