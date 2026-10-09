import { answer } from './Main.js';

const result: bigint = answer;
if (result !== 42n) throw new Error('Unexpected compiled answer');
console.log('ProofScript answer:', result.toString());
