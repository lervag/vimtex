set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

let g:vimtex_view_automatic = 0

if has('nvim')
  let g:vimtex_compiler_progname = 'nvr'
endif

function! RunTests(comp, list_opts)
  if !executable(a:comp)
    echo 'Warning! "' . a:comp . '" was not executable!'
    echo "Compiler tests could not run!\n\n"
    return
  endif

  let g:vimtex_compiler_method = a:comp

  for l:opts in a:list_opts
    let g:vimtex_compiler_{a:comp} = l:opts

    echo 'Testing compiler "' . a:comp . '" with options:'
    for [l:key, l:val] in items(l:opts)
      echo '* ' . l:key . ' =' l:val
    endfor

    silent edit minimal.tex

    " Check if the compiler was loaded
    if !has_key(b:vimtex, 'compiler')
      echo "Compiler failed to load!\n"
      cquit
    endif

    silent call vimtex#compiler#compile()

    " Check if continuous mode is active
    if get(b:vimtex.compiler, 'continuous')
      if !b:vimtex.compiler.get_pid()
        echo "Could not get PID for compiler\n"
        cquit
      endif

      sleep 900m
      silent call vimtex#compiler#stop()
      sleep 200m
    endif

    " Check that the PDF has been built
    if empty(b:vimtex.out())
      echo "PDF was not built properly\n"
      cquit
    endif

    silent call vimtex#compiler#clean(1)
    sleep 700m

    if !empty(b:vimtex.out()) || !empty(b:vimtex.aux())
      echo "VimtexClean failed!\n"
      cquit
    endif

    if !empty(get(l:opts, 'build_dir', ''))
      call delete(l:opts.build_dir, 'rf')
    endif

    echo "\n"
    bwipeout
  endfor
endfunction

for [s:comp, s:opts] in items({
      \ 'latexmk' : [
      \   {'backend' : 'process', 'build_dir' : 'out'},
      \   {'callback' : 0},
      \   {'callback' : 0, 'background' : 0},
      \   {'callback' : 0, 'continuous' : 0},
      \   {'background' : 0, 'continuous' : 0},
      \ ],
      \ 'latexrun' : [
      \   {'backend' : 'process', 'build_dir' : 'out'},
      \   {'background' : 0},
      \ ],
      \})
  call RunTests(s:comp, s:opts)
endfor

quitall!
