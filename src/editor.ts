import * as CodeMirror from 'codemirror';

CodeMirror.fromTextArea(document.getElementById('editor') as HTMLTextAreaElement, {
  lineNumbers: true
});
