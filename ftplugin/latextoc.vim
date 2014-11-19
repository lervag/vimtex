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
setlocal listchars=
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
  setlocal foldexpr=latextoc#fold_level(v:lnum)
  setlocal foldtext=latextoc#fold_text()
endif

" Refresh/Initialize TOC content
call latextoc#init()

" Define mappings
nnoremap <buffer> <silent> G G4k
nnoremap <buffer> <silent> <Esc>OA k
nnoremap <buffer> <silent> <Esc>OB j
nnoremap <buffer> <silent> <Esc>OC l
nnoremap <buffer> <silent> <Esc>OD h
nnoremap <buffer> <silent> s             :call <SID>toc_toggle_numbers()<cr>
nnoremap <buffer> <silent> -             :call <SID>toc_dec_secnumdepth()<cr>
nnoremap <buffer> <silent> +             :call <SID>toc_inc_secnumdepth()<cr>
nnoremap <buffer> <silent> q             :call <SID>toc_close()<cr>
nnoremap <buffer> <silent> <Esc>         :call <SID>toc_close()<cr>
nnoremap <buffer> <silent> <Space>       :call <SID>toc_activate(0)<cr>
nnoremap <buffer> <silent> <leftrelease> :call <SID>toc_activate(0)<cr>
nnoremap <buffer> <silent> <CR>          :call <SID>toc_activate(1)<cr>
nnoremap <buffer> <silent> <2-leftmouse> :call <SID>toc_activate(1)<cr>

function! s:toc_activate(close) "{{{1
  " Get TOC entry, do nothing if no entry found
  "   entry = {
  "     title  : ...,
  "     number : ...,
  "     file   : ...,
  "     line   : ...,
  "     }
  let n = getpos('.')[1] - 1
  if n >= len(b:toc)
    return
  endif
  let entry = b:toc[n]

  " Save TOC buffer info for later use
  let toc_bnr = bufnr('%')
  let toc_wnr = winnr()

  " Return to calling window
  execute b:calling_winnr . 'wincmd w'

  " Open file and line for given TOC entry
  call s:toc_open_entry(entry)

  " Keep or close TOC window (based on options)
  if a:close
    if g:latex_toc_resize
      silent exe "set columns-=" . g:latex_toc_width
    endif
    execute 'bwipeout ' . toc_bnr
  else
    execute toc_wnr . 'wincmd w'
  endif
endfunction

function! s:toc_close() "{{{1
  if g:latex_toc_resize
    silent exe "set columns-=" . g:latex_toc_width
  endif
  bwipeout
endfunction

function! s:toc_open_entry(entry) "{{{1
  " Get buffer number (add buffer if necessary)
  let bnr = bufnr(a:entry.file)
  if bnr == -1
    execute 'badd ' . fnameescape(a:entry.file)
    let bnr = bufnr(a:entry.file)
  endif

  " Set bufferopen command
  "   The point here is to use existing open buffer if the user has turned on
  "   the &switchbuf option to either 'useopen' or 'usetab'
  let cmd = 'buffer! '
  if &switchbuf =~ 'usetab'
    for i in range(tabpagenr('$'))
      if index(tabpagebuflist(i + 1), bnr) >= 0
        let cmd = 'sbuffer! '
        break
      endif
    endfor
  elseif &switchbuf =~ 'useopen'
    if bufwinnr(bnr) > 0
      let cmd = 'sbuffer! '
    endif
  endif

  " Open file buffer
  execute cmd . bnr

  " Go to entry line
  call setpos('.', [0, a:entry.line, 0, 0])

  " Ensure folds are opened
  normal! zv
endfunction

function! s:toc_toggle_numbers() "{{{1
  if b:toc_numbers
    let b:toc_numbers = 0
  else
    let b:toc_numbers = 1
  endif

  call latextoc#refresh()
endfunction

function! s:toc_inc_secnumdepth() "{{{1
  let b:toc_secnumdepth = min([b:toc_secnumdepth + 1, 5])
  let g:latex_toc_secnumdepth = b:toc_secnumdepth
  call latextoc#refresh()
endfunction

function! s:toc_dec_secnumdepth() "{{{1
  let b:toc_secnumdepth = max([b:toc_secnumdepth - 1, -2])
  let g:latex_toc_secnumdepth = b:toc_secnumdepth
  call latextoc#refresh()
endfunction

" }}}1

" vim: fdm=marker
