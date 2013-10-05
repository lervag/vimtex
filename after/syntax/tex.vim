" Add support for cleverref package (`\cref` and `\Cref`)
syn region texRefZone matchgroup=texStatement
      \ start="\\\(c\|C\)ref{"
      \ end="}\|%stopzone\>"
      \ contains=@texRefGroup
