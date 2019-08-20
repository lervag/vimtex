set nocompatible

let &rtp = 'targets.vim,' . &rtp
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'

filetype plugin indent on

source targets.vim/plugin/targets.vim
source ../../../ftplugin/tex.vim

set softtabstop=16 expandtab

" tests should pass with this setting too
" set selection=exclusive

function! s:execute(operation, motions)
    if a:operation == 'c'
        execute "normal" a:operation . a:motions . "_"
    elseif a:operation == 'v'
        execute "normal" a:operation . a:motions
        normal r_
    else
        execute "normal" a:operation . a:motions
    endif
    if a:operation == 'y'
        execute "normal A\<Tab>'\<C-R>\"'"
    endif
    execute "normal I" . a:operation . a:motions . "\<Tab>\<Esc>"
endfunction

function! s:testVimtexCmdtargets()
    " based on testBasics() from 'targets.vim/test/test.vim'
    edit test1.in
    setf tex
    normal gg0

    execute "normal /xxxxxx\<CR>"
    for delset in [
                \ [ 'c' ]
                \ ]
        normal "lyy

        for op in [ 'c', 'd', 'y', 'v' ]
            for cnt in [ '', '1', '2' ]
                for ln in [ 'l', '', 'n' ]
                    for iaIA in [ 'I', 'i', 'a', 'A' ]
                        for del in delset
                            execute "normal \"lpfx"
                            call s:execute(op, cnt . iaIA . ln . del)
                        endfor
                    endfor
                endfor
            endfor
        endfor

        normal +
    endfor

    normal +

    write! test1.out
endfunction

call s:testVimtexCmdtargets()

quit!
