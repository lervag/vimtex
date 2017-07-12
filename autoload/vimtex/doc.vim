" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#doc#init_buffer() " {{{1
  command! -buffer -nargs=? VimtexDocPackage call vimtex#doc#package(<q-args>)

  nnoremap <buffer> <plug>(vimtex-doc-package) :VimtexDocPackage<cr>
endfunction

" }}}1

function! vimtex#doc#package(word) " {{{1
  let l:packages = empty(a:word)
        \ ? s:packages_get_from_cursor()
        \ : [a:word]
  if empty(l:packages) | return | endif

  call s:packages_detect_invalid(l:packages)

  if len(l:packages) == 1
    call s:packages_open_doc(l:packages[0])
  elseif len(l:packages) > 1
    call s:packages_open_doc_list(l:packages)
  endif
endfunction

" }}}1

function! s:packages_get_from_cursor() " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return [] | endif

  if l:cmd.name ==# '\usepackage'
    return s:packages_from_usepackage(l:cmd)
  elseif l:cmd.name ==# '\documentclass'
    return s:packages_from_documentclass(l:cmd)
  else
    return s:packages_from_command(strpart(l:cmd.name, 1))
  endif
endfunction

" }}}1
function! s:packages_from_usepackage(cmd) " {{{1
  try
    let l:packages = split(a:cmd.args[0].text, ',\s*')

    let l:cword = expand('<cword>')
    if len(l:packages) > 1 && index(l:packages, l:cword) >= 0
      return [l:cword]
    endif

    return l:packages
  catch
    call vimtex#echo#warning('Could not parse the package from \usepackage!')
    return []
  endtry
endfunction

" }}}1
function! s:packages_from_documentclass(cmd) " {{{1
  try
    return [a:cmd.args[0].text]
  catch
    call vimtex#echo#warning('Could not parse the package from \documentclass!')
    return []
  endtry
endfunction

" }}}1
function! s:packages_from_command(cmd) " {{{1
  let l:packages = [
        \ 'default',
        \ 'class-' . get(b:vimtex, 'documentclass', ''),
        \] + keys(b:vimtex.packages)
  call filter(l:packages, 'filereadable(s:complete_dir . v:val)')

  let l:queue = copy(l:packages)
  while !empty(l:queue)
    let l:current = remove(l:queue, 0)
    let l:includes = filter(readfile(s:complete_dir . l:current), 'v:val =~# ''^\#\s*include:''')
    if empty(l:includes) | continue | endif

    call map(l:includes, 'matchstr(v:val, ''include:\s*\zs.*\ze\s*$'')')
    call filter(l:includes, 'filereadable(s:complete_dir . v:val)')
    call filter(l:includes, 'index(l:packages, v:val) < 0')

    let l:packages += l:includes
    let l:queue += l:includes
  endwhile

  let l:filter = 'v:val =~# ''^' . a:cmd . '\>'''
  for l:package in l:packages
    let l:cmds = readfile(s:complete_dir . l:package)
    call filter(l:cmds, l:filter)
    if empty(l:cmds) | continue | endif

    if l:package ==# 'default'
      return ['latex2e', 'lshort']
    else
      return [substitute(l:package, '^class-', '', '')]
    endif
  endfor

  call vimtex#echo#warning('Could not find corresponding package')
  return []
endfunction

" }}}1
function! s:packages_detect_invalid(paclist) " {{{1
  let l:invalid_packages = filter(copy(a:paclist),
        \   'empty(vimtex#kpsewhich#find(v:val . ''.sty'')) && '
        \ . 'empty(vimtex#kpsewhich#find(v:val . ''.cls''))')

  call filter(l:invalid_packages,
        \ 'index([''latex2e'', ''lshort''], v:val) < 0')

  if !empty(l:invalid_packages)
    if len(l:invalid_packages) == 1
      call vimtex#echo#warning('Package not recognized: ' . l:invalid_packages[0])
    else
      call vimtex#echo#warning('Packages not recognized:')
      for l:package in l:invalid_packages
        call vimtex#echo#echo('- ' . l:package)
      endfor
    endif
  endif

  " Return if no valid packages remain
  call filter(a:paclist, 'index(l:invalid_packages, v:val) < 0')
endfunction

" }}}1
function! s:packages_open_doc(package) " {{{1
  call vimtex#echo#status(['Open documentation for ',
        \ ['VimtexSuccess', a:package], ' [y/N]? '])

  let l:choice = nr2char(getchar())
  if l:choice ==# 'y'
    echon 'y'
    call s:packages_handler_texdoc(a:package)
  else
    echohl VimtexWarning
    echon l:choice =~# '\w' ? l:choice : 'N'
    echohl NONE
  endif
endfunction

" }}}1
function! s:packages_open_doc_list(packages) " {{{1
  call vimtex#echo#status(['Open documentation for:'])
  let l:count = 0
  for l:package in a:packages
    let l:count += 1
    call vimtex#echo#status([
          \ '  [' . string(l:count) . '] ',
          \ ['VimtexSuccess', l:package]
          \])
  endfor
  call vimtex#echo#status(['Type number (everything else cancels): '])

  let l:choice = nr2char(getchar())
  if l:choice !~# '\d'
        \ || l:choice == 0
        \ || l:choice > len(a:packages)
    echohl VimtexWarning
    echon l:choice =~# '\d' ? l:choice : '-'
    echohl NONE
  else
    echon l:choice
    call s:packages_handler_texdoc(a:packages[l:choice-1])
  endif
endfunction

" }}}1
function! s:packages_handler_texdoc(package) " {{{1
  if !get(s:, 'use_default') && exists('g:vimtex_doc_handler')
    if exists('*' . g:vimtex_doc_handler)
      return call(g:vimtex_doc_handler, [a:package])
    else
      let s:use_default = 1
      call vimtex#echo#warning('g:vimtex_doc_handler must be the name of a function!')
      call vimtex#echo#echo('                Falling back to default handler.')
      return
    endif
  endif

  let l:os = vimtex#util#get_os()
  let l:url = 'http://texdoc.net/pkg/' . a:package

  silent execute (l:os ==# 'linux'
        \         ? '!xdg-open'
        \         : (l:os ==# 'mac'
        \            ? '!open'
        \            : '!start /b'))
        \ . ' ' . l:url
        \ . (l:os ==# 'win' ? '' : ' &')
endfunction

" }}}1

let s:complete_dir = fnamemodify(expand('<sfile>'), ':h') . '/complete/'

" vim: fdm=marker sw=2
