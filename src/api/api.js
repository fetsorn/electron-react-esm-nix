import { BrowserAPI } from './browser.js';

export class API {
  #browser;

  constructor() {
    this.#browser = new BrowserAPI();
  }

  async foo(param) {
    // eslint-disable-next-line
    switch (__BUILD_MODE__) {
      case 'electron':
        return window.electron.foo(param);

      default:
        return this.#browser.foo(param);
    }
  }
}
