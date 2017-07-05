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
  let l:package = empty(a:word)
        \ ? s:package_get_current()
        \ : a:word

  if empty(l:package) | return | endif

  if empty(vimtex#kpsewhich#find(l:package . '.sty'))
    call vimtex#echo#warning('Package not recognized: ' . l:package)
    return
  endif

  call vimtex#echo#status(['Open documentation for ',
        \ ['VimtexSuccess', l:package], '? [y/N] > '])
  if nr2char(getchar()) ==# 'y'
    silent execute '!xdg-open http://texdoc.net/pkg/' . l:package . '&'
  else
    echon 'N'
    sleep 300m
  endif

  redraw!
endfunction

" }}}1

function! s:package_get_current() " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return '' | endif

  if l:cmd.name ==# '\usepackage'
    try
      let l:packages = split(l:cmd.args[0].text, ',\s*')

      let l:cword = expand('<cword>')
      if len(l:packages) > 1 && index(l:packages, l:cword) >= 0
        return l:cword
      endif

      return l:packages[0]
    catch
      call vimtex#echo#warning('Could not parse the package from \usepackage!')
      return ''
    endtry
  else
    return s:package_from_command(strpart(l:cmd.name, 1))
  endif
endfunction

" }}}1
function! s:package_from_command(cmd) " {{{1
  let l:packages = [
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
    if !empty(l:cmds) | return l:package | endif
  endfor

  call vimtex#echo#warning('Could not find corresponding package')
  return ''
endfunction

" }}}1

let s:complete_dir = fnamemodify(expand('<sfile>'), ':h') . '/complete/'

" vim: fdm=marker sw=2
