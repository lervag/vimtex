" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#doc#init_buffer() abort " {{{1
  command! -buffer -nargs=? VimtexDocPackage call vimtex#doc#package(<q-args>)

  nnoremap <buffer> <plug>(vimtex-doc-package) :VimtexDocPackage<cr>
endfunction

" }}}1

function! vimtex#doc#package(word) abort " {{{1
  let l:context = empty(a:word)
        \ ? s:packages_get_from_cursor()
        \ : {
        \     'type': 'word',
        \     'candidates': [a:word],
        \   }
  if empty(l:context) | return | endif

  call s:packages_remove_invalid(l:context)

  for l:handler in g:vimtex_doc_handlers
    if exists('*' . l:handler)
      if call(l:handler, [l:context]) | return | endif
    endif
  endfor

  call s:packages_open(l:context)
endfunction

" }}}1
function! vimtex#doc#make_selection(context) abort " {{{1
  if has_key(a:context, 'selected') | return | endif

  if len(a:context.candidates) == 0
    if exists('a:context.name')
      echohl ErrorMsg
      echo 'Sorry, no doc for '.a:context.name
      echohl NONE
    endif
    let a:context.selected = ''
    return
  endif

  let a:context.selected = vimtex#ui#choose(a:context.candidates, {
        \ 'prompt': 'Multiple candidates detected, please select one:',
        \})
  let a:context.ask_before_open = len(a:context.candidates) == 1
endfunction

" }}}1

function! s:packages_get_from_cursor() abort " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return {} | endif

  if l:cmd.name ==# '\usepackage'
    return s:packages_from_usepackage(l:cmd)
  elseif l:cmd.name ==# '\documentclass'
    return s:packages_from_documentclass(l:cmd)
  elseif l:cmd.name =~# '\v\\%(begin|end)$'
    return s:packages_from_environment(l:cmd)
  else
    return s:packages_from_command(strpart(l:cmd.name, 1))
  endif
endfunction

" }}}1
function! s:packages_from_usepackage(cmd) abort " {{{1
  try
    " Gather and clean up candidate list
    let l:candidates = substitute(a:cmd.args[0].text, '%.\{-}\n', '', 'g')
    let l:candidates = substitute(l:candidates, '\s*', '', 'g')
    let l:candidates = split(l:candidates, ',')

    let l:context = {
          \ 'type': 'usepackage',
          \ 'candidates': l:candidates,
          \}

    let l:cword = expand('<cword>')
    if len(l:context.candidates) > 1 && index(l:context.candidates, l:cword) >= 0
      let l:context.selected = l:cword
    endif

    return l:context
  catch
    call vimtex#log#warning('Could not parse the package from \usepackage!')
    return {}
  endtry
endfunction

" }}}1
function! s:packages_from_documentclass(cmd) abort " {{{1
  try
    return {
          \ 'type': 'documentclass',
          \ 'candidates': [a:cmd.args[0].text],
          \}
  catch
    call vimtex#log#warning('Could not parse the package from \documentclass!')
    return {}
  endtry
endfunction

" }}}1
function! s:packages_from_environment(cmd) abort " {{{1
  try
    let l:env = a:cmd.args[0].text
  catch
    call vimtex#log#warning('Could not parse the environment name!')
    return {}
  endtry

  return s:packages_from_command('\begin{' . l:env . '}')
endfunction

" }}}1
function! s:packages_from_command(cmd) abort " {{{1
  let l:packages = [
        \ 'default',
        \ 'class-' . get(b:vimtex, 'documentclass', ''),
        \] + keys(b:vimtex.packages)
  call filter(l:packages, 'filereadable(s:complete_dir . v:val)')

  let l:queue = copy(l:packages)
  while !empty(l:queue)
    let l:current = remove(l:queue, 0)
    let l:includes = filter(readfile(s:complete_dir . l:current),
          \ 'v:val =~# ''^\#\s*include:''')
    if empty(l:includes) | continue | endif

    call map(l:includes, {_, x -> matchstr(x, 'include:\s*\zs.*\ze\s*$')})
    call filter(l:includes, 'filereadable(s:complete_dir . v:val)')
    call filter(l:includes, 'index(l:packages, v:val) < 0')

    let l:packages += l:includes
    let l:queue += l:includes
  endwhile

  let l:candidates = []
  for l:package in l:packages
    let l:cmds = filter(
          \ readfile(s:complete_dir . l:package),
          \ {_, x -> x ==# a:cmd})
    if empty(l:cmds) | continue | endif

    if l:package ==# 'default'
      call extend(l:candidates, ['latex2e', 'lshort'])
    else
      call add(l:candidates, substitute(l:package, '^class-', '', ''))
    endif
  endfor

  return {
        \ 'type': 'command',
        \ 'name': a:cmd,
        \ 'candidates': l:candidates,
        \}
endfunction

" }}}1

function! s:packages_remove_invalid(context) abort " {{{1
  let l:invalid_packages = filter(copy(a:context.candidates), {_, x ->
        \    empty(vimtex#kpsewhich#find(x . '.sty'))
        \ && empty(vimtex#kpsewhich#find(x . '.cls'))})

  call filter(l:invalid_packages, "index(['latex2e', 'lshort'], v:val) < 0")

  " Warn about invalid candidates
  if !empty(l:invalid_packages)
    if len(l:invalid_packages) == 1
      call vimtex#log#warning(
            \ 'Package not recognized: ' . l:invalid_packages[0])
    else
      call vimtex#log#warning(
            \ 'Packages not recognized:',
            \ map(copy(l:invalid_packages), "'- ' . v:val"))
    endif
  endif

  " Remove invalid candidates
  call filter(a:context.candidates, 'index(l:invalid_packages, v:val) < 0')

  " Reset the selection if the selected candidate is not valid
  if has_key(a:context, 'selected')
        \ && index(a:context.candidates, a:context.selected) < 0
    unlet a:context.selected
  endif
endfunction

" }}}1
function! s:packages_open(context) abort " {{{1
  if !has_key(a:context, 'selected')
    call vimtex#doc#make_selection(a:context)
  endif

  if empty(a:context.selected) | return | endif

  if get(a:context, 'ask_before_open', 1)
    call vimtex#echo#formatted([
          \ 'Open documentation for ',
          \ ['VimtexSuccess', a:context.selected], ' [y/N]? '
          \])

    let l:choice = nr2char(getchar())
    if l:choice ==# 'y'
      echon 'y'
    else
      echohl VimtexWarning
      echon l:choice =~# '\w' ? l:choice : 'N'
      echohl NONE
      return
    endif
  endif

  call vimtex#util#www('http://texdoc.net/pkg/' . a:context.selected)
  redraw!
endfunction

" }}}1

let s:complete_dir = fnamemodify(expand('<sfile>'), ':h') . '/complete/'
