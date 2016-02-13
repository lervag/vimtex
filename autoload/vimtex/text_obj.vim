" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#text_obj#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_text_obj_enabled', 1)
endfunction

" }}}1
function! vimtex#text_obj#init_script() " {{{1
endfunction

" }}}1
function! vimtex#text_obj#init_buffer() " {{{1
  if !g:vimtex_text_obj_enabled | return | endif

  " Utility maps to avoid conflict with "normal" command
  nnoremap <buffer> <sid>(v) v
  nnoremap <buffer> <sid>(V) V

  " Commands
  xnoremap <silent><buffer>  <sid>(vimtex-ic) :<c-u>call vimtex#text_obj#commands(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ac) :<c-u>call vimtex#text_obj#commands()<cr>
  xmap     <silent><buffer> <plug>(vimtex-ic) <sid>(vimtex-ic)
  xmap     <silent><buffer> <plug>(vimtex-ac) <sid>(vimtex-ac)
  onoremap <silent><buffer> <plug>(vimtex-ic) :execute "normal \<sid>(v)\<sid>(vimtex-ic)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ac) :execute "normal \<sid>(v)\<sid>(vimtex-ac)"<cr>

  " Delimiters
  xnoremap <silent><buffer>  <sid>(vimtex-id) :<c-u>call vimtex#text_obj#delimiters(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ad) :<c-u>call vimtex#text_obj#delimiters()<cr>
  xmap     <silent><buffer> <plug>(vimtex-id) <sid>(vimtex-id)
  xmap     <silent><buffer> <plug>(vimtex-ad) <sid>(vimtex-ad)
  onoremap <silent><buffer> <plug>(vimtex-id) :execute "normal \<sid>(v)\<sid>(vimtex-id)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ad) :execute "normal \<sid>(v)\<sid>(vimtex-ad)"<cr>

  " Environments
  xnoremap <silent><buffer>  <sid>(vimtex-ie) :<c-u>call vimtex#text_obj#environments(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ae) :<c-u>call vimtex#text_obj#environments()<cr>
  xmap     <silent><buffer> <plug>(vimtex-ie) <sid>(vimtex-ie)
  xmap     <silent><buffer> <plug>(vimtex-ae) <sid>(vimtex-ae)
  onoremap <silent><buffer> <plug>(vimtex-ie) :execute "normal \<sid>(v)\<sid>(vimtex-ie)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ae) :execute "normal \<sid>(v)\<sid>(vimtex-ae)"<cr>

  " Inline math
  xnoremap <silent><buffer>  <sid>(vimtex-i$) :<c-u>call vimtex#text_obj#inline_math(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-a$) :<c-u>call vimtex#text_obj#inline_math()<cr>
  xmap     <silent><buffer> <plug>(vimtex-i$) <sid>(vimtex-i$)
  xmap     <silent><buffer> <plug>(vimtex-a$) <sid>(vimtex-a$)
  onoremap <silent><buffer> <plug>(vimtex-i$) :execute "normal \<sid>(v)\<sid>(vimtex-i$)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-a$) :execute "normal \<sid>(v)\<sid>(vimtex-a$)"<cr>

  " Paragraphs
  xnoremap <silent><buffer>  <sid>(vimtex-ip) :<c-u>call vimtex#text_obj#paragraphs(1)<cr>
  xnoremap <silent><buffer>  <sid>(vimtex-ap) :<c-u>call vimtex#text_obj#paragraphs()<cr>
  xmap     <silent><buffer> <plug>(vimtex-ip) <sid>(vimtex-ip)
  xmap     <silent><buffer> <plug>(vimtex-ap) <sid>(vimtex-ap)
  onoremap <silent><buffer> <plug>(vimtex-ip) :execute "normal \<sid>(V)\<sid>(vimtex-ip)"<cr>
  onoremap <silent><buffer> <plug>(vimtex-ap) :execute "normal \<sid>(V)\<sid>(vimtex-ap)"<cr>
endfunction

" }}}1

function! vimtex#text_obj#commands(...) " {{{1
  let l:cmd = vimtex#cmd#get_current()
  if empty(l:cmd) | return | endif

  let [l1, c1] = [l:cmd.pos_start.lnum, l:cmd.pos_start.cnum]
  let [l2, c2] = [l:cmd.pos_end.lnum, l:cmd.pos_end.cnum]

  if a:0 > 0
    let l2 = l1
    let c2 = c1 + strlen(l:cmd.name) - 1
    let c1 += 1
  endif

  call cursor(l1, c1)
  normal! v
  call cursor(l2, c2)
endfunction

" }}}1
function! vimtex#text_obj#delimiters(...) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('delim_all')
  if empty(l:open) | return | endif
  call s:text_obj_delim(l:open, l:close, a:0 > 0)
endfunction

" }}}1
function! vimtex#text_obj#environments(...) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env')
  if empty(l:open) | return | endif

  " Fix for options and extra arguments to environments, e.g.
  "
  "   \begin{frame}[asd]{title} ...
  "
  let l:open.match .= matchstr(join(getline(l:open.lnum, l:close.lnum), ''),
        \                      '^\v%(\s*\[[^]]*\])?%(\s*\{[^}]*\})*',
        \                      l:open.cnum + strlen(l:open.match) - 1)

  call s:text_obj_delim(l:open, l:close, a:0 > 0)
endfunction

" }}}1
function! vimtex#text_obj#inline_math(...) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env_math')
  if empty(l:open) | return | endif
  call s:text_obj_delim(l:open, l:close, a:0 > 0)
endfunction
" }}}1
function! vimtex#text_obj#paragraphs(...) " {{{1
  let inner = a:0 > 0

  " Define selection
  normal! 0j
  call vimtex#motion#next_paragraph(1,0)
  normal! jV
  call vimtex#motion#next_paragraph(0,0)

  " Go back one line for inner objects
  if inner
    normal! k
  endif
endfunction

" }}}1

function! s:text_obj_delim(open, close, inner) " {{{1
  let [l1, c1, l2, c2] = [a:open.lnum, a:open.cnum, a:close.lnum, a:close.cnum]

  if a:inner
    let c1 += len(a:open.match)
    let c2 -= 1

    let l:adjust_c1 = (c1 >= len(getline(l1)))
    let l:adjust_c2 = (c2 == 0) || (l:adjust_c1 &&
            \ len(substitute(strpart(getline(l2), 0, c2-1), '^\s*', '', '')) == 0)
    let l:adjust_both = l:adjust_c1 && l:adjust_c2

    if l:adjust_both
      let l1 += 1
      let c1 = strlen(matchstr(getline(l1), '^\s*')) + 1
    elseif l:adjust_c1
      let c1 += 1
    endif

    if l:adjust_c2
      let l2 -= 1
      let c2 = len(getline(l2)) + (l:adjust_both ? 0 : 1)
    endif
  else
    let c2 += len(a:close.match) - 1
  endif

  if l1 < l2 || (l1 == l2 && c1 < c2)
    execute 'normal!' visualmode() ==# 'V' ? 'V' : 'v'
    call cursor(l1, c1)
    normal! o
    call cursor(l2, c2)
  endif
endfunction
" }}}1

" vim: fdm=marker sw=2
