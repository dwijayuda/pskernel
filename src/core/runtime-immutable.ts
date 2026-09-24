const deeplyFrozenKernelValues=new WeakSet<object>();

/**
 * Enforce the runtime immutability promised by the public readonly kernel data
 * types. Lean Expr/Level/Name values are physically immutable; the TypeScript
 * port must preserve that invariant because checker caches are identity-based.
 */
export function deepFreezeKernelValue<T>(value:T):T{
  const visit=(x:unknown):void=>{
    if(x===null||(typeof x!=='object'&&typeof x!=='function'))return;
    const o=x as object;
    if(deeplyFrozenKernelValues.has(o))return;
    // Register before descent so hostile/cyclic metadata cannot recurse forever.
    deeplyFrozenKernelValues.add(o);
    for(const key of Reflect.ownKeys(o)){
      const d=Object.getOwnPropertyDescriptor(o,key);
      if(d&&'value' in d)visit(d.value);
    }
    Object.freeze(o);
  };
  visit(value);
  return value;
}
