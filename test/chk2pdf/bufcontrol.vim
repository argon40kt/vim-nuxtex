if !exists('g:bufnr')
  let g:bufnr = bufadd('')
elseif !bufexists(g:bufnr)
  let g:bufnr = bufadd('')
endif
call bufload(g:bufnr)
call deletebufline(g:bufnr,1,'$')
call appendbufline(g:bufnr,0,localtime())
if bufwinid(g:bufnr) < 0
  5split
  exec 'buf ' . g:bufnr
  set ro
endif
echo g:bufnr
