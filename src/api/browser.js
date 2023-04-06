async function runWorker(bar, param) {
  const worker = new Worker(new URL('./browser.worker', import.meta.url));

  worker.onmessage = async (message) => {
    switch (message.data.action) {
      case 'bar': {
        try {
          const result = await bar()

          message.ports[0].postMessage({ result });
        } catch (e) {
          // safari cannot clone the error object, force to string
          message.ports[0].postMessage({ error: `${e}` });
        }

        break;
      }

      default:
        // do nothing
    }
  };

  return new Promise((res, rej) => {
    const channel = new MessageChannel();

    channel.port1.onmessage = ({ data }) => {
      channel.port1.close();

      if (data.error) {
        rej(data.error);
      } else {
        res(data.result);
      }
    };

    worker.postMessage(
      { action: 'foo', param },
      [channel.port2],
    );
  });
}

export class BrowserAPI {

  constructor() {
    //
  }

  async bar() {
    return `browser function 'bar'`
  }

  async foo(param) {
    return runWorker(this.bar.bind(this), param);
  }
}
