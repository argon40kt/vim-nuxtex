function Getchar(str,idx) abort
  return strcharpart(a:str,a:idx,1)
endfunc
function Ltrim(list) abort
  let l:str = a:list[0]
  echo l:str
  echo strchars(l:str)
  let l:after = ''
  let l:len_str = strchars(l:str) - 1
  let l:k = 0
  while l:k <= l:len_str
    if (l:k == 0 || l:k == l:len_str) && Getchar(l:str,l:k) == "'"
    else
      let l:after .= Getchar(l:str,l:k)
    endif
  let l:k += 1
  endwhile

  echo l:after
  echo strchars(l:after)
  let l:list = a:list
  let l:list[0] = l:after
endfunc
let s:list = ["''ab'あいうcdeえお'"]
call Ltrim(s:list)
echo s:list[0]
echo strchars(s:list[0])

