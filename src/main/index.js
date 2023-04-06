import path from 'path';
import url from 'url';
import {
  app, BrowserWindow, ipcMain, shell,
} from 'electron';
import { ElectronAPI as API } from 'api/electron.js';

let mainWindow = null;

const createWindow = async () => {
  // NOTE: any use of dirname will fail windows
  const RESOURCES_PATH = app.isPackaged
    ? path.join(process.resourcesPath, 'app/.webpack/renderer/public')
    : path.join(process.resourcesPath, '../../../../../../src/main/');

  const getAssetPath = (...paths) => path.join(RESOURCES_PATH, ...paths);

  mainWindow = new BrowserWindow({
    show: false,
    width: 1024,
    height: 728,
    icon: getAssetPath('icon'),
    webPreferences: {
      preload: getAssetPath('preload.js'),
      contextIsolation: true,
    },
  });

  // eslint-disable-next-line
  mainWindow.loadURL(MAIN_WINDOW_WEBPACK_ENTRY);

  mainWindow.on('ready-to-show', () => {
    if (!mainWindow) {
      throw new Error('"mainWindow" is not defined');
    }
    if (process.env.START_MINIMIZED) {
      mainWindow.minimize();
    } else {
      mainWindow.show();
    }
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // Open urls in the user's browser
  mainWindow.webContents.setWindowOpenHandler((edata) => {
    shell.openExternal(edata.url);

    return { action: 'deny' };
  });
};

/**
 * Add event listeners...
 */

app.on('window-all-closed', () => {
  // Respect the OSX convention of having the application in memory even
  // after all windows have been closed
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app
  .whenReady()
  .then(() => {
    ipcMain.handle(
      'foo',
      async (_event, param) => (new API()).foo(param),
    );

    createWindow();
  })
  .catch(console.log);

app.on('activate', () => {
  if (mainWindow === null) createWindow();
});
