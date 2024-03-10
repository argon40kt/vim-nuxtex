function! Test_status() dict
	let self['example'] = self.example + 1
	"let self.example = self.example + 1
	"echo self.example
endfunc
function! Test_mode() dict
	call self['base']['func']()
	echo self['base']['name'] . ': ' . self['base']['example']
endfunc
function! Test_start()
	let l:base = {'name': '', 'example': 0, 'func': function("Test_status"), 'list': []}
	let l:dict = {'name': '', 'base': deepcopy(l:base), 'func': function("Test_mode")}
	let l:input1 = deepcopy(l:dict)
	let l:input1['base']['name'] = 'input1'
	let l:input2 = deepcopy(l:dict)
	let l:input2['base']['name'] = 'input2'
	let l:input2['base']['example'] = 1
	for cnt in [0, 1, 2]
	  call l:input1['func']()
	  call l:input2['func']()
	endfor
endfunc
call Test_start()

