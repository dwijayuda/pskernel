import assert from 'node:assert/strict';
import { test } from 'node:test';
import { interfaceAndWitArtifacts, decodeInterfaceIrArtifact } from './interface-ir-artifact.mjs';

const encoded = '["psc-interface-ir-json/1","psc-foreign-interface/1","fixture","storage","client",[["storage-api",[["file",["resource"]],["error",["enum",["missing","denied"]]],["metadata",["record",[["size",["scalar","u64"]]]]],["event",["variant",[["closed",["none"]],["opened",["some",["named","metadata"]]]]]]],[["read",[["handle",["borrow","file"]]],["some",["result",["some",["list",["scalar","u8"]]],["some",["named","error"]]]],false,["component-model","javascript"]]],[],["storage"]]],["storage-api"],[]]';
const wit = `package %fixture:%storage;

interface %storage-api {
  resource %file;
  enum %error { %missing, %denied }
  record %metadata { %size: u64 }
  variant %event { %closed, %opened(%metadata) }
  %read: func(%handle: borrow<%file>) -> result<list<u8>, %error>;
}

world %client {
  import %storage-api;
}
`;

test('canonical InterfaceIR independently reproduces the portable WIT world', () => {
  const result = interfaceAndWitArtifacts(Buffer.from(encoded), Buffer.from(wit));
  assert.equal(result.world.name, 'client');
  assert.equal(result.world.interfaces[0].functions[0].parameters[0].type.tag, 'borrow');
  assert.equal(result.interface.identity.contract, 'psc-interface-ir-json/1');
  assert.equal(result.wit.identity.contract, 'psc-wit-world/1');
  const relation = JSON.parse(result.relation.bytes);
  assert.equal(relation.relation, 'psc-interface-ir-wit-rendering/1');
  assert.equal(relation.runtimeBehavior, 'not-established');
  assert.equal(relation.canonicalAbi, 'not-established');
});

test('InterfaceIR decoder rejects namespace injection and WIT drift', () => {
  assert.throws(() => decodeInterfaceIrArtifact(Buffer.from(encoded.replace('"client"','"bad;world"'))), /NAME/);
  assert.throws(() => interfaceAndWitArtifacts(Buffer.from(encoded), Buffer.from(wit.replace('borrow<%file>','%file'))), /WIT_RELATION/);
});
