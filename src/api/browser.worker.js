const bar = (param) => new Promise((res, rej) => {
  const channel = new MessageChannel();

  channel.port1.onmessage = ({ data }) => {
    channel.port1.close();

    if (data.error) {
      rej(data.error);
    } else {
      res(data.result);
    }
  };

  postMessage({ action: 'bar' }, [channel.port2]);
});

async function foo(message) {
  try {
    let result;

    const { param } = message.data

    const callbackResult = await bar(param);

    message.ports[0].postMessage({ result: `called function 'foo' in browser worker with param ${param} and call to ${callbackResult}` });
  } catch (e) {
    message.ports[0].postMessage({ error: e });
  }
}

onmessage = async (message) => {
  if (message.data.action === 'foo') {
    await foo(message);
  }
};
