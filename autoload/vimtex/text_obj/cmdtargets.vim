" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#text_obj#cmdtargets#new(args) " {{{1
    return {
                \ 'genFuncs': {
                \     'c': function('vimtex#text_obj#cmdtargets#current'),
                \     'n': function('vimtex#text_obj#cmdtargets#next'),
                \     'l': function('vimtex#text_obj#cmdtargets#last'),
                \ },
                \ 'modFuncs': {
                \     'i': [function('vimtex#text_obj#cmdtargets#inner')],
                \     'a': [function('targets#modify#keep')],
                \     'I': [function('vimtex#text_obj#cmdtargets#inner'), function('targets#modify#shrink')],
                \     'A': [function('targets#modify#expand')],
                \ }}
endfunction

" }}}1

function! vimtex#text_obj#cmdtargets#current(args, opts, state) " {{{1
    if a:opts.first
        let cnt = 1
    else
        let cnt = 2
    endif

    let target = s:select(cnt)
    call target.cursorE() " keep going from right end
    return target
endfunction

" }}}1

function! vimtex#text_obj#cmdtargets#next(args, opts, state) " {{{1
    if targets#util#search('\\\S*{', 'W') > 0
        return targets#target#withError('no target')
    endif

    let oldpos = getpos('.')
    let target = s:select(1)
    call setpos('.', oldpos)
    return target
endfunction

" }}}1

function! vimtex#text_obj#cmdtargets#last(args, opts, state) " {{{1
    if targets#util#search('\\\S*{', 'bW') > 0
        return targets#target#withError('no target')
    endif

    let oldpos = getpos('.')
    let target = s:select(1)
    call setpos('.', oldpos)
    return target
endfunction

" }}}1

function! s:select(count) " {{{1
    " try to select command
    silent! execute 'keepjumps normal v'.a:count."\<Plug>(vimtex-ac)v"
    let target = targets#target#fromVisualSelection()

    if target.sc == target.ec && target.sl == target.el
        return targets#target#withError('tex_cmd select')
    endif

    return target
endfunction

" }}}1

function! vimtex#text_obj#cmdtargets#inner(target, args) " {{{1
    if a:target.state().isInvalid()
        return
    endif

    let [sLinewise, eLinewise] = [0, 0]
    call a:target.cursorS()
    if searchpos('\S', 'nW', line('.'))[0] == 0
        " if only whitespace after cursor
        let sLinewise = 1
    endif
    silent! execute 'normal! f '
    call a:target.setS()

    call a:target.cursorE()
    if a:target.sl < a:target.el && searchpos('\S', 'bnW', line('.'))[0] == 0
        " if only whitespace in front of cursor
        let eLinewise = 1
        " move to end of line above
        normal! -$
    else
        " one character back
        silent! execute "normal! \<BS>"
    endif
    call a:target.setE()
    let a:target.linewise = sLinewise && eLinewise
endfunction

" }}}1
