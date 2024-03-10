let g:str = '\n'
let g:str2 = '&'
echo g:str |
echo substitute('abc', 'b', '\\n', '') |
echo substitute('abc', 'b', '\=g:str', '') |
echo g:str2 |
echo substitute('abc', 'b', '\&', '') |
echo substitute('abc', 'b', '\=g:str2', '')
echo substitute('a/b/c', '/', '\', 'g')
echo substitute('a/b/c', '/', '\\', 'g')
