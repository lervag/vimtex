syntax match TocHelpText /^.*: .*/
syntax match TocNum      /^\S\+\(\.\S\+\)\?\s*/           contained conceal
syntax match TocSec      /^\t.\+/
syntax match TocSec1     /^[^\.]\+\t.*/                   contains=secNum
syntax match TocSec2     /^\([^\.]\+\.\)\{1}[^\.]\+\t.*/  contains=secNum
syntax match TocSec3     /^\([^\.]\+\.\)\{2}[^\.]\+\t.*/  contains=secNum
syntax match TocSec4     /^\([^\.]\+\.\)\{3}[^\.]\+\t.*/  contains=secNum

highlight link TocHelpText helpVim
highlight link TocNum      Number
highlight link TocSec      Title
highlight link TocSec1     TocSec
highlight link TocSec2     Normal
highlight link TocSec3     NonText
highlight link TocSec4     Comment
