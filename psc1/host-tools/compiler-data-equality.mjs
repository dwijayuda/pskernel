// Private generated compiler values are immutable, including their shared nodes.
// This is scheduling equality, never admission evidence. Distinct unsupported
// shapes, accessors, cycles or exhausted budgets conservatively disable reuse.
export function createCompilerDataEquality({ maxNodes = 1000000, maxMillis = 100 } = {}) {
  return function equal(left, right) {
    const deadline = performance.now() + maxMillis,
      stack = [{ left, right }],
      activeLeft = new Set(),
      activeRight = new Set();
    let nodes = 0;
    try {
      while (stack.length) {
        if (++nodes > maxNodes || (nodes % 256 === 0 && performance.now() > deadline)) return false;
        const item = stack.pop();
        if (item.exit) {
          activeLeft.delete(item.left);
          activeRight.delete(item.right);
          continue;
        }
        const a = item.left,
          b = item.right;
        // Identity is valid only under the private generated-data immutability contract.
        if (Object.is(a, b)) continue;
        if (a === null || b === null || typeof a !== 'object' || typeof b !== 'object')
          return false;
        const proto = Object.getPrototypeOf(a);
        if (
          proto !== Object.getPrototypeOf(b) ||
          ![null, Object.prototype, Array.prototype].includes(proto)
        )
          return false;
        if (Array.isArray(a) !== Array.isArray(b) || activeLeft.has(a) || activeRight.has(b))
          return false;
        const keys = Reflect.ownKeys(a),
          other = Reflect.ownKeys(b);
        if (keys.length !== other.length || keys.length > 8192) return false;
        activeLeft.add(a);
        activeRight.add(b);
        stack.push({ exit: true, left: a, right: b });
        for (let i = keys.length - 1; i >= 0; i--) {
          if (
            ++nodes > maxNodes ||
            (nodes % 256 === 0 && performance.now() > deadline) ||
            keys[i] !== other[i]
          )
            return false;
          const x = Object.getOwnPropertyDescriptor(a, keys[i]),
            y = Object.getOwnPropertyDescriptor(b, other[i]);
          if (
            !x ||
            !y ||
            !Object.hasOwn(x, 'value') ||
            !Object.hasOwn(y, 'value') ||
            x.enumerable !== y.enumerable ||
            x.configurable !== y.configurable ||
            x.writable !== y.writable
          )
            return false;
          stack.push({ left: x.value, right: y.value });
        }
      }
      return true;
    } catch {
      return false;
    }
  };
}
