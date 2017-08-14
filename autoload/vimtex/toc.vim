" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#toc#init_buffer() abort " {{{1
  if !g:vimtex_toc_enabled | return | endif

  command! -buffer VimtexTocOpen   call b:vimtex.toc.open()
  command! -buffer VimtexTocToggle call b:vimtex.toc.toggle()

  nnoremap <buffer> <plug>(vimtex-toc-open)   :call b:vimtex.toc.open()<cr>
  nnoremap <buffer> <plug>(vimtex-toc-toggle) :call b:vimtex.toc.toggle()<cr>
endfunction

" }}}1
function! vimtex#toc#init_state(state) abort " {{{1
  if !g:vimtex_toc_enabled | return | endif

  let a:state.toc = vimtex#index#new(s:toc.new())
endfunction

" }}}1

function! vimtex#toc#get_entries() abort " {{{1
  if !has_key(b:vimtex, 'toc') | return [] | endif

  return b:vimtex.toc.update(0)
endfunction

" }}}1
function! vimtex#toc#refresh() abort " {{{1
  if has_key(b:vimtex, 'toc')
    call b:vimtex.toc.update(1)
  endif
endfunction

" }}}1

let s:toc = {
      \ 'name' : 'Table of contents (vimtex)',
      \ 'help' : [
      \   '-:       decrease g:vimtex_toc_tocdepth',
      \   '+:       increase g:vimtex_toc_tocdepth',
      \   's:       hide numbering',
      \   't:       toggle sorted TODOs',
      \   'u:       update',
      \ ],
      \ 'show_numbers' : g:vimtex_toc_show_numbers,
      \ 'tocdepth' : g:vimtex_toc_tocdepth,
      \ 'todo_sorted' : 1,
      \}

function! s:toc.new() abort dict " {{{1
  let l:toc = deepcopy(self)

  let l:toc.matchers = [
        \ g:vimtex#toc#matchers#preamble,
        \ g:vimtex#toc#matchers#vimtex_include,
        \ g:vimtex#toc#matchers#bibinputs,
        \ g:vimtex#toc#matchers#parts,
        \ g:vimtex#toc#matchers#sections,
        \ g:vimtex#toc#matchers#table_of_contents,
        \ g:vimtex#toc#matchers#index,
        \ g:vimtex#toc#matchers#titlepage,
        \ g:vimtex#toc#matchers#bibliography,
        \ g:vimtex#toc#matchers#todos,
        \]
  let l:toc.matchers += g:vimtex_toc_custom_matchers

  let l:toc.hotkeys = extend({
        \ 'enabled' : '0',
        \ 'leader' : ';',
        \ 'keys' : 'abcdefghijklmnopqrstuvxyz',
        \}, g:vimtex_toc_hotkeys)

  unlet l:toc.new
  return l:toc
endfunction

" }}}1
function! s:toc.update(force) abort dict " {{{1
  if has_key(self, 'entries') && !g:vimtex_toc_refresh_always && !a:force
    return self.entries
  endif

  let l:content = vimtex#parser#tex(b:vimtex.tex)

  let self.entries = []
  let self.max_level = 0
  let self.topmatters = 0

  "
  " First iteration: Prepare total values
  "
  call self.parse_prepare(l:content)

  "
  " Main iteration: Generate entries
  "
  call self.parse(l:content)

  "
  " Sort todo entries
  "
  if self.todo_sorted
    let l:todos = filter(copy(self.entries), 'get(v:val, ''todo'')')
    call filter(self.entries, '!get(v:val, ''todo'')')
    let self.entries = l:todos + self.entries
  endif

  "
  " Add hotkeys to entries
  "
  let k = strwidth(self.hotkeys.keys)
  let n = len(self.entries)
  let m = len(s:base(n, k))
  let i = 0
  for entry in self.entries
    let keys = map(s:base(i, k), 'strcharpart(self.hotkeys.keys, v:val, 1)')
    let keys = repeat([self.hotkeys.keys[0]], m - len(keys)) + keys
    let i+=1
    let entry.num = i
    let entry.hotkey = join(keys, '')
  endfor

  "
  " Refresh if wanted
  "
  if a:force && self.is_open()
    call self.refresh()
  endif

  return self.entries
endfunction

" }}}1

function! s:toc.parse_prepare(content) " {{{1
  for [l:file, l:lnum, l:line] in a:content
    if l:line =~# g:vimtex#toc#matchers#sections.re
      let self.max_level = max([
            \ self.max_level,
            \ s:sec_to_value[matchstr(l:line, g:vimtex#toc#matchers#sections.re_level)]
            \])
    elseif l:line =~# '\v^\s*\\%(front|main|back)matter>'
      let self.topmatters += 1
    endif
  endfor
endfunction

" }}}1
function! s:toc.parse(content) abort dict " {{{1
  "
  " Parses tex project for TOC entries.  Each entry is a dictionary similar to
  " the following:
  "
  "   entry = {
  "     title  : "Some title",
  "     number : "3.1.2",
  "     file   : /path/to/file.tex,
  "     line   : 142,
  "     level  : 2,
  "   }
  "

  call s:level.reset('preamble', self.max_level)

  " Prepare included file matcher
  let l:included = g:vimtex#toc#matchers#included.init(a:content[0][0])

  " Parse project content for TOC entries
  let l:lnum_total = 0
  for [l:file, l:lnum, l:line] in a:content
    let l:lnum_total += 1
    let l:context = {
          \ 'file' : l:file,
          \ 'line' : l:line,
          \ 'lnum' : l:lnum,
          \ 'lnum_total' : l:lnum_total,
          \ 'level' : s:level,
          \ 'max_level' : self.max_level,
          \ 'entry' : get(self.entries, -1, {}),
          \ 'num_entries' : len(self.entries),
          \}

    " Detect end of preamble
    if s:level.preamble && l:line =~# '\v^\s*\\begin\{document\}'
      let s:level.preamble = 0
      continue
    endif

    " Handle multi-line entries
    if exists('s:matcher_continue')
      call s:matcher_continue.continue(l:context)
      continue
    endif

    " Add TOC entry for each included file
    "
    " Note: This is handled differently from other matchers. Every new file
    "       will get an entry, and all such entries that are provided by other
    "       means will be filtered out at the end.
    if l:file !=# l:included.prev
      let l:entry = l:included.get_entry(l:context)
      if !empty(l:entry)
        call add(self.entries, l:entry)
      endif
    endif

    " Apply the registered TOC matchers
    for l:matcher in self.matchers
      if (s:level.preamble && !get(l:matcher, 'in_preamble'))
            \ || (!s:level.preamble && !get(l:matcher, 'in_content', 1))
            \ || l:line !~# l:matcher.re
        continue
      endif

      if has_key(l:matcher, 'action')
        call l:matcher.action(l:context)
      else
        let l:entry = call(
              \ get(l:matcher, 'get_entry', function('vimtex#toc#matchers#general')),
              \ [l:context],
              \ l:matcher)

        if !empty(l:entry)
          call add(self.entries, l:entry)
        endif
      endif

      break
    endfor
  endfor

  " Remove superfluous TOC entries (cf. the "included files" section above)
  call filter(self.entries, 'get(v:val, ''entries'', 1) == 1')
endfunction

" }}}1

function! s:toc.hook_init_post() abort dict " {{{1
  if g:vimtex_toc_fold
    let self.foldexpr = function('s:foldexpr')
    let self.foldtext  = function('s:foldtext')
    setlocal foldmethod=expr
    setlocal foldexpr=b:index.foldexpr(v:lnum)
    setlocal foldtext=b:index.foldtext()
    let &l:foldlevel = get(self, 'fold_level', g:vimtex_toc_fold_level_start)
  endif

  nnoremap <buffer> <silent> s :call b:index.toggle_numbers()<cr>
  nnoremap <buffer> <silent> t :call b:index.toggle_sorted_todos()<cr>
  nnoremap <buffer> <silent> u :call b:index.update(1)<cr>
  nnoremap <buffer> <silent> - :call b:index.decrease_depth()<cr>
  nnoremap <buffer> <silent> + :call b:index.increase_depth()<cr>

  if self.hotkeys.enabled
    for entry in self.entries
      execute printf(
            \ 'nnoremap <buffer><silent> %s%s'
            \ . ' :call b:index.activate_number(%d)<cr>',
            \ self.hotkeys.leader, entry.hotkey, entry.num)
    endfor
  endif

  " Jump to closest index
  call vimtex#pos#set_cursor(self.get_closest_index())
endfunction

" }}}1
function! s:toc.get_closest_index() abort dict " {{{1
  let l:calling_rank = 0
  for [l:file, l:lnum, l:line] in vimtex#parser#tex(b:vimtex.tex)
    let l:calling_rank += 1
    if l:file ==# self.calling_file && l:lnum >= self.calling_line
      break
    endif
  endfor

  let l:index = 0
  let l:dist = 0
  let l:closest_index = 1
  let l:closest_dist = 10000
  for l:entry in self.entries
    let l:index += 1
    let l:dist = l:calling_rank - entry.rank

    if l:dist >= 0 && l:dist < l:closest_dist
      let l:closest_dist = l:dist
      let l:closest_index = l:index
    endif
  endfor

  return [0, l:closest_index + self.help_nlines, 0, 0]
endfunction

" }}}1
function! s:toc.print_entries() abort dict " {{{1
  let self.number_width = max([0, 2*(self.tocdepth + 2)])
  let self.number_format = '%-' . self.number_width . 's'

  for entry in self.entries
    call self.print_entry(entry)
  endfor
endfunction

" }}}1
function! s:toc.print_entry(entry) abort dict " {{{1
  let level = self.max_level - a:entry.level

  let output = ''
  if self.show_numbers
    let number = level >= self.tocdepth + 2 ? ''
          \ : strpart(self.print_number(a:entry.number),
          \           0, self.number_width - 1)
    let output .= printf(self.number_format, number)
  endif

  if self.hotkeys.enabled
    let output .= printf('[%S] ', a:entry.hotkey)
  endif

  let title = self.todo_sorted
        \ ? get(a:entry, 'title_sorted', a:entry.title)
        \ : a:entry.title

  let output .= printf('%-140S%s', title, level)

  call append('$', output)
endfunction

" }}}1
function! s:toc.print_number(number) abort dict " {{{1
  if empty(a:number) | return '' | endif
  if type(a:number) == type('') | return a:number | endif

  if get(a:number, 'part_toggle')
    return s:int_to_roman(a:number.part)
  endif

  let number = [
        \ a:number.chapter,
        \ a:number.section,
        \ a:number.subsection,
        \ a:number.subsubsection,
        \ a:number.subsubsubsection,
        \ ]

  " Remove unused parts
  while len(number) > 0 && number[0] == 0
    call remove(number, 0)
  endwhile
  while len(number) > 0 && number[-1] == 0
    call remove(number, -1)
  endwhile

  " Change numbering in frontmatter, appendix, and backmatter
  if self.topmatters > 1
        \ && (a:number.frontmatter || a:number.backmatter)
    return ''
  elseif a:number.appendix
    let number[0] = nr2char(number[0] + 64)
  endif

  return join(number, '.')
endfunction

" }}}1
function! s:toc.decrease_depth() abort dict "{{{1
  let self.tocdepth = max([self.tocdepth - 1, -2])
  call self.refresh()
endfunction

" }}}1
function! s:toc.increase_depth() abort dict "{{{1
  let self.tocdepth = min([self.tocdepth + 1, 5])
  call self.refresh()
endfunction

" }}}1
function! s:toc.syntax() abort dict "{{{1
  syntax match VimtexTocHelp /^\S.*: .*/
  syntax match VimtexTocNum
        \ /\v^(T%[ODO:]\s*)?(([A-Z]+>|\d+)(\.\d+)*)?\s*/ contained
        \ contains=VimtexTocTodo
  syntax match VimtexTocTodo /T\%[ODO:]/ contained
  syntax match VimtexTocHotkey /\[[^]]\+\]/ contained
  syntax match VimtexTocTag
        \ /^\[.\]/ contained

  syntax match VimtexTocSec0 /^.*0$/ contains=@VimtexTocStuff
  syntax match VimtexTocSec1 /^.*1$/ contains=@VimtexTocStuff
  syntax match VimtexTocSec2 /^.*2$/ contains=@VimtexTocStuff
  syntax match VimtexTocSec3 /^.*3$/ contains=@VimtexTocStuff
  syntax match VimtexTocSec4 /^.*4$/ contains=@VimtexTocStuff

  syntax cluster VimtexTocStuff
        \ contains=VimtexTocNum,VimtexTocTag,VimtexTocHotkey,@Tex
endfunction

" }}}1
function! s:toc.toggle_numbers() abort dict "{{{1
  let self.show_numbers = self.show_numbers ? 0 : 1
  call self.refresh()
endfunction

" }}}1
function! s:toc.toggle_sorted_todos() abort dict "{{{1
  let self.todo_sorted = self.todo_sorted ? 0 : 1
  call self.update(1)
  call vimtex#pos#set_cursor(self.get_closest_index())
endfunction

" }}}1
function! s:toc.activate_number(n) abort dict "{{{1
  execute printf('normal! %dG', self.help_nlines + a:n)
  call self.activate(1)
endfunction

" }}}1

function! s:foldexpr(lnum) abort " {{{1
  let pline = getline(a:lnum - 1)
  let cline = getline(a:lnum)
  let nline = getline(a:lnum + 1)
  let l:pn = matchstr(pline, '\d$')
  let l:cn = matchstr(cline, '\d$')
  let l:nn = matchstr(nline, '\d$')

  " Don't fold options
  if cline =~# '^\s*$'
    return 0
  endif

  if l:nn > l:cn
    return '>' . l:nn
  endif

  if l:cn < l:pn
    return l:cn
  endif

  return '='
endfunction

" }}}1
function! s:foldtext() abort " {{{1
  return getline(v:foldstart)
endfunction

" }}}1

function! s:int_to_roman(number) " {{{1
  let l:number = a:number
  let l:result = ''
  for [l:val, l:romn] in [
        \ ['1000', 'M'],
        \ ['900', 'CM'],
        \ ['500', 'D'],
        \ ['400', 'CD' ],
        \ ['100', 'C'],
        \ ['90', 'XC'],
        \ ['50', 'L'],
        \ ['40', 'XL'],
        \ ['10', 'X'],
        \ ['9', 'IX'],
        \ ['5', 'V'],
        \ ['4', 'IV'],
        \ ['1', 'I'],
        \]
    while l:number >= l:val
      let l:number -= l:val
      let l:result .= l:romn
    endwhile
  endfor

  return l:result
endfunction

" }}}1


" Define simple type for TOC level
let s:level = {}
function! s:level.reset(part, level) abort dict " {{{1
  let self.current = 0
  let self.preamble = 0
  let self.frontmatter = 0
  let self.mainmatter = 0
  let self.appendix = 0
  let self.backmatter = 0
  let self.part = 0
  let self.chapter = 0
  let self.section = 0
  let self.subsection = 0
  let self.subsubsection = 0
  let self.subsubsubsection = 0
  let self.current = a:level
  let self[a:part] = 1
endfunction

" }}}1
function! s:level.increment(level) abort dict " {{{1
  let self.current = s:sec_to_value[a:level]

  let self.part_toggle = 0

  if a:level ==# 'part'
    let self.part += 1
    let self.part_toggle = 1
  elseif a:level ==# 'chapter'
    let self.chapter += 1
    let self.section = 0
    let self.subsection = 0
    let self.subsubsection = 0
    let self.subsubsubsection = 0
  elseif a:level ==# 'section'
    let self.section += 1
    let self.subsection = 0
    let self.subsubsection = 0
    let self.subsubsubsection = 0
  elseif a:level ==# 'subsection'
    let self.subsection += 1
    let self.subsubsection = 0
    let self.subsubsubsection = 0
  elseif a:level ==# 'subsubsection'
    let self.subsubsection += 1
    let self.subsubsubsection = 0
  elseif a:level ==# 'subsubsubsection'
    let self.subsubsubsection += 1
  endif
endfunction

" }}}1

" Map for section hierarchy
let s:sec_to_value = {
      \ '_' : 0,
      \ 'subsubsubsection' : 1,
      \ 'subsubsection' : 2,
      \ 'subsection' : 3,
      \ 'section' : 4,
      \ 'chapter' : 5,
      \ 'part' : 6,
      \ }

function! s:base(n, k) " {{{1
  if a:n < a:k
    return [a:n]
  else
    return add(s:base(a:n/a:k, a:k), a:n % a:k)
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
