// Linux local ext4/XFS only: an executing inode with active write denial cannot
// change bytes through ordinary file writes. Recheck pathname/inode binding and
// ETXTBSY every use. No mtime acceptance; unsupported/permission-denied cases hash fresh.
// Linux references: fs/exec.c exe_file_deny_write_access; include/linux/fs.h i_writecount.
import fs from 'node:fs';
import crypto from 'node:crypto';
let captured;
const same = (a, b) => a.dev === b.dev && a.ino === b.ino && a.size === b.size;
function boundImage(file) {
  if (process.platform !== 'linux' || file !== process.execPath) return;
  try {
    const type = fs.statfsSync(file).type;
    if (type !== 0xef53 && type !== 0x58465342) return;
    const entry = fs.lstatSync(file),
      loaded = fs.statSync('/proc/self/exe');
    if (!entry.isFile() || entry.isSymbolicLink() || !same(entry, loaded)) return;
    // Open without O_TRUNC: a success never writes; it means no usable write-denial proof.
    let fd;
    try {
      fd = fs.openSync(file, fs.constants.O_WRONLY | fs.constants.O_NOFOLLOW);
      return;
    } catch (error) {
      if (error.code !== 'ETXTBSY') return;
    } finally {
      if (fd !== undefined) fs.closeSync(fd);
    }
    const after = fs.lstatSync(file);
    if (!same(entry, after) || !same(after, fs.statSync('/proc/self/exe'))) return;
    return after;
  } catch {
    return;
  }
}
export function runningExecutableIdentity(file) {
  const inode = boundImage(file);
  if (!inode) return;
  if (captured && same(captured.inode, inode)) return captured.record;
  const bytes = fs.readFileSync('/proc/self/exe');
  const after = boundImage(file);
  if (!after || !same(inode, after)) return;
  const record = Object.freeze({
    bytes: bytes.length,
    sha256: crypto.createHash('sha256').update(bytes).digest('hex'),
  });
  if (record.bytes !== inode.size) return;
  captured = { inode, record };
  return record;
}
