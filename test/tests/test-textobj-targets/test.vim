set nocompatible
let &rtp = 'targets.vim,' . &rtp
let &rtp = '../../..,' . &rtp
filetype plugin on

runtime plugin/targets.vim

let g:tex_flavor = 'latex'

set noswapfile
set softtabstop=16
set expandtab

silent edit test1.tex

if empty($INMAKE) | finish | endif

function! s:testVimtexCmdtargets()
  silent! edit!
  call search('xxxxxx')
  normal! "lyy

  for operator in ['c', 'd', 'y', 'v']
    for cnt in ['', '1', '2']
      for lastnext in ['l', '', 'n']
        for iaIA in ['I', 'i', 'a', 'A']
          for target in ['c']
            normal! "lpfx
            call s:execute(operator, cnt . iaIA . lastnext . target)
          endfor
        endfor
      endfor
    endfor
  endfor

  normal! "lp2f}l
  call s:execute('v', 'ilc')

  write! test1.out
endfunction

function! s:execute(operation, motions)
  execute 'normal' a:operation . a:motions
        \ . (a:operation ==# 'c' ? '_' : '')

  if a:operation ==# 'v'
    normal! r_
  endif

  if a:operation ==# 'y'
    execute "normal! A\<tab>'\<c-r>\"'"
  endif

  execute 'normal! I' . a:operation . a:motions . "\<tab>"
endfunction

call s:testVimtexCmdtargets()

" Tests should pass with this setting too
set selection=exclusive
call s:testVimtexCmdtargets()

quit!
