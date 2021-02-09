" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#bibliography#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'prefilter_cmds' : ['printbib', 'begin', 'bibliography'],
      \ 'priority' : 0,
      \ 're' : '\v^\s*\\%('
      \        .  'printbib%(liography|heading)\s*(\{|\[)?'
      \        . '|begin\s*\{\s*thebibliography\s*\}'
      \        . '|bibliography\s*\{)',
      \ 're_biblatex' : '\v^\s*\\printbib%(liography|heading)',
      \}
function! s:matcher.get_entry(context) abort dict " {{{1
  let l:entry = {
        \ 'title'  : 'Bibliography',
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'rank'   : a:context.lnum_total,
        \ 'level'  : 0,
        \ 'type'   : 'content',
        \}

  if a:context.line !~# self.re_biblatex
    return l:entry
  endif

  let self.options = matchstr(a:context.line, self.re_biblatex . '\s*\[\zs.*')

  let [l:end, l:count] = vimtex#parser#tex#find_closing(
        \ 0, self.options, !empty(self.options), '[')
  if l:count == 0
    let self.options = strpart(self.options, 0, l:end)
    call self.parse_options(a:context, l:entry)
  else
    let self.count = l:count
    let a:context.continue = 'bibliography'
  endif

  return l:entry
endfunction

" }}}1
function! s:matcher.continue(context) abort dict " {{{1
  let [l:end, l:count] = vimtex#parser#tex#find_closing(
        \ 0, a:context.line, self.count, '[')
  if l:count == 0
    let self.options .= strpart(a:context.line, 0, l:end)
    unlet! a:context.continue
    call self.parse_options(a:context, a:context.entry)
  else
    let self.options .= a:context.line
    let self.count = l:count
  endif
endfunction

" }}}1
function! s:matcher.parse_options(context, entry) abort dict " {{{1
  " Parse the options
  let l:opt_pairs = map(split(self.options, ','), 'split(v:val, ''='')')
  let l:opts = {}
  for [l:key, l:val] in l:opt_pairs
    let l:key = substitute(l:key, '^\s*\|\s*$', '', 'g')
    let l:val = substitute(l:val, '^\s*\|\s*$', '', 'g')
    let l:val = substitute(l:val, '{\|}', '', 'g')
    let l:opts[l:key] = l:val
  endfor

  " Check if entry should appear in the TOC
  let l:heading = get(l:opts, 'heading')
  let a:entry.added_to_toc = l:heading =~# 'intoc\|numbered'

  " Check if entry should be numbered
  if l:heading =~# '\v%(sub)?bibnumbered'
    if a:context.level.chapter > 0
      let l:levels = ['chapter', 'section']
    else
      let l:levels = ['section', 'subsection']
    endif
    call a:context.level.increment(l:levels[l:heading =~# '^sub'])
    let a:entry.level = a:context.max_level - a:context.level.current
    let a:entry.number = deepcopy(a:context.level)
  endif

  " Parse title
  try
    let a:entry.title = remove(l:opts, 'title')
  catch /E716/
    let a:entry.title = l:heading =~# '^sub' ? 'References' : 'Bibliography'
  endtry
endfunction

" }}}1
function! s:matcher.filter(entries) abort dict " {{{1
  if !empty(
        \ filter(deepcopy(a:entries), 'get(v:val, "added_to_toc")'))
    call filter(a:entries, 'get(v:val, "added_to_toc", 1)')
  endif
endfunction

" }}}1
