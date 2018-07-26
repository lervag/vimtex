" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:did_indent')
  finish
endif

if !get(g:, 'vimtex_indent_enabled', 1) | finish | endif

let b:did_vimtex_indent = 1
let b:did_indent = 1

let s:cpo_save = &cpoptions
set cpoptions&vim

setlocal autoindent
setlocal indentexpr=VimtexIndentExpr()
setlocal indentkeys&
setlocal indentkeys+=[,(,{,),},],\&,=item,=else,=fi

function! VimtexIndentExpr() abort " {{{1
  return VimtexIndent(v:lnum)
endfunction

"}}}
function! VimtexIndent(lnum) abort " {{{1
  let s:sw = exists('*shiftwidth') ? shiftwidth() : &shiftwidth

  let l:prev_lnum = s:get_prev_line(prevnonblank(a:lnum - 1), 0)
  if l:prev_lnum == 0 | return indent(a:lnum) | endif

  " Get current and previous line and remove comments
  let l:line = substitute(getline(a:lnum), '\\\@<!%.*', '', '')
  let l:prev_line = substitute(getline(l:prev_lnum),   '\\\@<!%.*', '', '')

  " Check for verbatim modes
  if s:is_verbatim(l:line, a:lnum)
    return empty(l:line) ? indent(l:prev_lnum) : indent(a:lnum)
  endif

  " Align on ampersands
  if s:indent_amps.check(a:lnum, l:line, l:prev_line)
    return s:indent_amps.indent
  endif

  " Use previous indentation for comments
  if l:line =~# '^\s*%'
    return indent(a:lnum)
  endif

  " Ensure previous line does not start with ampersand
  let l:prev_lnum = s:get_prev_line(l:prev_lnum,
        \ get(g:, 'vimtex_indent_on_ampersands', 1))
  if l:prev_lnum == 0 | return 0 | endif
  let l:prev_line = substitute(getline(l:prev_lnum), '\\\@<!%.*', '', '')

  " Indent environments, delimiters, and tikz
  let l:ind = indent(l:prev_lnum)
  let l:ind += s:indent_envs(l:line, l:prev_line)
  let l:ind += s:indent_delims(l:line, a:lnum, l:prev_line, l:prev_lnum)
  let l:ind += s:indent_conditionals(l:line, a:lnum, l:prev_line, l:prev_lnum)
  let l:ind += s:indent_tikz(l:prev_lnum, l:prev_line)
  return l:ind
endfunction

"}}}

function! s:get_prev_line(lnum, skip_amps) abort " {{{1
  let l:lnum = a:lnum
  let l:prev = getline(l:lnum)

  while l:lnum != 0
        \ && (l:prev =~# '^\s*%'
        \     || s:is_verbatim(l:prev, l:lnum)
        \     || (a:skip_amps && l:prev =~# s:indent_amps.re_align))
    let l:lnum = prevnonblank(l:lnum - 1)
    let l:prev = getline(l:lnum)
  endwhile

  return l:lnum
endfunction

" }}}1
function! s:is_verbatim(line, lnum) abort " {{{1
  return a:line !~# '\v\\%(begin|end)\{%(verbatim|lstlisting|minted)'
        \ && vimtex#env#is_inside('\%(lstlisting\|verbatim\|minted\)')[0]
endfunction

" }}}1

let s:indent_amps = {}
let s:indent_amps.indent = 0
let s:indent_amps.re_amp = g:vimtex#re#not_bslash . '\&'
let s:indent_amps.re_align = '^[ \t\\]*' . s:indent_amps.re_amp
function! s:indent_amps.check(lnum, cline, pline) abort dict " {{{1
  if get(g:, 'vimtex_indent_on_ampersands', 1)
        \ && a:cline =~# self.re_align
        \ && a:pline =~# self.re_amp

    let l:pre = strdisplaywidth(strpart(a:pline, 0, match(a:pline, self.re_amp)))
    let l:cur = strdisplaywidth(strpart(a:cline, 0, match(a:cline, self.re_amp)))
    let self.indent = max([indent(a:lnum) - l:cur + l:pre, 0])

    return 1
  endif

  let self.indent = 0
  return 0
endfunction

" }}}1

function! s:indent_envs(cur, prev) abort " {{{1
  let l:ind = 0

  " First for general environments
  let l:ind += s:sw*(
        \    a:prev =~# '\\begin{.*}'
        \ && a:prev !~# '\\end{.*}'
        \ && a:prev !~# s:envs_ignored)
  let l:ind -= s:sw*(
        \    a:cur !~# '\\begin{.*}'
        \ && a:cur =~# '\\end{.*}'
        \ && a:cur !~# s:envs_ignored)

  " Indentation for prolonged items in lists
  let l:ind += s:sw*((a:prev =~# s:envs_item)    && (a:cur  !~# s:envs_enditem))
  let l:ind -= s:sw*((a:cur  =~# s:envs_item)    && (a:prev !~# s:envs_begitem))
  let l:ind -= s:sw*((a:cur  =~# s:envs_endlist) && (a:prev !~# s:envs_begitem))

  return l:ind
endfunction

let s:envs_ignored = '\v'
      \ . join(get(g:, 'vimtex_indent_ignored_envs', ['document']), '|')
let s:envs_lists = join(get(g:, 'vimtex_indent_lists', [
      \ 'itemize',
      \ 'description',
      \ 'enumerate',
      \ 'thebibliography',
      \]), '\|')
let s:envs_item = '^\s*\\item'
let s:envs_beglist = '\\begin{\%(' . s:envs_lists . '\)'
let s:envs_endlist =   '\\end{\%(' . s:envs_lists . '\)'
let s:envs_begitem = s:envs_item . '\|' . s:envs_beglist
let s:envs_enditem = s:envs_item . '\|' . s:envs_endlist

" }}}1
function! s:indent_delims(line, lnum, prev_line, prev_lnum) abort " {{{1
  return s:sw*(  max([  s:count(a:prev_line, s:re_open)
        \             - s:count(a:prev_line, s:re_close), 0])
        \      - max([  s:count(a:line, s:re_close)
        \             - s:count(a:line, s:re_open), 0]))
endfunction

let s:re_opt = extend({
      \ 'open' : ['{', '\\\@<!\\\['],
      \ 'close' : ['}', '\\\]'],
      \ 'include_modified_math' : 1,
      \}, get(g:, 'vimtex_indent_delims', {}))
let s:re_open = join(s:re_opt.open, '\|')
let s:re_close = join(s:re_opt.close, '\|')
if s:re_opt.include_modified_math
  let s:re_open .= empty(s:re_open ? '' : '\|') . g:vimtex#delim#re.delim_mod_math.open
  let s:re_close .= empty(s:re_close ? '' : '\|') . g:vimtex#delim#re.delim_mod_math.close
endif

" }}}1
function! s:indent_conditionals(line, lnum, prev_line, prev_lnum) abort " {{{1
  if !exists('s:re_cond')
    let l:cfg = {}

    if exists('g:vimtex_indent_conditionals')
      let l:cfg = g:vimtex_indent_conditionals
      if empty(l:cfg)
        let s:re_cond = {}
        return 0
      endif
    endif

    let s:re_cond = extend({
          \ 'open': '\v(\\newif)@<!\\if(field|name|numequal|thenelse)@!',
          \ 'else': '\\else\>',
          \ 'close': '\\fi\>',
          \}, l:cfg)
  endif

  if empty(s:re_cond) | return 0 | endif

  " Match for conditional indents
  if a:line =~# s:re_cond.close
    silent! unlet s:conditional_opened
    return -s:sw
  elseif get(s:, 'conditional_opened')
        \ && a:line =~# s:re_cond.else
    return -s:sw
  elseif get(s:, 'conditional_opened')
        \ && a:prev_line =~# s:re_cond.else
    return s:sw
  elseif a:prev_line =~# s:re_cond.open
    let s:conditional_opened = 1
    return s:sw
  endif
endfunction

" }}}1
function! s:indent_tikz(lnum, prev) abort " {{{1
  if !has_key(b:vimtex.packages, 'tikz') | return 0 | endif

  let l:env_pos = vimtex#env#is_inside('tikzpicture')
  if l:env_pos[0] > 0 && l:env_pos[0] < a:lnum
    let l:prev_starts = a:prev =~# s:tikz_commands
    let l:prev_stops  = a:prev =~# ';\s*$'

    " Increase indent on tikz command start
    if l:prev_starts && ! l:prev_stops
      return s:sw
    endif

    " Decrease indent on tikz command end, i.e. on semicolon
    if ! l:prev_starts && l:prev_stops
      let l:context = join(getline(l:env_pos[0], a:lnum-1), '')
      return -s:sw*(l:context =~# s:tikz_commands)
    endif
  endif

  return 0
endfunction

let s:tikz_commands = '\v\\%(' . join([
        \ 'draw',
        \ 'fill',
        \ 'path',
        \ 'node',
        \ 'coordinate',
        \ 'add%(legendentry|plot)',
      \ ], '|') . ')'

" }}}1

function! s:count(line, pattern) abort " {{{1
  if empty(a:pattern) | return 0 | endif

  let l:sum = 0
  let l:indx = match(a:line, a:pattern)
  while l:indx >= 0
    let l:sum += 1
    let l:match = matchstr(a:line, a:pattern, l:indx)
    let l:indx += len(l:match)
    let l:indx = match(a:line, a:pattern, l:indx)
  endwhile
  return l:sum
endfunction

" }}}1

let &cpoptions = s:cpo_save
unlet s:cpo_save
