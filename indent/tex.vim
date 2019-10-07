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
setlocal indentkeys=!^F,o,O,(,),],},\&,=item,=else,=fi

" Add standard closing math delimiters to indentkeys
for s:delim in [
      \ 'rangle', 'rbrace', 'rvert', 'rVert', 'rfloor', 'rceil', 'urcorner']
  let &l:indentkeys .= ',=' . s:delim
endfor


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
  let l:ind = s:indent_amps.check(a:lnum, l:line, l:prev_lnum, l:prev_line)
  if s:indent_amps.finished | return l:ind | endif
  let l:prev_lnum = s:indent_amps.prev_lnum
  let l:prev_line = s:indent_amps.prev_line

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
let s:indent_amps.re_amp = g:vimtex#re#not_bslash . '\&'
let s:indent_amps.re_align = '^[ \t\\]*' . s:indent_amps.re_amp
function! s:indent_amps.check(lnum, cline, plnum, pline) abort dict " {{{1
  let self.finished = 0
  let self.amp_ind = -1
  let self.init_ind = -1
  let self.prev_lnum = a:plnum
  let self.prev_line = a:pline
  let self.prev_ind = a:plnum > 0 ? indent(a:plnum) : 0
  if !get(g:, 'vimtex_indent_on_ampersands', 1) | return self.prev_ind | endif

  if a:cline =~# self.re_align
        \ || a:cline =~# self.re_amp
        \ || a:cline =~# '^\v\s*\\%(end|])'
    call self.parse_context(a:lnum, a:cline)
  endif

  if a:cline =~# self.re_align
    let self.finished = 1
    let l:ind_diff =
          \   strdisplaywidth(strpart(a:cline, 0, match(a:cline, self.re_amp)))
          \ - strdisplaywidth(strpart(a:cline, 0, match(a:cline, '\S')))
    return self.amp_ind - l:ind_diff
  endif

  if self.amp_ind >= 0
        \ && (a:cline =~# '^\v\s*\\%(end|])' || a:cline =~# self.re_amp)
    let self.prev_lnum = self.init_lnum
    let self.prev_line = self.init_line
    return self.init_ind
  endif

  return self.prev_ind
endfunction

" }}}1
function! s:indent_amps.parse_context(lnum, line) abort dict " {{{1
  let l:depth = 1
  let l:init_depth = l:depth
  let l:lnum = prevnonblank(a:lnum - 1)

  while l:lnum >= 1
    let l:line = getline(l:lnum)

    if l:line =~# '\v^\s*%(}|\\%(end|]))'
      let l:depth += 1
    endif

    if l:line =~# '\v\\begin\s*\{|\\[|\\\w+\{\s*$'
      let l:depth -= 1
      if l:depth == l:init_depth - 1
        let self.init_lnum = l:lnum
        let self.init_line = l:line
        let self.init_ind = indent(l:lnum)
        break
      endif
    endif

    if l:depth == 1 && l:line =~# self.re_amp
      if self.amp_ind < 0
        let self.amp_ind = strdisplaywidth(
              \ strpart(l:line, 0, match(l:line, self.re_amp)))
      endif
      if l:line !~# self.re_align
        let self.init_lnum = l:lnum
        let self.init_line = l:line
        let self.init_ind = indent(l:lnum)
        break
      endif
    endif

    let l:lnum = prevnonblank(l:lnum - 1)
  endwhile
endfunction

" }}}1

function! s:indent_envs(cur, prev) abort " {{{1
  let l:ind = 0

  " First for general environments
  let l:ind += s:sw*(
        \    a:prev =~# s:envs_begin
        \ && a:prev !~# s:envs_end
        \ && a:prev !~# s:envs_ignored)
  let l:ind -= s:sw*(
        \    a:cur !~# s:envs_begin
        \ && a:cur =~# s:envs_end
        \ && a:cur !~# s:envs_ignored)

  " Indentation for prolonged items in lists
  let l:ind += s:sw*((a:prev =~# s:envs_item)    && (a:cur  !~# s:envs_enditem))
  let l:ind -= s:sw*((a:cur  =~# s:envs_item)    && (a:prev !~# s:envs_begitem))
  let l:ind -= s:sw*((a:cur  =~# s:envs_endlist) && (a:prev !~# s:envs_begitem))

  return l:ind
endfunction

let s:envs_begin = '\\begin{.*}\|\\\@<!\\\['
let s:envs_end = '\\end{.*}\|\\\]'
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
  if s:re_opt.close_indented
    return s:sw*(s:count(a:prev_line, s:re_open)
          \ - s:count(a:prev_line, s:re_close))
  else
    return s:sw*(  max([  s:count(a:prev_line, s:re_open)
          \             - s:count(a:prev_line, s:re_close), 0])
          \      - max([  s:count(a:line, s:re_close)
          \             - s:count(a:line, s:re_open), 0]))
  endif
endfunction

let s:re_opt = extend({
      \ 'open' : ['{'],
      \ 'close' : ['}'],
      \ 'close_indented' : 0,
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
          \ 'open': '\v(\\newif\s*)@<!\\if(f|field|name|numequal|thenelse)@!',
          \ 'else': '\\else\>',
          \ 'close': '\\fi\>',
          \}, l:cfg)
  endif

  if empty(s:re_cond) | return 0 | endif

  if get(s:, 'conditional_opened')
    if a:line =~# s:re_cond.close
      silent! unlet s:conditional_opened
      return a:prev_line =~# s:re_cond.open ? 0 : -s:sw
    elseif a:line =~# s:re_cond.else
      return -s:sw
    elseif a:prev_line =~# s:re_cond.else
      return s:sw
    elseif a:prev_line =~# s:re_cond.open
      return s:sw
    endif
  endif

  if a:line =~# s:re_cond.open
        \ && a:line !~# s:re_cond.close
    let s:conditional_opened = 1
  endif

  return 0
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
