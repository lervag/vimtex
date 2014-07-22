" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

syntax match TocHelpText /^.*: .*/
syntax match TocNum      /^\(\S\+\(\.\S\+\)*\)\?\s*/ contained conceal
syntax match TocSec0     /^.*0$/                contains=TocNum,@Tex
syntax match TocSec1     /^.*1$/                contains=TocNum,@Tex
syntax match TocSec2     /^.*2$/                contains=TocNum,@Tex
syntax match TocSec3     /^.*3$/                contains=TocNum,@Tex
syntax match TocSec4     /^.*4$/                contains=TocNum,@Tex

highlight link TocHelpText helpVim
highlight link TocNum      Number
highlight link TocSec0     Title
highlight link TocSec1     Normal
highlight link TocSec2     helpVim
highlight link TocSec3     NonText
highlight link TocSec4     Comment
