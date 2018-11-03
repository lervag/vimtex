" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:did_indent')
  finish
endif

if !get(g:, 'vimtex_indent_bib_enabled', 1) | finish | endif

let b:did_indent = 1

let s:cpo_save = &cpo
set cpo&vim

setlocal autoindent
setlocal indentexpr=VimtexIndentBib()

function! VimtexIndentBib() abort " {{{1
  " Find first non-blank line above the current line
  let lnum = prevnonblank(v:lnum - 1)
  if lnum == 0
    return 0
  endif

  " Get some initial conditions
  let ind   = indent(lnum)
  let line  = getline(lnum)
  let cline = getline(v:lnum)
  let g:test = 1

  " Zero indent for first line of each entry
  if cline =~# '^\s*@'
    return 0
  endif

  " Title line of entry
  if line =~# '^@'
    if cline =~# '^\s*}'
      return 0
    else
      return &sw
    endif
  endif

  if line =~# '='
    " Indent continued bib info entries
    if s:count('{', line) - s:count('}', line) > 0
      let match = searchpos('.*=\s*{','bcne')
      return match[1]
    elseif cline =~# '^\s*}'
      return 0
    endif
  elseif s:count('{', line) - s:count('}', line) < 0
    if s:count('{', cline) - s:count('}', cline) < 0
      return 0
    else
      return &sw
    endif
  endif

  return ind
endfunction

function! s:count(pattern, line) abort " {{{1
  let sum = 0
  let indx = match(a:line, a:pattern)
  while indx >= 0
    let sum += 1
    let indx += 1
    let indx = match(a:line, a:pattern, indx)
  endwhile
  return sum
endfunction

" }}}1

let &cpo = s:cpo_save
unlet s:cpo_save
