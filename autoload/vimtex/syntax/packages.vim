" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#packages#init() abort " {{{1
  if !exists('b:vimtex') || !exists('b:vimtex_syntax') | return | endif

  " Initialize project cache (used e.g. for the minted package)
  if !has_key(b:vimtex, 'syntax')
    let b:vimtex.syntax = {}
  endif

  call s:register_packages()

  for [l:pkg, l:cfg] in items(b:vimtex_syntax)
    if !l:cfg.__load || l:cfg.__loaded | continue | endif

    call vimtex#syntax#p#{l:pkg}#load(l:cfg)
    let l:cfg.__loaded = 1
  endfor
endfunction

" }}}1
function! vimtex#syntax#packages#load(pkg) abort " {{{1
  let l:cfg = get(b:vimtex_syntax, a:pkg, {})
  if empty(l:cfg) || l:cfg.__loaded | return | endif

  call vimtex#syntax#p#{a:pkg}#load(l:cfg)
  let l:cfg.__loaded = 1
endfunction

" }}}1

function! s:register_packages() abort " {{{1
  let l:packages = map(
        \ keys(b:vimtex.packages) + [b:vimtex.documentclass],
        \ {_, x -> tolower(substitute(x, '-', '_', 'g'))})

  for l:pkg in s:addons
    if empty(l:pkg) | continue | endif

    " Register "state" for package in current buffer
    if !has_key(b:vimtex_syntax, l:pkg)
      let b:vimtex_syntax[l:pkg] = extend({
            \ 'load': 1,
            \ '__load': 0,
            \ '__loaded': 0,
            \}, get(g:vimtex_syntax_packages, l:pkg, {}))
    endif
    let l:cfg = b:vimtex_syntax[l:pkg]

    let l:cfg.__load =
          \    l:cfg.load > 1
          \ || (l:cfg.load == 1 && index(l:packages, l:pkg) >= 0)
  endfor
endfunction

let s:addons = map(
      \ glob(fnamemodify(expand('<sfile>'), ':h') . '/p/*.vim', 0, 1),
      \ "fnamemodify(v:val, ':t:r')")

" }}}1
