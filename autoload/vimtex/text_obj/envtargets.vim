" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#text_obj#envtargets#new(args) " {{{1
  return {
        \ 'genFuncs': {
        \   'c': function('vimtex#text_obj#envtargets#current'),
        \   'n': function('vimtex#text_obj#envtargets#next'),
        \   'l': function('vimtex#text_obj#envtargets#last'),
        \ },
        \ 'modFuncs': {
        \   'i': [function('vimtex#text_obj#envtargets#inner'), function('targets#modify#drop')],
        \   'a': [function('targets#modify#keep')],
        \   'I': [function('vimtex#text_obj#envtargets#inner'), function('targets#modify#shrink')],
        \   'A': [function('vimtex#text_obj#envtargets#expand')],
        \ }}
endfunction

" }}}1
function! vimtex#text_obj#envtargets#current(args, opts, state) " {{{1
  let target = s:select(a:opts.first ? 1 : 2)
  call target.cursorE() " keep going from right end
  return target
endfunction

" }}}1
function! vimtex#text_obj#envtargets#next(args, opts, state) " {{{1
  if targets#util#search('\\begin{.*}', 'W') > 0
    return targets#target#withError('no target')
  endif

  let oldpos = getpos('.')
  let target = s:select(1)
  call setpos('.', oldpos)
  return target
endfunction

" }}}1
function! vimtex#text_obj#envtargets#last(args, opts, state) " {{{1
  if targets#util#search('\\end{.*}', 'bW') > 0
    return targets#target#withError('no target')
  endif

  let oldpos = getpos('.')
  let target = s:select(1)
  call setpos('.', oldpos)
  return target
endfunction

" }}}1
function! vimtex#text_obj#envtargets#inner(target, args) " {{{1
  call a:target.cursorS()
  call a:target.searchposS('\\begin{.*}', 'Wce')
  call a:target.cursorE()
  call a:target.searchposE('\\end{.*}', 'bWc')
endfunction

" }}}1
function! vimtex#text_obj#envtargets#expand(target, args) " {{{1
  " Based on targets#modify#expand() from
  "   $VIMMRUNTIME/autoload/targets/modify.vim

  " Add outer whitespace
  if a:0 == 0 || a:1 ==# '>'
    call a:target.cursorE()
    let [line, column] = searchpos('\S\|$', '')
    if line > a:target.el || (line > 0 && column-1 > a:target.ec)
      " non whitespace or EOL after trailing whitespace found
      " not counting whitespace directly after end
      return a:target.setE(line, column-1)
    endif
  endif

  if a:0 == 0 || a:1 ==# '<'
    call a:target.cursorS()
    let [line, column] = searchpos('\S', 'b')
    if line < a:target.sl
      return a:target.setS(line+1, 0)
    elseif line > 0
      " non whitespace before leading whitespace found
      return a:target.setS(line, column+1)
    endif
    " only whitespace in front of start
    " include all leading whitespace from beginning of line
    let a:target.sc = 1
  endif
endfunction

" }}}1

function! s:select(count) " {{{1
  " Try to select environment
  silent! execute 'keepjumps normal v'.a:count."\<Plug>(vimtex-ae)v"
  let target = targets#target#fromVisualSelection()

  if target.sc == target.ec && target.sl == target.el
    return targets#target#withError('tex_env select')
  endif

  return target
endfunction

" }}}1
