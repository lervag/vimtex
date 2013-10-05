" {{{1 latextoc#fold_level
function! latextoc#fold_level(lnum)
    let line  = getline(a:lnum)
    let match_s1 = line =~# '^\w\+\s'
    let match_s2 = line =~# '^\w\+\.\w\+\s'
    let match_s3 = line =~# '^\w\+\.\w\+\.\w\+\s'

    if g:latex_toc_fold_levels >= 3
        if match_s3
            return ">3"
        endif
    endif

    if g:latex_toc_fold_levels >= 2
        if match_s2
            return ">2"
        endif
    endif

    if match_s1
        return ">1"
    endif

    " Don't fold options
    if line =~# '^\s*$'
        return 0
    endif

    " Return previous fold level
    return "="
endfunction

" {{{1 latextoc#fold_text
function! latextoc#fold_text()
    let parts = matchlist(getline(v:foldstart), '^\(.*\)\t\(.*\)$')
    return printf('%-8s%-72s', parts[1], parts[2])
endfunction

" }}}1

" vim:fdm=marker:ff=unix
