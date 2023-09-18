set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_toc_show_preamble = 0
let g:vimtex_toc_config_matchers = {
      \ 'beamer_frame': {'disable': 1}
      \}

silent edit test-beamer.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()

call assert_equal(4, len(s:toc))
call assert_notequal('Preamble', s:toc[0].title)
call assert_equal('Conclusion', s:toc[-1].title)

call vimtex#test#finished()
