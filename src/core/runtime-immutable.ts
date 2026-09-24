const deeplyFrozenKernelValues=new WeakSet<object>();

/**
 * Enforce the runtime immutability promised by the public readonly kernel data
 * types. Lean Expr/Level/Name values are physically immutable; the TypeScript
 * port must preserve that invariant because checker caches are identity-based.
 *
 * The traversal is iterative because real Lean expression/level graphs can be
 * much deeper than the JavaScript call stack.
 */
export function deepFreezeKernelValue<T>(value:T):T{
  const todo:unknown[]=[value];
  while(todo.length){
    const x=todo.pop();
    if(x===null||(typeof x!=='object'&&typeof x!=='function'))continue;
    const o=x as object;
    if(deeplyFrozenKernelValues.has(o))continue;
    // Register before scheduling children so cycles and shared DAGs are safe.
    deeplyFrozenKernelValues.add(o);
    for(const key of Reflect.ownKeys(o)){
      const d=Object.getOwnPropertyDescriptor(o,key);
      if(d&&'value' in d)todo.push(d.value);
    }
    Object.freeze(o);
  }
  return value;
}
