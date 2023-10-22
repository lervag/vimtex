set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_parser_bib_backend = 'bibtex'

silent edit test_cache.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\cite{', '')
call assert_true(len(s:candidates) == 1)
call assert_equal(
      \ '[a] Müller et al. (2019), "A new role for CsrA: promotion of complex formation between an srna and its mrna target in bacillus subtilis"',
      \ s:candidates[0].menu
      \)

call vimtex#cache#close('bibcomplete')
let g:vimtex_complete_bib.menu_fmt = '[@type] @year @author_short'
let s:candidates = vimtex#test#completion('\cite{', '')
call assert_true(len(s:candidates) == 1)
call assert_equal(
      \ '[a] 2019 Müller et al.',
      \ s:candidates[0].menu
      \)

for s:file in glob('*.json', 0, 1)
  call delete(s:file)
endfor

call vimtex#test#finished()
