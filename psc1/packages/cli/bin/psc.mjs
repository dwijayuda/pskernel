#!/usr/bin/env node
// Root npm bin, npm run psc, and the scoped CLI package all use the same native
// command model. Historical bootstrap launcher source is retained in legacy/cli;
// it is not a silent fallback or a qualified current self-host command.
import '../../../npm-cli/psc.js';
