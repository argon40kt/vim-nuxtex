
function! s:is_str_equal(str, pattern) abort
  let l:list = matchstrpos(a:str, a:pattern)
  return (!l:list[1]) && (l:list[2] == len(a:str))
endfunc

echo s:is_str_equal('', '\s\+')
