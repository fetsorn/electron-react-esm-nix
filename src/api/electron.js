import { Worker } from 'node:worker_threads';

let runningWorker;

// we run functions in workers to offload the main thread
// but UI only expects results from the last call to functions
// so we want only one instance of worker running at any time
// and we terminate the previous instance if worker is still running
async function runWorker(workerData) {
  if (workerData.msg === 'foo' && runningWorker !== undefined) {
    await runningWorker.terminate();

    runningWorker = undefined;
  }

  return new Promise((resolve, reject) => {
    const worker = new Worker(
      new URL('./electron.worker.js', import.meta.url),
      {
        workerData,
      },
    );

    worker.on('message', (message) => {
      if (typeof message === 'string' && message.startsWith('log')) {
        // uncomment to read logs from worker
        // console.log(message);
      } else {
        if (workerData.msg === 'foo') {
          runningWorker = undefined;
        }

        resolve(message);
      }
    });

    worker.on('error', reject);

    worker.on('exit', (code) => {
      if (workerData.msg === 'foo') {
        runningWorker = undefined;
      }

      if (code !== 0) { reject(new Error(`Worker stopped with exit code ${code}`)); }
    });

    if (workerData.msg === 'foo') {
      runningWorker = worker;
    }
  });
}

export class ElectronAPI {
  constructor() {
    //
  }

  async bar(param) {
    return `electron callback for ${param}`
  }

  async foo(param) {
    return runWorker({
      msg: 'foo',
      param,
    });
  }
}
