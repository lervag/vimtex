function! vimtex#doc#handlers#texdoc(context) abort " {{{1
  call vimtex#doc#make_selection(a:context)

  if !empty(a:context.selected)
    call vimtex#jobs#run('texdoc --nointeract -l ' . a:context.selected)
    if v:shell_error == 0
      call vimtex#jobs#start('texdoc ' . a:context.selected)
      return 1
    endif
  endif

  return 0
endfunction

" }}}1
