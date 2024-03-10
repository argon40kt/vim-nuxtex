
if exists("b:did_nuxtex")
	finish
endif
let b:did_nuxtex = 1

let s:save_cpo = &cpo
setlocal cpo&vim

command! -buffer NuxtexFwd call nuxtex#fwd#jump_to_pdf()
command! -buffer NuxtexChkFwdCmd call nuxtex#fwd#check_to_pdf()

if !hasmapto('<Plug>NuxtexFwdSearch')
	map <unique><buffer><nowait> <localleader><localleader>nf <Plug>NuxtexFwdSearch
endif
noremap <silent><unique><buffer> <Plug>NuxtexFwdSearch :call nuxtex#fwd#jump_to_pdf()<CR>

"if !hasmapto('<Plug>SynctexFwdChk')
"	map <unique><buffer><nowait> <localleader>sc <Plug>SynctexFwdChk
"endif
"noremap <silent><unique><buffer> <Plug>SynctexFwdChk :call nuxtex#fwd#check_to_pdf()<CR>


let &cpo = s:save_cpo
unlet s:save_cpo
