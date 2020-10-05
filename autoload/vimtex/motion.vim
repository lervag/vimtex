" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#motion#init_buffer() abort " {{{1
  if !g:vimtex_motion_enabled | return | endif

  " Utility map to avoid conflict with "normal" command
  nnoremap <buffer> <sid>(v) v
  nnoremap <buffer> <sid>(V) V

  " Matching pairs
  nnoremap <silent><buffer> <plug>(vimtex-%) :call vimtex#motion#find_matching_pair()<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-%) :<c-u>call vimtex#motion#find_matching_pair(1)<cr>
  xmap     <silent><buffer> <plug>(vimtex-%) <sid>(vimtex-%)
  onoremap <silent><buffer> <plug>(vimtex-%) :execute "normal \<sid>(v)\<sid>(vimtex-%)"<cr>

  " Sections
  nnoremap <silent><buffer> <plug>(vimtex-]]) :<c-u>call vimtex#motion#section(0,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-][) :<c-u>call vimtex#motion#section(1,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[]) :<c-u>call vimtex#motion#section(1,1,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[[) :<c-u>call vimtex#motion#section(0,1,0)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-]]) :<c-u>call vimtex#motion#section(0,0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-][) :<c-u>call vimtex#motion#section(1,0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-[]) :<c-u>call vimtex#motion#section(1,1,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-[[) :<c-u>call vimtex#motion#section(0,1,1)<cr>
  xmap     <silent><buffer> <plug>(vimtex-]]) <sid>(vimtex-]])
  xmap     <silent><buffer> <plug>(vimtex-][) <sid>(vimtex-][)
  xmap     <silent><buffer> <plug>(vimtex-[]) <sid>(vimtex-[])
  xmap     <silent><buffer> <plug>(vimtex-[[) <sid>(vimtex-[[)
  onoremap <silent><buffer> <plug>(vimtex-]])
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-]])"<cr>
  onoremap <silent><buffer> <plug>(vimtex-][)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-][)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-[])
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-[])"<cr>
  onoremap <silent><buffer> <plug>(vimtex-[[)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-[[)"<cr>

  " Environments
  nnoremap <silent><buffer> <plug>(vimtex-]m) :<c-u>call vimtex#motion#environment(1,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-]M) :<c-u>call vimtex#motion#environment(0,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[m) :<c-u>call vimtex#motion#environment(1,1,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[M) :<c-u>call vimtex#motion#environment(0,1,0)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-]m) :<c-u>call vimtex#motion#environment(1,0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-]M) :<c-u>call vimtex#motion#environment(0,0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-[m) :<c-u>call vimtex#motion#environment(1,1,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-[M) :<c-u>call vimtex#motion#environment(0,1,1)<cr>
  xmap     <silent><buffer> <plug>(vimtex-]m) <sid>(vimtex-]m)
  xmap     <silent><buffer> <plug>(vimtex-]M) <sid>(vimtex-]M)
  xmap     <silent><buffer> <plug>(vimtex-[m) <sid>(vimtex-[m)
  xmap     <silent><buffer> <plug>(vimtex-[M) <sid>(vimtex-[M)
  onoremap <silent><buffer> <plug>(vimtex-]m)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-]m)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-]M)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-]M)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-[m)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-[m)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-[M)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-[M)"<cr>

  " Comments
  nnoremap <silent><buffer> <plug>(vimtex-]/) :<c-u>call vimtex#motion#comment(1,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-]*) :<c-u>call vimtex#motion#comment(0,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[/) :<c-u>call vimtex#motion#comment(1,1,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[*) :<c-u>call vimtex#motion#comment(0,1,0)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-]/) :<c-u>call vimtex#motion#comment(1,0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-]*) :<c-u>call vimtex#motion#comment(0,0,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-[/) :<c-u>call vimtex#motion#comment(1,1,1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-[*) :<c-u>call vimtex#motion#comment(0,1,1)<cr>
  xmap     <silent><buffer> <plug>(vimtex-]/) <sid>(vimtex-]/)
  xmap     <silent><buffer> <plug>(vimtex-]*) <sid>(vimtex-]*)
  xmap     <silent><buffer> <plug>(vimtex-[/) <sid>(vimtex-[/)
  xmap     <silent><buffer> <plug>(vimtex-[*) <sid>(vimtex-[*)
  onoremap <silent><buffer> <plug>(vimtex-]/)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-]/)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-]*)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-]*)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-[/)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-[/)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-[*)
        \ :execute "normal \<sid>(V)" . v:count1 . "\<sid>(vimtex-[*)"<cr>

  " Math
  nnoremap <silent><buffer> <plug>(vimtex-]n) :<c-u>call vimtex#motion#math(1,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-]N) :<c-u>call vimtex#motion#math(0,0,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[n) :<c-u>call vimtex#motion#math(1,1,0)<cr>
  nnoremap <silent><buffer> <plug>(vimtex-[N) :<c-u>call vimtex#motion#math(0,1,0)<cr>
endfunction

" }}}1

function! vimtex#motion#find_matching_pair(...) abort " {{{1
  if a:0 > 0
    normal! gv
  endif

  let delim = vimtex#delim#get_current('all', 'both')
  if empty(delim)
    let delim = vimtex#delim#get_next('all', 'both')
    if empty(delim) | return | endif
  endif

  let delim = vimtex#delim#get_matching(delim)
  if empty(delim) | return | endif
  if empty(delim.match) | return | endif

  normal! m`
  call vimtex#pos#set_cursor(delim.lnum,
        \ (delim.is_open
        \   ? delim.cnum
        \   : delim.cnum + strlen(delim.match) - 1))
endfunction

" }}}1
function! vimtex#motion#section(type, backwards, visual) abort " {{{1
  let l:count = v:count1
  if a:visual
    normal! gv
  endif

  " Check trivial cases
  let l:top = search(s:re_sec, 'nbW') == 0
  let l:bottom = search(a:type == 1 ? s:re_sec_t2 : s:re_sec, 'nW') == 0
  if a:backwards && l:top
    return vimtex#pos#set_cursor([1, 1])
  elseif !a:backwards && l:bottom
    return vimtex#pos#set_cursor([line('$'), 1])
  endif

  " Define search pattern and search flag
  let l:re = a:type == 0 ? s:re_sec : s:re_sec_t1
  let l:flags = 'W'
  if a:backwards
    let l:flags .= 'b'
  endif

  for l:_ in range(l:count)
    let l:save_pos = vimtex#pos#get_cursor()

    if a:type == 1
      call search('\S', 'W')
    endif

    let l:bottom = search(s:re_sec_t2, 'nW') == 0
    if a:type == 1 && !a:backwards && l:bottom
      return vimtex#pos#set_cursor([line('$'), 1])
    endif

    let l:top = search(s:re_sec, 'ncbW') == 0
    let l:lnum = search(l:re, l:flags)

    if l:top && l:lnum > 0 && a:type == 1 && !a:backwards
      let l:lnum = search(l:re, l:flags)
    endif

    if a:type == 1
      call search('\S\s*\n\zs', 'Wb')

      " Move to start of file if cursor was moved to top part of document
      if search(s:re_sec, 'ncbW') == 0
        call vimtex#pos#set_cursor([1, 1])
      endif
    endif
  endfor
endfunction

" }}}1
function! vimtex#motion#environment(begin, backwards, visual) abort " {{{1
  let l:count = v:count1
  if a:visual
    normal! gv
  endif

  let l:re = g:vimtex#re#not_comment . (a:begin ? '\\begin\s*\{' : '\\end\s*\{')
  let l:flags = 'W' . (a:backwards ? 'b' : '')

  for l:_ in range(l:count)
    call search(l:re, l:flags)
  endfor
endfunction

" }}}1
function! vimtex#motion#comment(begin, backwards, visual) abort " {{{1
  let l:count = v:count1
  if a:visual
    normal! gv
  endif

  let l:re = a:begin
        \ ? '\v%(^\s*\%.*\n)@<!\s*\%'
        \ : '\v^\s*\%.*\n%(^\s*\%)@!'
  let l:flags = 'W' . (a:backwards ? 'b' : '')

  for l:_ in range(l:count)
    call search(l:re, l:flags)
  endfor
endfunction

" }}}1
function! vimtex#motion#math(begin, backwards, visual) abort " {{{1
  " Save cursor position first (and restore it on errors)
  let l:curpos_saved = vimtex#pos#get_cursor()

  let l:count = v:count1
  if a:visual
    normal! gv
  endif

  " Search for $, $$, \[, \(, \begin
  " Use syntax to determine if we are inside math region
  let l:re = g:vimtex#re#not_comment . (a:begin ? '%(\${1,2}|\\\[|\\\(|\\begin\s*\{)' : '%(\${1,2}|\\\]|\\\)|\\end\s*\{)')
  let l:flags = 'W' . (a:backwards ? 'b' : '')

  for l:_ in range(l:count)
    " Ensure we are not going into infinite loop
    let l:iter = 0

    " We need to restore cursor back to it's original position if jumping
    " to count number of math environments fail.
    let l:restore_cursor = 1
    while l:iter <= 5
      let l:iter += 1
      call search(l:re, l:flags)
      let l:pos = vimtex#pos#get_cursor()
      if a:begin == 0
        let l:pos_prev = vimtex#pos#prev(l:pos[1],l:pos[2]-1)
        if vimtex#syntax#in_mathzone(l:pos_prev[1],l:pos_prev[2],l:pos_prev[3])
            let l:restore_cursor = 0
            break
        endif
      elseif vimtex#syntax#in_mathzone(l:pos[1],l:pos[2],l:pos[3])
        let l:restore_cursor = 0
        break
      endif
    endwhile
  endfor
  " Restore cursor position if fail
  if l:restore_cursor
    call vimtex#pos#set_cursor(l:curpos_saved)
  endif
endfunction


" Patterns to match section/chapter/...
let s:re_sec = '\v^\s*\\%(%(sub)?paragraph|%(sub)*section|chapter|part|'
      \ .        'appendi%(x|ces)|%(front|back|main)matter)>'
let s:re_sec_t1 = '\v%(' . s:re_sec . '|^\s*%(\\end\{document\}|%$))'
let s:re_sec_t2 = '\v%(' . s:re_sec . '|^\s*\\end\{document\})'
