set nocompatible
set runtimepath^=../..
filetype plugin on

nnoremap q :qall!<cr>

function! Report()
  let l:sum = 0
  let l:max = 0
  for [l:key, l:value] in items(g:time_per_lnum)
    let l:sum += l:value
    if l:value > l:max
      let l:max = l:value
    endif
  endfor

  echo 'Number:  ' .. len(g:time_per_lnum)
  echo 'Sum:     ' .. l:sum
  echo 'Max:     ' .. l:max
  echo 'Avg:     ' .. l:sum/len(g:time_per_lnum)
  echo 'Repeats: ' .. len(g:repeats_per_lnum)
endfunction

let g:time_per_lnum = {}
let g:repeats_per_lnum = {}
function! FoldLevel()
  let start_time = reltime()
  let l:res = vimtex#fold#level(v:lnum)
  let elapsed_time = reltimefloat(reltime(start_time))
  if has_key(g:time_per_lnum, v:lnum)
    let g:repeats_per_lnum[v:lnum] = get(g:repeats_per_lnum, v:lnum, 0) + 1
  endif

  let g:time_per_lnum[v:lnum] = elapsed_time

  return l:res
endfunction

let g:vimtex_cache_root = "."
let g:vimtex_cache_persistent = v:false

setlocal foldmethod=expr
setlocal foldexpr=FoldLevel()
setlocal foldtext=vimtex#fold#text()

nnoremap <space>tt :<c-u>call Report()<cr>

silent edit ../example-startup-timing/thesis.tex
