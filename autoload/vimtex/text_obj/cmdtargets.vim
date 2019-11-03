" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#text_obj#cmdtargets#new(args) " {{{1
  return {
        \ 'genFuncs': {
        \   'c': function('vimtex#text_obj#cmdtargets#current'),
        \   'n': function('vimtex#text_obj#cmdtargets#next'),
        \   'l': function('vimtex#text_obj#cmdtargets#last'),
        \ },
        \ 'modFuncs': {
        \   'i': [function('vimtex#text_obj#cmdtargets#inner'),
        \         function('targets#modify#drop')],
        \   'a': [function('targets#modify#keep')],
        \   'I': [function('vimtex#text_obj#cmdtargets#inner'),
        \         function('targets#modify#shrink')],
        \   'A': [function('targets#modify#expand')],
        \ }}
endfunction

" }}}1
function! vimtex#text_obj#cmdtargets#current(args, opts, state) " {{{1
  let target = s:select(a:opts.first ? 1 : 2)
  call target.cursorE() " keep going from right end
  return target
endfunction

" }}}1
function! vimtex#text_obj#cmdtargets#next(args, opts, state) " {{{1
  if targets#util#search('\\\S*{', 'W') > 0
    return targets#target#withError('no target')
  endif

  let oldpos = getpos('.')
  let target = s:select(1)
  call setpos('.', oldpos)
  return target
endfunction

" }}}1
function! vimtex#text_obj#cmdtargets#last(args, opts, state) " {{{1
  " Move to the last non-surrounding cmd
  if targets#util#search('\\\S\+{\_.\{-}}', 'bWe') > 0
    return targets#target#withError('no target')
  endif

  let oldpos = getpos('.')
  let target = s:select(1)
  call setpos('.', oldpos)
  return target
endfunction

" }}}1
function! vimtex#text_obj#cmdtargets#inner(target, args) " {{{1
  if a:target.state().isInvalid()
    return
  endif

  call a:target.cursorS()
  silent! normal! f{
  call a:target.setS()
endfunction

" }}}1

function! s:select(count) " {{{1
  " Try to select command
  silent! execute 'keepjumps normal v'.a:count."\<Plug>(vimtex-ac)v"
  let target = targets#target#fromVisualSelection()

  if target.sc == target.ec && target.sl == target.el
    return targets#target#withError('tex_cmd select')
  endif

  return target
endfunction

" }}}1
