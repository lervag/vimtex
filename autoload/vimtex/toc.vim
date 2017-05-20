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
      \   'u:       update',
      \ ],
      \ 'show_numbers' : g:vimtex_toc_show_numbers,
      \ 'tocdepth' : g:vimtex_toc_tocdepth,
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
        \]
  let l:toc.matchers += g:vimtex_toc_custom_matchers

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
  for [l:file, l:lnum, l:line] in a:content
    let l:context = {
          \ 'file' : l:file,
          \ 'line' : l:line,
          \ 'lnum' : l:lnum,
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
    let &l:foldlevel = g:vimtex_toc_fold_level_start
  endif

  nnoremap <buffer> <silent> s :call b:index.toggle_numbers()<cr>
  nnoremap <buffer> <silent> u :call b:index.update(1)<cr>
  nnoremap <buffer> <silent> - :call b:index.decrease_depth()<cr>
  nnoremap <buffer> <silent> + :call b:index.increase_depth()<cr>

  " Jump to closest index
  call vimtex#pos#set_cursor(self.pos_closest)
endfunction

" }}}1
function! s:toc.print_entries() abort dict " {{{1
  if g:vimtex_toc_number_width
    let self.number_width = g:vimtex_toc_number_width
  else
    let self.number_width = 2*(self.tocdepth + 2)
  endif
  let self.number_width = max([0, self.number_width])
  let self.number_format = '%-' . self.number_width . 's'

  let index = 0
  let closest_index = 0
  for entry in self.entries
    let index += 1
    call self.print_entry(entry)
    if entry.file == self.calling_file && entry.line <= self.calling_line
      let closest_index = index
    endif
  endfor

  let self.pos_closest = [0, closest_index + self.help_nlines, 0, 0]
endfunction

" }}}1
function! s:toc.print_entry(entry) abort dict " {{{1
  let level = self.max_level - a:entry.level

  let output = ''
  if self.show_numbers
    let number = level >= self.tocdepth + 2 ? ''
          \ : strpart(self.print_number(a:entry.number), 0, self.number_width - 1)
    let output .= printf(self.number_format, number)
  endif
  let output .= printf('%-140S%s', a:entry.title, level)

  call append('$', output)
endfunction

" }}}1
function! s:toc.print_number(number) abort dict " {{{1
  if empty(a:number) | return '' | endif
  if type(a:number) == type('') | return a:number | endif

  let number = [
        \ a:number.part,
        \ a:number.chapter,
        \ a:number.section,
        \ a:number.subsection,
        \ a:number.subsubsection,
        \ a:number.subsubsubsection,
        \ ]

  " Remove unused parts
  while number[0] == 0
    call remove(number, 0)
  endwhile
  while number[-1] == 0
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
        \ /^\(\([A-Z]\+\>\|\d\+\)\(\.\d\+\)*\)\?\s*/ contained
  syntax match VimtexTocTag
        \ /^\[.\]/ contained
  syntax match VimtexTocSec0 /^.*0$/ contains=VimtexTocNum,VimtexTocTag,@Tex
  syntax match VimtexTocSec1 /^.*1$/ contains=VimtexTocNum,VimtexTocTag,@Tex
  syntax match VimtexTocSec2 /^.*2$/ contains=VimtexTocNum,VimtexTocTag,@Tex
  syntax match VimtexTocSec3 /^.*3$/ contains=VimtexTocNum,VimtexTocTag,@Tex
  syntax match VimtexTocSec4 /^.*4$/ contains=VimtexTocNum,VimtexTocTag,@Tex
endfunction

" }}}1
function! s:toc.toggle_numbers() abort dict "{{{1
  let self.show_numbers = self.show_numbers ? 0 : 1
  call self.refresh()
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

  if l:nn > l:cn && g:vimtex_toc_fold_levels >= l:nn
    return '>' . l:nn
  endif

  if l:cn < l:pn && l:cn >= l:nn && g:vimtex_toc_fold_levels >= l:cn
    return l:cn
  endif

  return '='
endfunction

" }}}1
function! s:foldtext() abort " {{{1
  return getline(v:foldstart)
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

  if a:level ==# 'part'
    let self.part += 1
    let self.chapter = 0
    let self.section = 0
    let self.subsection = 0
    let self.subsubsection = 0
    let self.subsubsubsection = 0
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

" vim: fdm=marker sw=2
