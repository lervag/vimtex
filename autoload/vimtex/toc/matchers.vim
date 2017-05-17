" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#toc#matchers#general(context) abort dict " {{{1
  return {
        \ 'title'  : self.title,
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.max_level,
        \}
endfunction

" }}}1

let vimtex#toc#matchers#included = {}
function! vimtex#toc#matchers#included.init(file) " {{{1
  let l:inc = deepcopy(self)
  let l:inc.prev = a:file
  let l:inc.files = [a:file]
  let l:inc.current = { 'entries' : 0 }

  unlet l:inc.init
  return l:inc
endfunction

" }}}1
function! vimtex#toc#matchers#included.get_entry(context) " {{{1
  let self.prev = a:context.file
  let self.current.entries = a:context.num_entries - get(self, 'toc_length')
  let self.toc_length = a:context.num_entries

  if index(self.files, a:context.file) < 0
    let self.files += [a:context.file]
    let self.current = {
          \ 'title'   : fnamemodify(a:context.file, ':t'),
          \ 'number'  : '[i]',
          \ 'file'    : a:context.file,
          \ 'line'    : 1,
          \ 'level'   : a:context.level.current,
          \ 'entries' : 0,
          \ }
    return self.current
  else
    let self.current = { 'entries' : 0 }
    return {}
  endif
endfunction

" }}}1

let g:vimtex#toc#matchers#vimtex_include = {
      \ 're' : '%\s*vimtex-include:\?\s\+\zs\f\+',
      \ 'in_preamble' : 1,
      \}
function! g:vimtex#toc#matchers#vimtex_include.get_entry(context) abort dict " {{{1
  let l:file = matchstr(a:context.line, self.re)
  if l:file[0] !=# '/'
    let l:file = b:vimtex.root . '/' . l:file
  endif
  let l:file = fnamemodify(l:file, ':~:.')
  return {
        \ 'title'  : (strlen(l:file) < 70
        \               ? l:file
        \               : l:file[0:30] . '...' . l:file[-36:]),
        \ 'number' : '[v]',
        \ 'file'   : l:file,
        \ 'level'  : a:context.level.current,
        \ 'link'   : 1,
        \ }
endfunction

" }}}1

let g:vimtex#toc#matchers#preamble_start = {
      \ 're' : '\v^\s*\\documentclass',
      \ 'in_preamble' : 1,
      \ 'in_content' : 0,
      \}
function! g:vimtex#toc#matchers#preamble_start.get_entry(context) " {{{1
  return g:vimtex_toc_show_preamble
        \ ? {
        \   'title'  : 'Preamble',
        \   'number' : '',
        \   'file'   : a:context.file,
        \   'line'   : a:context.lnum,
        \   'level'  : a:context.max_level,
        \   }
        \ : {}
endfunction

" }}}1

let g:vimtex#toc#matchers#preamble_end = {
      \ 're' : '\v^\s*\\begin\{document\}',
      \ 'in_preamble' : 1,
      \ 'in_content' : 0,
      \}
function! g:vimtex#toc#matchers#preamble_end.action(context) abort dict " {{{1
  let a:context.level.preamble = 0
endfunction

" }}}1

let g:vimtex#toc#matchers#bib = {
      \ 're' : g:vimtex#re#not_comment
      \        . '\\(bibliography|add(bibresource|globalbib|sectionbib))'
      \        . '\m\s*{\zs[^}]\+\ze}',
      \ 'in_preamble' : 1,
      \}
function! g:vimtex#toc#matchers#bib.get_entry(context) abort dict " {{{1
  let l:file = matchstr(a:context.line, self.re)

  " Ensure that the file name has extension
  if l:file !~# '\.bib$'
    let l:file .= '.bib'
  endif

  return {
        \ 'title'  : printf('%-.78s', fnamemodify(l:file, ':t')),
        \ 'number' : '[b]',
        \ 'file'   : vimtex#kpsewhich#find(l:file),
        \ 'line'   : 0,
        \ 'level'  : a:context.max_level,
        \ }
endfunction

" }}}1

let g:vimtex#toc#matchers#struct = {
      \ 're' : '\v^\s*\\\zs((front|main|back)matter|appendix)>',
      \}
function! g:vimtex#toc#matchers#struct.action(context) abort dict " {{{1
  call a:context.level.reset(matchstr(a:context.line, self.re), a:context.max_level)
endfunction

" }}}1

let g:vimtex#toc#matchers#sec = {
      \ 're' : '\v^\s*\\%(part|chapter|%(sub)*section)\*?\s*(\[|\{)',
      \ 're_starred' : '\v^\s*\\%(part|chapter|%(sub)*section)\*',
      \ 're_level' : '\v^\s*\\\zs%(part|chapter|%(sub)*section)',
      \}
let g:vimtex#toc#matchers#sec.re_title = g:vimtex#toc#matchers#sec.re . '\zs.{-}\ze\%?\s*$'
function! g:vimtex#toc#matchers#sec.get_entry(context) abort dict " {{{1
  let level = matchstr(a:context.line, self.re_level)
  let type = matchlist(a:context.line, self.re)[1]
  let title = matchstr(a:context.line, self.re_title)

  let [l:end, l:count] = s:find_closing(0, title, 1, type)
  if l:count == 0
    let title = self.parse_title(strpart(title, 0, l:end+1))
  else
    let self.type = type
    let self.count = l:count
    let s:matcher_continue = deepcopy(self)
  endif

  call a:context.level.increment(level)

  return {
        \ 'title'  : title,
        \ 'number' : a:context.line =~# self.re_starred ? '' : deepcopy(a:context.level),
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : a:context.level.current,
        \ }
endfunction

" }}}1
function! g:vimtex#toc#matchers#sec.parse_title(title) abort dict " {{{1
  let l:title = substitute(a:title, '\v%(\]|\})\s*$', '', '')
  return s:clear_texorpdfstring(l:title)
endfunction

" }}}1
function! g:vimtex#toc#matchers#sec.continue(context) abort dict " {{{1
  let [l:end, l:count] = s:find_closing(0, a:context.line, self.count, self.type)
  if l:count == 0
    let a:context.entry.title = self.parse_title(a:context.entry.title . strpart(a:context.line, 0, l:end+1))
    unlet! s:matcher_continue
  else
    let a:context.entry.title .= a:context.line
    let self.count = l:count
  endif
endfunction

" }}}1

"
" Utility functions
"
function! s:clear_texorpdfstring(title) abort " {{{1
  let l:i1 = match(a:title, '\\texorpdfstring')
  if l:i1 < 0 | return a:title | endif

  " Find start of included part
  let [l:i2, l:dummy] = s:find_closing(
        \ match(a:title, '{', l:i1+1), a:title, 1, '{')
  let l:i2 = match(a:title, '{', l:i2+1)
  if l:i2 < 0 | return a:title | endif

  " Find end of included part
  let [l:i3, l:dummy] = s:find_closing(l:i2, a:title, 1, '{')
  if l:i3 < 0 | return a:title | endif

  return strpart(a:title, 0, l:i1)
        \ . strpart(a:title, l:i2+1, l:i3-l:i2-1)
        \ . s:clear_texorpdfstring(strpart(a:title, l:i3+1))
endfunction

" }}}1
function! s:find_closing(start, string, count, type) abort " {{{1
  if a:type ==# '{'
    let l:re = '{\|}'
    let l:open = '{'
  else
    let l:re = '\[\|\]'
    let l:open = '['
  endif
  let l:i2 = a:start
  let l:count = a:count
  while l:count > 0
    let l:i2 = match(a:string, l:re, l:i2+1)
    if l:i2 < 0 | break | endif

    if a:string[l:i2] ==# l:open
      let l:count += 1
    else
      let l:count -= 1
    endif
  endwhile

  return [l:i2, l:count]
endfunction

" }}}1

" vim: fdm=marker sw=2
