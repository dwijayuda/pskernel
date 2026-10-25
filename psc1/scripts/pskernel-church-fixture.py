"""Literal, fail-closed native transcription of the pinned authentic Church input."""
import hashlib
import json
import pathlib
import sys

INPUT_SHA = "443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1"
BODY_SHA = "85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47"


def native_source(raw):
    assert hashlib.sha256(raw).hexdigest() == INPUT_SHA
    assert hashlib.sha256(raw.partition(b"\n")[2]).hexdigest() == BODY_SHA
    records = [json.loads(line) for line in raw.splitlines()]
    assert len(records) == 227
    out = ['import Ps.KernelCore.SelfHost', '',
           '-- Literal transcription of the original authenticated Arena body.',
           '-- Elaboration depth only; checked kernel resources remain unchanged.',
           'set_option maxRecDepth 10000', '',
           'def psKernelChurchSource : Except String (PsKernelExprV2PagedArena × List PsKernelDagDeclarationRequest) := do',
           '  let n0 : PsKernelName := .anonymous',
           '  let u0 : PsKernelLevel := .zero',
           '  let a0 := psKernelExprV2PagedEmpty']
    names = {0}; levels = {0}; exprs = {}; requests = []; count = 0

    def n(value):
        assert value in names
        return 'n' + str(value)

    def u(value):
        assert value in levels
        return 'u' + str(value)

    def e(value):
        assert value in exprs
        return 'e' + str(value)

    def lst(values):
        return '[' + ', '.join(values) + ']'

    def base(value):
        return '(PsKernelDagConstantBase.mk ' + n(value['name']) + ' ' + lst(n(x) for x in value['levelParams']) + ' ' + e(value['type']) + ')'

    for record in records[1:]:
        if 'in' in record:
            idx = record['in']; assert idx not in names
            if 'str' in record:
                x = record['str']; value = '.str ' + n(x['pre']) + ' ' + json.dumps(x['str'], ensure_ascii=False)
            else:
                assert 'num' in record
                x = record['num']; value = '.num ' + n(x['pre']) + ' ' + str(x['i'])
            out.append('  let n' + str(idx) + ' : PsKernelName := ' + value); names.add(idx)
        elif 'il' in record:
            idx = record['il']; assert idx not in levels
            if 'param' in record: value = '.param ' + n(record['param'])
            elif 'succ' in record: value = '.succ ' + u(record['succ'])
            else: raise ValueError('Unexpected universe record')
            out.append('  let u' + str(idx) + ' : PsKernelLevel := ' + value); levels.add(idx)
        elif 'ie' in record:
            idx = record['ie']; assert idx not in exprs
            kind, = [key for key in record if key != 'ie']; x = record[kind]
            if kind == 'bvar': ctor, args = 'BVar', str(x)
            elif kind == 'sort': ctor, args = 'Sort', u(x)
            elif kind == 'const': ctor, args = 'Const', n(x['name']) + ' ' + lst(u(v) for v in x['us'])
            elif kind == 'app': ctor, args = 'App', e(x['fn']) + ' ' + e(x['arg'])
            elif kind in ['lam', 'forallE']:
                assert x['binderInfo'] in ['default', 'implicit', 'strictImplicit', 'instImplicit']
                ctor = 'Lam' if kind == 'lam' else 'Forall'
                args = n(x['name']) + ' ' + e(x['type']) + ' ' + e(x['body']) + ' .' + x['binderInfo']
            else: raise ValueError('Unexpected expression record: ' + kind)
            out += ['  let p' + str(count) + ' ← psKernelExprV2PagedMk' + ctor + ' a' + str(count) + ' ' + args,
                    '  let a' + str(count + 1) + ' := p' + str(count) + '.fst',
                    '  let e' + str(idx) + ' := p' + str(count) + '.snd']
            exprs[idx] = count; count += 1
        elif 'inductive' in record:
            x = record['inductive']; assert len(x['types']) == len(x['ctors']) == len(x['recs']) == 1
            t = x['types'][0]; c = x['ctors'][0]
            assert t['numNested'] == 0 and not t['isUnsafe'] and not c['isUnsafe']
            assert t['all'] == [t['name']] and t['ctors'] == [c['name']] and c['induct'] == t['name']
            value = '(.ordinaryInductive ' + lst(n(v) for v in t['levelParams']) + ' ' + str(t['numParams'])
            value += ' (PsKernelDagInductive.mk ' + n(t['name']) + ' ' + e(t['type'])
            value += ' [PsKernelDagConstructor.mk ' + n(c['name']) + ' ' + e(c['type']) + ']) false)'
            requests.append(value)
        elif 'def' in record:
            x = record['def']; assert x['safety'] == 'safe' and x['all'] == [x['name']]
            requests.append('(.definitionDecl (PsKernelDagDefinition.mk ' + base(x) + ' ' + e(x['value']) + ' (.regular ' + str(x['hints']['regular']) + ') .safe))')
        elif 'thm' in record:
            x = record['thm']; assert x['all'] == [x['name']]
            requests.append('(.theoremDecl ' + base(x) + ' ' + e(x['value']) + ')')
        else: raise ValueError('Unexpected declaration record')
    assert count == 197 and len(names) == 22 and len(levels) == 5 and len(requests) == 4
    out += ['  pure (a197, ' + lst(requests) + ')', '']
    return '\n'.join(out)


if __name__ == '__main__':
    raw = pathlib.Path(sys.argv[1]).read_bytes()
    result = native_source(raw)
    path = pathlib.Path(sys.argv[2])
    if len(sys.argv) == 4 and sys.argv[3] == '--verify':
        assert path.read_text() == result, 'Committed native fixture differs from original corpus transcription'
    else:
        path.write_text(result)
