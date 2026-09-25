export const V061_BINARY_PRECEDENCE:ReadonlyMap<string,number>=new Map([
  ['||',1],['&&',2],['==',3],['!=',3],
  ['<',4],['<=',4],['>',4],['>=',4],
  ['+',5],['-',5],['*',6],['/',6],['%',6],
]);

export function v061BinaryPrecedence(operator:string):number|undefined {
  return V061_BINARY_PRECEDENCE.get(operator);
}

export function v061LeanSubsetBinaryPrecedence(operator:string):number|undefined {
  if(operator==='++')return 5;
  return v061BinaryPrecedence(operator);
}
