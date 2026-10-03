"use strict";
const assert = require("node:assert/strict");
const { importDts } = require("./interface-ir-prototype.js");

const fixture = [
  "export interface User {",
  "  readonly id: bigint;",
  "  name?: string;",
  "}",
  "export declare function fetchUser(id: bigint): Promise<User>;",
  "export declare function greet(name: string): string;"
].join("\n");

const ir = importDts(fixture);
assert.equal(ir.version, 1);
assert.equal(ir.interfaces[0].name, "User");
assert.equal(ir.interfaces[0].fields[0].readonly, true);
assert.equal(ir.interfaces[0].fields[1].presence, "missing-or-undefined");
assert.equal(ir.functions[0].result.kind, "promise");
assert.equal(ir.functions[0].result.value.name, "User");
assert.throws(
  () => importDts("export type X<T> = T extends string ? number : boolean;"),
  /unsupported conditional/
);
console.log(JSON.stringify({status:"passed", interfaces:ir.interfaces.length, functions:ir.functions.length, rejectedAdvancedType:true}));
