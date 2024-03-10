let g:test_list = [0, 1, 2]
let g:test_dict = {'apple' : 1, 'orange' : 2, 'lemon': 3}
function Test_IO(test_list, test_dict)
	let l:test_list = a:test_list
	let l:test_dict = a:test_dict
	let l:test_list[0] = 3
	let l:test_dict['apple'] = 0
endfunc

for element in g:test_list
  echo element
endfor
for key in keys(g:test_dict)
  echo key
endfor
for [key, value] in items(g:test_dict)
  echo 'key = ' . key . ', value = ' . value
endfor
echo 'keys(g:test_dict) = ' | echo keys(g:test_dict)
call Test_IO(deepcopy(g:test_list), deepcopy(g:test_dict))
echo '(deep copied) g:test_list = ' . g:test_list[0]
echo '(deep copied) g:test_dict = ' . g:test_dict['apple']

call Test_IO(copy(g:test_list), copy(g:test_dict))
echo '(copied) g:test_list = ' . g:test_list[0]
echo '(copied) g:test_dict = ' . g:test_dict['apple']

call Test_IO(g:test_list, g:test_dict)
echo 'g:test_list = ' . g:test_list[0]
echo 'g:test_dict = ' . g:test_dict['apple']

