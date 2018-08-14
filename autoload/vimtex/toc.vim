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
      \   'c:       clear filters',
      \   'f:       filter',
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

  let l:toc.hotkeys = extend({
        \ 'enabled' : '0',
        \ 'leader' : ';',
        \ 'keys' : 'abdeghijklmnoprvxyz',
        \}, g:vimtex_toc_hotkeys)

  unlet l:toc.new
  return l:toc
endfunction

" }}}1
function! s:toc.update(force) abort dict " {{{1
  if has_key(self, 'entries') && !g:vimtex_toc_refresh_always && !a:force
    return self.entries
  endif

  let self.entries = vimtex#parser#toc(b:vimtex.tex, {'types': ['content', 'todo']})
  let self.topmatters = vimtex#parser#toc#get_topmatters()

  "
  " Sort todo entries
  "
  if self.todo_sorted
    let l:todos = filter(copy(self.entries), 'v:val.type ==# ''todo''')
    for l:t in l:todos[1:]
      let l:t.level = 1
    endfor
    call filter(self.entries, 'v:val.type !=# ''todo''')
    let self.entries = l:todos + self.entries
  endif

  let self.all_entries = deepcopy(self.entries)

  "
  " Add hotkeys to entries
  "
  if self.hotkeys.enabled
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
  endif

  "
  " Refresh if wanted
  "
  if a:force && self.is_open()
    call self.refresh()
  endif

  return self.entries
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

  nnoremap <buffer><nowait><silent> f :call b:index.filter()<cr>
  nnoremap <buffer><nowait><silent> F :call b:index.clear_filter()<cr>
  nnoremap <buffer><nowait><silent> s :call b:index.toggle_numbers()<cr>
  nnoremap <buffer><nowait><silent> t :call b:index.toggle_sorted_todos()<cr>
  nnoremap <buffer><nowait><silent> u :call b:index.update(1)<cr>
  nnoremap <buffer><nowait><silent> - :call b:index.decrease_depth()<cr>
  nnoremap <buffer><nowait><silent> + :call b:index.increase_depth()<cr>

  if self.hotkeys.enabled
    for entry in self.entries
      execute printf(
            \ 'nnoremap <buffer><nowait><silent> %s%s'
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
  let l:not_found = 1
  for [l:file, l:lnum, l:line] in vimtex#parser#tex(b:vimtex.tex)
    let l:calling_rank += 1
    if l:file ==# self.calling_file && l:lnum >= self.calling_line
      let l:not_found = 0
      break
    endif
  endfor

  if l:not_found
    return [0, get(self, 'prev_index', self.help_nlines + 1), 0, 0]
  endif

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
  let output = ''
  if self.show_numbers
    let number = a:entry.level >= self.tocdepth + 2 ? ''
          \ : strpart(self.print_number(a:entry.number),
          \           0, self.number_width - 1)
    let output .= printf(self.number_format, number)
  endif

  if self.hotkeys.enabled
    let output .= printf('[%S] ', a:entry.hotkey)
  endif

  let output .= printf('%-140S%s', a:entry.title, a:entry.level)

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
  syntax match VimtexTocNum /\v^(([A-Z]+>|\d+)(\.\d+)*)?\s*/ contained
  syntax match VimtexTocTodo /\s\zsTODO: / contained
  syntax match VimtexTocHotkey /\[[^]]\+\]/ contained
  syntax match VimtexTocTag
        \ /^\[.\]/ contained

  syntax match VimtexTocSec0 /^.*0$/ contains=@VimtexTocStuff
  syntax match VimtexTocSec1 /^.*1$/ contains=@VimtexTocStuff
  syntax match VimtexTocSec2 /^.*2$/ contains=@VimtexTocStuff
  syntax match VimtexTocSec3 /^.*3$/ contains=@VimtexTocStuff
  syntax match VimtexTocSec4 /^.*4$/ contains=@VimtexTocStuff

  syntax cluster VimtexTocStuff
        \ contains=VimtexTocNum,VimtexTocTag,VimtexTocHotkey,VimtexTocTodo,@Tex
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
function! s:toc.clear_filter() dict "{{{1
  let self.entries = copy(self.all_entries)
  call self.refresh()
endfunction

" }}}1
function! s:toc.filter() dict "{{{1
  let filter = input('filter by: ')
  let self.entries = filter(self.entries, 'v:val.title =~# filter')
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
  let l:line = getline(v:foldstart)

  if b:index.todo_sorted && l:line =~# 'TODO:'
    return substitute(l:line, 'TODO\zs:.*', 's', '')
  else
    return l:line
  endif
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
function! s:base(n, k) " {{{1
  if a:n < a:k
    return [a:n]
  else
    return add(s:base(a:n/a:k, a:k), a:n % a:k)
  endif
endfunction

" }}}1
