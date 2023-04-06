import fs from 'fs';
import path from 'path';
import { workerData, parentPort } from 'worker_threads';

async function bar(param) {
  return `electron function 'bar'`
}

async function foo() {
  const { param } = workerData;

  const callResult = await bar(param)

  parentPort.postMessage(`called function 'foo' in electron worker with param ${param} and call to ${callResult}`);
}

async function run() {
  const { msg } = workerData;

  switch (msg) {
    case 'foo':
      return foo();

    default:
      // do nothing
      return undefined;
  }
}

run();
