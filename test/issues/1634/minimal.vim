set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

set nomore

let g:tex_flavor = 'latex'

let g:vimtex_view_automatic = 0
let g:vimtex_cache_persistent = 1
let g:vimtex_cache_root = getcwd()

let $TEXINPUTS = 'pgf/text-en:pgf/images'

" call vimtex#profile#start()
silent let s:time = str2float(system('date +"%s.%N"'))
silent edit pgf/version-for-pdftex/en/pgfmanual.tex
echo 'Time elapsed (1st run):' str2float(system('date +"%s.%N"')) - s:time "\n"
" call vimtex#profile#stop()
" call rename('prof.log', 'prof_before.log')


bwipeout
" call vimtex#profile#start()
let s:time = str2float(system('date +"%s.%N"'))
silent edit pgf/version-for-pdftex/en/pgfmanual.tex
echo 'Time elapsed (2nd run):' str2float(system('date +"%s.%N"')) - s:time "\n"
" call vimtex#profile#stop()
" call rename('prof.log', 'prof_after.log')

bwipeout
let s:time = str2float(system('date +"%s.%N"'))
silent edit pgf/version-for-pdftex/en/pgfmanual.tex
echo 'Time elapsed (3rd run):' str2float(system('date +"%s.%N"')) - s:time "\n"

quitall!
