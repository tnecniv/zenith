import * as CodeMirror from 'codemirror';

interface Column {
  newWindow(): void;
}

class SimpleColumn {
  el: HTMLDivElement;

  constructor() {
    this.el = document.createElement('div');
    this.el.className = 'column';

    this.el.appendChild(new ColumnControl(this).el);
    this.newWindow();
  }

  newWindow() {
    this.el.appendChild(new Window().el);
  }
}

class ColumnControl {
  el: HTMLDivElement;

  constructor(column: Column) {
    this.el = document.createElement('div');
    this.el.className = 'column-control';

    const newWindowButton = document.createElement('button');
    newWindowButton.innerText = 'New';
    newWindowButton.onclick = column.newWindow.bind(column);

    this.el.appendChild(newWindowButton);
  }
}

class Window {
  el: HTMLDivElement;

  constructor() {
    this.el = document.createElement('div');
    this.el.className = 'window';

    const cm = CodeMirror(this.el, { lineNumbers: true });
  }
}

document.getElementById('container').appendChild(new SimpleColumn().el);
