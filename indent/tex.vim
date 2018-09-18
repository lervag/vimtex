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

  let [l:prev_lnum, l:prev_line] = s:get_prev_lnum(prevnonblank(a:lnum - 1))
  if l:prev_lnum == 0 | return indent(a:lnum) | endif
  let l:line = s:clean_line(getline(a:lnum))

  " Check for verbatim modes
  if s:is_verbatim(l:line, a:lnum)
    return empty(l:line) ? indent(l:prev_lnum) : indent(a:lnum)
  endif

  " Use previous indentation for comments
  if l:line =~# '^\s*%'
    return indent(a:lnum)
  endif

  " Align on ampersands
  let [l:ind, l:do_indent, l:prev_lnum, l:prev_line]
        \ = s:indent_amps.check(a:lnum, l:line, l:prev_lnum, l:prev_line)
  if l:do_indent
    return l:ind
  endif
  " unsilent echo printf('%2s %2s %2s', l:ind, l:prev_lnum, a:lnum) l:line "\n"

  " Indent environments, delimiters, and tikz
  let l:ind += s:indent_envs(l:line, l:prev_line)
  let l:ind += s:indent_delims(l:line, a:lnum, l:prev_line, l:prev_lnum)
  let l:ind += s:indent_conditionals(l:line, a:lnum, l:prev_line, l:prev_lnum)
  let l:ind += s:indent_tikz(l:prev_lnum, l:prev_line)

  return l:ind
endfunction

"}}}

function! s:get_prev_lnum(lnum) abort " {{{1
  let l:lnum = a:lnum
  let l:line = getline(l:lnum)

  while l:lnum != 0 && (l:line =~# '^\s*%' || s:is_verbatim(l:line, l:lnum))
    let l:lnum = prevnonblank(l:lnum - 1)
    let l:line = getline(l:lnum)
  endwhile

  return [
        \ l:lnum,
        \ l:lnum > 0 ? s:clean_line(l:line) : '',
        \]
endfunction

" }}}1
function! s:clean_line(line) abort " {{{1
  return substitute(a:line, '\s*\\\@<!%.*', '', '')
endfunction

" }}}1
function! s:is_verbatim(line, lnum) abort " {{{1
  return a:line !~# '\v\\%(begin|end)\{%(verbatim|lstlisting|minted)'
        \ && vimtex#env#is_inside('\%(lstlisting\|verbatim\|minted\)')[0]
endfunction

" }}}1

let s:indent_amps = {}
let s:indent_amps.indent = 0
let s:indent_amps.env = 0
let s:indent_amps.continued = 0
let s:indent_amps.prev_lnum = 0
let s:indent_amps.prev_line = ''
let s:indent_amps.re_amp = g:vimtex#re#not_bslash . '\&'
let s:indent_amps.re_align = '^[ \t\\]*' . s:indent_amps.re_amp
function! s:indent_amps.check(lnum, cline, plnum, pline) abort dict " {{{1
  if !get(g:, 'vimtex_indent_on_ampersands', 1)
    return [a:plnum > 0 ? indent(a:plnum) : 0, 0, a:plnum, a:pline]
  endif

  if !self.env
    if a:pline =~# self.re_amp && a:cline =~# self.re_amp
      let self.env = vimtex#env#is_inside('\w\+')[0]
      let self.indent = strdisplaywidth(
            \ strpart(a:pline, 0, match(a:pline, self.re_amp)))
      let [self.prev_lnum, self.prev_line] = self.get_prev_nonamp(a:plnum)
    endif
  endif

  " Check if the ampersand environment is closed
  if self.env
    let l:env = vimtex#env#is_inside('\w\+')[0]
    if l:env != self.env || a:cline =~# '^\s*\\end'
      let self.env = ''
      let self.indent = 0
      let l:plnum = self.prev_lnum
      let l:pline = self.prev_line
      let self.prev_lnum = 0
      let self.prev_line = ''
      return [l:plnum > 0 ? indent(l:plnum) : 0, 0, l:plnum, l:pline]
    endif
  endif

  " Check if we should indent directly
  if self.env && a:cline =~# self.re_align
    let l:ind_diff =
          \   strdisplaywidth(strpart(a:cline, 0, match(a:cline, self.re_amp)))
          \ - strdisplaywidth(strpart(a:cline, 0, match(a:cline, '\S')))
    return [self.indent - l:ind_diff, 1, a:plnum, a:pline]
  endif

  " Get indent (either continued or from previous nonamped line
  if self.get_continued_indent(a:cline)
    let l:ind = self.indent + s:sw
    let l:plnum = a:plnum
    let l:pline = a:pline
  else
    let [l:plnum, l:pline] = self.get_prev_nonamp(a:plnum)
    let l:ind = l:plnum > 0 ? indent(l:plnum) : 0
  endif

  return [l:ind, 0, l:plnum, l:pline]
endfunction

" }}}1
function! s:indent_amps.get_continued_indent(line) abort dict " {{{1
  if self.env && !self.continued && a:line !~# self.re_amp
    let self.continued = 1
    return 1
  else
    let self.continued = 0
  endif
endfunction

" }}}1
function! s:indent_amps.get_prev_nonamp(lnum) abort dict " {{{1
  let [l:lnum, l:line] = s:get_prev_lnum(a:lnum)

  while l:lnum > 1
    if l:line !~# s:indent_amps.re_align
      break
    endif
    let [l:lnum, l:line] = s:get_prev_lnum(l:lnum-1)
  endwhile

  return [l:lnum, l:line]
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
  let s:re_open .= (empty(s:re_open) ? '' : '\|') . g:vimtex#delim#re.delim_mod_math.open
  let s:re_close .= (empty(s:re_close) ? '' : '\|') . g:vimtex#delim#re.delim_mod_math.close
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
