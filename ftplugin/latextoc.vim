" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" Set local buffer settings
setlocal buftype=nofile
setlocal bufhidden=wipe
setlocal nobuflisted
setlocal noswapfile
setlocal nowrap
setlocal nonumber
setlocal nolist
setlocal nospell
setlocal cursorline
setlocal tabstop=8
setlocal cole=0
setlocal cocu=nvic
if g:latex_toc_fold
  setlocal foldmethod=expr
  setlocal foldexpr=toc#fold(v:lnum)
  setlocal foldtext=toc#fold_tex()
endif

" Define mappings
nnoremap <buffer> <silent> G G4k
nnoremap <buffer> <silent> <Esc>OA k
nnoremap <buffer> <silent> <Esc>OB j
nnoremap <buffer> <silent> <Esc>OC l
nnoremap <buffer> <silent> <Esc>OD h
nnoremap <buffer> <silent> s             :call <SID>toc_toggle_numbers()<cr>
nnoremap <buffer> <silent> q             :call <SID>toc_close()<cr>
nnoremap <buffer> <silent> <Esc>         :call <SID>toc_close()<cr>
nnoremap <buffer> <silent> <Space>       :call <SID>toc_activate(0)<cr>
nnoremap <buffer> <silent> <leftrelease> :call <SID>toc_activate(0)<cr>
nnoremap <buffer> <silent> <CR>          :call <SID>toc_activate(1)<cr>
nnoremap <buffer> <silent> <2-leftmouse> :call <SID>toc_activate(1)<cr>

" {{{1 s:toc_activate
function! s:toc_activate(close)
  let n = getpos('.')[1] - 1

  if n >= len(b:toc)
    return
  endif

  let entry = b:toc[n]

  let titlestr = s:toc_escape_title(entry['text'])

  " Search for duplicates
  let i=0
  let entry_hash = entry['level'].titlestr
  let duplicates = 0
  while i<n
    let i_hash = b:toc[i]['level'].s:toc_escape_title(b:toc[i]['text'])
    if i_hash == entry_hash
      let duplicates += 1
    endif
    let i += 1
  endwhile
  let toc_bnr = bufnr('%')
  let toc_wnr = winnr()

  execute b:calling_win . 'wincmd w'

  let files = [entry['file']]
  for line in filter(readfile(entry['file']), 'v:val =~ ''\\input{''')
    call add(files, matchstr(line, '{\zs.*\ze\(\.tex\)\?}') . '.tex')
  endfor

  " Find section in buffer (or inputted files)
  call s:toc_find_match('\\' . entry['level'] . '\_\s*{' . titlestr . '}',
        \ duplicates, files)

  if a:close
    if g:latex_toc_resize
      silent exe "set columns-=" . g:latex_toc_width
    endif
    execute 'bwipeout ' . toc_bnr
  else
    execute toc_wnr . 'wincmd w'
  endif
endfunction

" {{{1 s:toc_close
function! s:toc_close()
  if g:latex_toc_resize
    silent exe "set columns-=" . g:latex_toc_width
  endif
  bwipeout
endfunction

" {{{1 s:toc_escape_title
function! s:toc_escape_title(titlestr)
  " Credit goes to Marcin Szamotulski for the following fix.  It allows to
  " match through commands added by TeX.

  let titlestr = substitute(a:titlestr, '\\\w*\>\s*\%({[^}]*}\)\?', '.*', 'g')
  let titlestr = escape(titlestr, '\')
  return substitute(titlestr, ' ', '\\_\\s\\+', 'g')
endfunction

" {{{1 s:toc_find_match
function! s:toc_find_match(strsearch,duplicates,files)

  call s:toc_open_buf(a:files[0])
  let dups = a:duplicates

  " Skip duplicates
  while dups > 0
    if search(a:strsearch, 'w')
      let dups -= 1
    else
      break
    endif
  endwhile

  if search(a:strsearch, 'w')
    normal! zv
    return
  endif

  call s:toc_find_match(a:strsearch,dups,a:files[1:])

endfunction

" {{{1 s:toc_open_buf
function! s:toc_open_buf(file)

  let bnr = bufnr(a:file)
  if bnr == -1
    execute 'badd ' . a:file
    let bnr = bufnr(a:file)
  endif
  execute 'buffer! ' . bnr

endfunction

" {{{1 s:toc_toggle_numbers
function! s:toc_toggle_numbers()
  if b:toc_numbers
    setlocal conceallevel=3
    let b:toc_numbers = 0
  else
    setlocal conceallevel=0
    let b:toc_numbers = 1
  endif
endfunction
" }}}1

" vim: fdm=marker
