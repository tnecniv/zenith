import * as CodeMirror from 'codemirror';
import * as fs from 'fs';

interface Column {
  newWindow(content?: string): void;
}

class SimpleColumn {
  el: HTMLDivElement;

  constructor() {
    this.el = document.createElement('div');
    this.el.className = 'column';

    this.el.appendChild(new ColumnControl(this).el);
  }

  newWindow(content) {
    this.el.appendChild(new Window(content).el);
  }
}

class ColumnControl {
  el: HTMLDivElement;

  constructor(column: Column) {
    this.el = document.createElement('div');
    this.el.className = 'column-control';

    const newWindowButton = document.createElement('button');
    newWindowButton.innerText = 'New';
    newWindowButton.onclick = () => column.newWindow();

    this.el.appendChild(newWindowButton);
  }
}

class Window {
  el: HTMLDivElement;

  constructor(content = '') {
    this.el = document.createElement('div');
    this.el.className = 'window';

    const cm = CodeMirror(this.el, { lineNumbers: true });
    cm.setValue(content);
  }
}

const column = new SimpleColumn();
document.getElementById('container').appendChild(column.el);

fs.readdir(process.env.HOME, function(err, files) {
  if (err) alert('Could not read home folder.');

  column.newWindow(files.join('\n'));
});
