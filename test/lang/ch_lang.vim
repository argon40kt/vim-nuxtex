
let g:old_lang=$LANG
function LANG_SAVE()
	let g:old_lang=$LANG
	let $LANG='en_US.UTF-8'
endfunc

augroup ch_lang
  au!
  au QuickFixCmdPre make call LANG_SAVE()
  au QuickFixCmdPost make let $LANG=g:old_lang
augroup END

