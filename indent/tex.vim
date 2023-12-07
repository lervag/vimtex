" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:did_indent')
  finish
endif

call vimtex#options#init()

if !g:vimtex_indent_enabled | finish | endif

let b:did_vimtex_indent = 1
let b:did_indent = 1

let s:cpo_save = &cpoptions
set cpoptions&vim

setlocal autoindent
setlocal indentexpr=VimtexIndentExpr()
setlocal indentkeys=!^F,o,O,0(,0),],},\&,0=\\item\ ,0=\\item[,0=\\else,0=\\fi

" Add standard closing math delimiters to indentkeys
for s:delim in [
      \ 'rangle', 'rbrace', 'rvert', 'rVert', 'rfloor', 'rceil', 'urcorner']
  let &l:indentkeys .= ',0=\' . s:delim
endfor


function! VimtexIndentExpr() abort " {{{1
  " This wrapper function is used because of rnoweb[0] that "misuses" the
  " indentexpr and assumes it takes no arguments.
  "
  " [0]: /usr/share/nvim/runtime/indent/rnoweb.vim:21

  return VimtexIndent(v:lnum)
endfunction

"}}}
function! VimtexIndent(lnum) abort " {{{1
  let s:sw = shiftwidth()

  let [l:prev_lnum, l:prev_line] = s:get_prev_lnum(prevnonblank(a:lnum - 1))
  if l:prev_lnum == 0 | return indent(a:lnum) | endif
  let l:line = s:clean_line(getline(a:lnum))

  " Check for verbatim modes
  if s:in_verbatim(a:lnum)
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

  " Indent environments, delimiters, and conditionals
  let l:ind += s:indent_envs(l:line, l:prev_line)
  let l:ind += s:indent_items(l:line, a:lnum, l:prev_line, l:prev_lnum)
  let l:ind += s:indent_delims(l:line, a:lnum, l:prev_line, l:prev_lnum)
  let l:ind += s:indent_conditionals(l:line, a:lnum, l:prev_line, l:prev_lnum)

  " Indent tikz commands
  if g:vimtex_indent_tikz_commands
    let l:ind += s:indent_tikz(l:prev_lnum, l:prev_line)
  endif

  return l:ind < 0 ? 0 : l:ind
endfunction

"}}}

function! s:get_prev_lnum(lnum) abort " {{{1
  let l:lnum = a:lnum
  let l:line = getline(l:lnum)

  while l:lnum > 0 && (l:line =~# '^\s*%' || s:in_verbatim(l:lnum))
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
function! s:in_verbatim(lnum) abort " {{{1
  let l:synstack = vimtex#syntax#stack(a:lnum, col([a:lnum, '$']) - 2)

  return match(l:synstack, '\v^tex%(Lst|Verb|Markdown|Minted)Zone') >= 0
        \ && match(l:synstack, '\v^tex%(Minted)?Env') < 0
endfunction

" }}}1

let s:indent_amps = {}
function! s:indent_amps.check(lnum, cline, plnum, pline) abort dict " {{{1
  let self.finished = 0
  let self.amp_ind = -1
  let self.init_ind = -1
  let self.prev_lnum = a:plnum
  let self.prev_line = a:pline
  let self.prev_ind = a:plnum > 0 ? indent(a:plnum) : 0
  if !g:vimtex_indent_on_ampersands | return self.prev_ind | endif

  if a:cline =~# s:re_align
        \ || a:cline =~# s:re_amp
        \ || a:cline =~# '^\v\s*\\%(end|])'
    call self.parse_context(a:lnum, a:cline)
  endif

  if a:cline =~# s:re_align
    let self.finished = 1
    let l:ind_diff =
          \   strdisplaywidth(strpart(a:cline, 0, match(a:cline, s:re_amp)))
          \ - strdisplaywidth(strpart(a:cline, 0, match(a:cline, '\S')))
    return self.amp_ind - l:ind_diff
  endif

  if self.amp_ind >= 0
        \ && (a:cline =~# '^\v\s*\\%(end|])' || a:cline =~# s:re_amp)
    let self.prev_lnum = self.init_lnum
    let self.prev_line = self.init_line
    return self.init_ind
  endif

  return self.prev_ind
endfunction

let s:re_amp = g:vimtex#re#not_bslash . '\&'
let s:re_align = '^[ \t\\]*' . s:re_amp

" }}}1
function! s:indent_amps.parse_context(lnum, line) abort dict " {{{1
  let l:depth = 1
  let l:lnum = prevnonblank(a:lnum - 1)

  while l:lnum >= 1
    let l:line = getline(l:lnum)

    if l:line =~# s:re_depth_end
      let l:depth += 1
    endif

    if l:line =~# s:re_depth_beg
      let l:depth -= 1
      if l:depth == 0
        let self.init_lnum = l:lnum
        let self.init_line = l:line
        let self.init_ind = indent(l:lnum)
        break
      endif
    endif

    if l:depth == 1 && l:line =~# s:re_amp
      if self.amp_ind < 0
        let self.amp_ind = strdisplaywidth(
              \ strpart(l:line, 0, match(l:line, s:re_amp)))
      endif
      if l:line !~# s:re_align
        let self.init_lnum = l:lnum
        let self.init_line = l:line
        let self.init_ind = indent(l:lnum)
        break
      endif
    endif

    let l:lnum = prevnonblank(l:lnum - 1)
  endwhile
endfunction

let s:re_depth_beg = g:vimtex#re#not_bslash . '\\%(begin\s*\{|[|\w+\{\s*$)'
let s:re_depth_end = g:vimtex#re#not_bslash . '\\end\s*\{\w+\*?}|^\s*%(}|\\])'

" }}}1

function! s:indent_envs(line, prev_line) abort " {{{1
  let l:ind = 0

  let l:ind += s:sw*(
        \    a:prev_line =~# s:envs_begin
        \ && a:prev_line !~# s:envs_end
        \ && a:prev_line !~# s:envs_ignored)
  let l:ind -= s:sw*(
        \    a:line !~# s:envs_begin
        \ && a:line =~# s:envs_end
        \ && a:line !~# s:envs_ignored)

  return l:ind
endfunction

let s:envs_begin = '\\begin{.*}\|\\\@<!\\\['
let s:envs_end = '\\end{.*}\|\\\]'
let s:envs_ignored = '\v<%(' . join(g:vimtex_indent_ignored_envs, '|') . ')>'

" }}}1
function! s:indent_items(line, lnum, prev_line, prev_lnum) abort " {{{1
  if s:envs_lists_empty | return 0 | endif

  if a:prev_line =~# s:envs_item
        \ && (a:line !~# s:envs_enditem
        \     || (a:line =~# s:envs_item && a:prev_line =~# s:envs_beglist))
    return s:sw
  elseif a:line =~# s:envs_endlist && a:prev_line !~# s:envs_begitem
    return -s:sw
  elseif a:line =~# s:envs_item && a:prev_line !~# s:envs_item
    let l:prev_lnum = a:prev_lnum
    let l:prev_line = a:prev_line
    while l:prev_lnum >= 1
      if l:prev_line =~# s:envs_begitem
        return -s:sw*(l:prev_line =~# s:envs_item)
      endif
      let l:prev_lnum = prevnonblank(l:prev_lnum - 1)
      let l:prev_line = getline(l:prev_lnum)
    endwhile
  endif

  return 0
endfunction

let s:envs_lists_empty = empty(g:vimtex_indent_lists)
let s:envs_lists = join(g:vimtex_indent_lists, '\|')
let s:envs_item = '^\s*\\item\>'
let s:envs_beglist = '\\begin{\%(' . s:envs_lists . '\)'
let s:envs_endlist =   '\\end{\%(' . s:envs_lists . '\)'
let s:envs_begitem = s:envs_item . '\|' . s:envs_beglist
let s:envs_enditem = s:envs_item . '\|' . s:envs_endlist

" }}}1
function! s:indent_delims(line, lnum, prev_line, prev_lnum) abort " {{{1
  if s:re_delim_trivial | return 0 | endif

  if s:re_opt.close_indented
    return s:sw*(vimtex#util#count(a:prev_line, s:re_open)
          \ - vimtex#util#count(a:prev_line, s:re_close))
  else
    return s:sw*(vimtex#util#count_open(a:prev_line, s:re_open, s:re_close)
          \      - vimtex#util#count_close(a:line, s:re_open, s:re_close))
  endif
endfunction

let s:re_opt = extend({
      \ 'open' : ['{'],
      \ 'close' : ['}'],
      \ 'close_indented' : 0,
      \ 'include_modified_math' : 1,
      \}, g:vimtex_indent_delims)
let s:re_open = join(s:re_opt.open, '\|')
let s:re_close = join(s:re_opt.close, '\|')
if s:re_opt.include_modified_math
  let s:re_open .= (empty(s:re_open) ? '' : '\|') . g:vimtex#delim#re.delim_mod_math.open
  let s:re_close .= (empty(s:re_close) ? '' : '\|') . g:vimtex#delim#re.delim_mod_math.close
endif
let s:re_delim_trivial = empty(s:re_open) || empty(s:re_close)

" }}}1
function! s:indent_conditionals(line, lnum, prev_line, prev_lnum) abort " {{{1
  if empty(s:conditionals) | return 0 | endif

  let l:ind = s:sw*(
        \    (a:prev_line =~# s:conditionals.open
        \     || a:prev_line =~# s:conditionals.else)
        \ && a:prev_line !~# s:conditionals.close)
  let l:ind -= s:sw*(
        \    a:line !~# s:conditionals.open
        \ && (a:line =~# s:conditionals.close
        \     || a:line =~# s:conditionals.else))

  return l:ind
endfunction

let s:conditionals = g:vimtex_indent_conditionals

" }}}1
function! s:indent_tikz(lnum, prev) abort " {{{1
  if !has_key(b:vimtex.packages, 'tikz') | return 0 | endif

  let l:synstack = vimtex#syntax#stack(a:lnum, 1)
  if match(l:synstack, '^texTikzZone') < 0 | return 0 | endif

  let l:env_lnum = search('\\begin\s*{tikzpicture\*\?}', 'bn')
  if l:env_lnum > 0 && l:env_lnum < a:lnum
    let l:prev_starts = a:prev =~# s:tikz_commands
    let l:prev_stops  = a:prev =~# ';\s*$'

    " Increase indent on tikz command start
    if l:prev_starts && ! l:prev_stops
      return s:sw
    endif

    " Decrease indent on tikz command end, i.e. on semicolon
    if ! l:prev_starts && l:prev_stops
      let l:context = join(getline(l:env_lnum, a:lnum-1), '')
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
        \ 'clip',
        \ 'add%(legendentry|plot)',
      \ ], '|') . ')'

" }}}1

let &cpoptions = s:cpo_save
unlet s:cpo_save
