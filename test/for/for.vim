
function! s:remove_empty(list) abort
  let l:in = deepcopy(a:list)
  let l:out = a:list
  let l:len = len(l:out)
  if l:len > 0
    call remove(l:out, 0, l:len - 1)
  else
    return
  endif
  for i in l:in
    if i != ''
      let l:out += [i]
    endif
  endfor
endfunc

let s:list = ['abc', '', 'def']
call s:remove_empty(s:list)
echo s:list

