import { app, BrowserWindow } from 'electron';
declare var __dirname, process;

let win;

let createWindow = () => {
  win = new BrowserWindow({ width: 800, height: 900});
  win.loadURL(`file://${__dirname}/index.html`);
  win.on("closed", () => {
    win = null;
  });
}
app.on("ready", createWindow);
app.on("window-all-closed", () => {
  if(process.platform !== "darwin") {
    app.quit();
  }
});

app.on("activate", () => {
  if(win === null) createWindow();
});
