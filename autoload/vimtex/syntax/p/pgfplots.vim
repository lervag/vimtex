" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pgfplots#load() abort " 
  if has_key(b:vimtex_syntax, 'pgfplots') | return | endif
  let b:vimtex_syntax.pgfplots = 1

  call vimtex#syntax#p#tikz#load()

  syntax cluster texClusterTikz add=texCmdAxis

  syntax match texCmd nextgroup=texArgTikzset skipwhite "\\pgfplotsset\>"

  syntax match texCmdAxis contained nextgroup=texOptTikzpic skipwhite "\\addplot3\?\>"
  syntax match texCmdAxis contained nextgroup=texOptTikzpic skipwhite "\\nextgroupplot\>"

  syntax match texEnvBgnTikz contains=texCmdEnv nextgroup=texOptTikzpic skipwhite skipnl "\\begin{\%(log\)*axis}"
  syntax match texEnvBgnTikz contains=texCmdEnv nextgroup=texOptTikzpic skipwhite skipnl "\\begin{groupplot}"
  syntax region texRegionTikz
        \ start="\\begin{\z(\%(log\)*axis\)}" end="\\end{\z1}"
        \ keepend transparent contains=@texClusterTikz
  syntax region texRegionTikz
        \ start="\\begin{groupplot}" end="\\end{groupplot}"
        \ keepend transparent contains=@texClusterTikz

  highlight def link texCmdAxis texCmd
endfunction

" 
