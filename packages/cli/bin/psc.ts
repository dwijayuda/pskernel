#!/usr/bin/env node
import {runPsc} from '../src/psc.js';
process.exitCode=await runPsc(process.argv.slice(2));
