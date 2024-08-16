function Ltrim2(list) abort
  let l:str = trim(a:list[0])
  echo l:str
  echo strchars(l:str)
  let l:after = ''
  let l:len_str = strchars(l:str)
  if strcharpart(l:str,0,1) == "'"
    let l:start = 1
  else
    let l:start = 0
  endif
  if strcharpart(l:str,l:len_str - 1,1) == "'"
    let l:length = l:len_str - l:start - 1
  else
    let l:length = l:len_str - l:start
  endif
  let l:after = strcharpart(l:str,l:start,l:length)

  echo l:after
  echo strchars(l:after)
  let l:list = a:list
  let l:list[0] = l:after
endfunc
let s:list = ["''ab'あいうcdeえお''"]
call Ltrim2(s:list)
echo s:list[0]
echo strchars(s:list[0])

