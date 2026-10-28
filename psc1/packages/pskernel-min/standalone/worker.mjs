import {parentPort,workerData} from 'node:worker_threads';
import {checkBytes} from './index.mjs';
parentPort.postMessage(checkBytes(workerData));
