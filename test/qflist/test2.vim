function Test_status() dict
	let self['example'] = self.example + 1
	"let self.example = self.example + 1
	"echo self.example
endfunc
function Test_mode(input)
	let l:input = a:input
	"let l:input['example'] = l:input['example'] + 1
	"call l:input['base'].func()
	call l:input['base']['func']()
	echo l:input['base']['name'] . ': ' . l:input['base']['example']
endfunc
function Test_start()
	let l:base = {'name': '', 'example': 0, 'func': function("Test_status")}
	let l:dict = {'name': '', 'base': deepcopy(l:base)}
	let l:input1 = deepcopy(l:dict)
	let l:input1['base']['name'] = 'input1'
	let l:input2 = deepcopy(l:dict)
	let l:input2['base']['name'] = 'input2'
	let l:input2['base']['example'] = 1
	for cnt in [0, 1, 2]
	  call Test_mode(l:input1)
	  call Test_mode(l:input2)
	endfor
endfunc
call Test_start()

