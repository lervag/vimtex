set nocompatible
let &rtp = 'targets.vim,' . &rtp
let &rtp = '../..,' . &rtp
filetype plugin on

runtime plugin/targets.vim

set noswapfile
set softtabstop=16
set expandtab

silent edit test.tex

if empty($INMAKE) | finish | endif

function! s:testVimtexCmdtargets(name)
  silent! edit!
  normal! "lyy

  for operator in ['c', 'd', 'y', 'v']
    for cnt in ['', '1', '2']
      for lastnext in ['l', '', 'n']
        for iaIA in ['I', 'i', 'a', 'A']
          for target in ['c']
            let l:motion = cnt . iaIA . lastnext . target
            if operator ==# 'c' && l:motion =~# '^2.c$'
              continue
            endif

            normal! "lpfx
            call s:execute(operator, l:motion)
          endfor
        endfor
      endfor
    endfor
  endfor

  normal! "lp2f}l
  call s:execute('v', 'ilc')

  execute 'silent write!' a:name
endfunction

function! s:execute(operation, motions)
  let l:cmd = a:operation . a:motions . (a:operation ==# 'c' ? '_' : '')
  silent execute 'normal' l:cmd

  if a:operation ==# 'v'
    normal! r_
  endif

  if a:operation ==# 'y'
    execute "normal! A\<tab>'\<c-r>\"'"
  endif

  execute 'normal! I' . l:cmd . "\<tab>"
endfunction

call s:testVimtexCmdtargets('test1.out')

" Tests should pass with this setting too
set selection=exclusive
call s:testVimtexCmdtargets('test2.out')

quit!
