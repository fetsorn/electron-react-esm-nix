// cannot use esm because loads raw as cjs by absolute path
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electron', {
  foo: (param) => ipcRenderer.invoke('foo', param),
});
