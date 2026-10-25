"""Exact-source qualification of a positive unary application congruence shortcut."""
import argparse
import hashlib
import importlib.util
import io
import json
import os
import pathlib
import re
import shutil
import signal
import subprocess
import sys
import time
import zipfile

BASE = 'dbd9db47bd8ef184583bcd5ae3feb38f3ce612c5'
TREE = '2b0f061ef9e211df46b6dda8266b4b975823fab7'
PROD = 'psc1/packages/pskernel-core/src'
DELTA = ["psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagAdmission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagQuotAdmission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Quot/Admission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/FullShape.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/UnarySpines.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Transform.lean"]
PINS = {"psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/FullShape.lean":{"bytes":20939,"sha256":"bd66aa2e8cc039406b76d8e24459d3d9107e579c7e17ed5432cf192b38e3e2d2"},"psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/UnarySpines.lean":{"bytes":3754,"sha256":"0a5eb430466bff2fa3f3f00384b5ac7f22dc62bbc0505429ca52494259a8e26e"},"psc1/test/PsKernelUnarySpineProofs.lean":{"bytes":11532,"sha256":"4098607f1b2d5874f998d69bb732ab9150a5031c1ab584e4e524b23d0a6340c2"},"psc1/test/PsKernelChurchSource.lean":{"bytes":21080,"sha256":"5f723e4b184c9134128552fe8186064dd0b291a42e54ecc575d210d339dd0a30"},"psc1/test/PsKernelChurchStageProbe.lean":{"bytes":6043,"sha256":"3601231d19268d33474697a2058a7ada58918ce5a8d11b56da263b4377e41a32"},"psc1/scripts/pskernel-unary-spine-smoke.mjs":{"bytes":5583,"sha256":"9053a5bfc66687c7d1529c6f18179bfb97ced1e41ac0dd3d24ae039d60612d2b"},"psc1/scripts/pskernel-church-fixture.py":{"bytes":5437,"sha256":"9053ae13a6df9fd542ab9f76177f4daea4835fa68c661b1d1c1b446c06608ddf"},"psc1/scripts/pskernel-church-stages.mjs":{"bytes":4798,"sha256":"d008052b8bb6ecab9c0b0fc5c7c43a2de66304da03e34016c0396cfee947f11d"}}
ROOT = pathlib.Path(__file__).resolve().parents[1]
REPO = ROOT.parent
INPUT_SHA = '443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1'
BODY_SHA = '85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47'
ARCHIVE_SHA = '98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d'

def require(ok, message):
    if not ok: raise RuntimeError(message)

def digest(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}

def write(path, value):
    path.write_text(json.dumps(value,indent=2)+'\n')

def git(*args):
    return subprocess.check_output(['git',*args],cwd=REPO)

def identity():
    return {key:os.environ[value] for key,value in
        [('sourceSha','GITHUB_SHA'),('runId','GITHUB_RUN_ID'),('runAttempt','GITHUB_RUN_ATTEMPT')]}

def authenticate(out):
    out.mkdir(parents=True,exist_ok=True)
    require(git('rev-parse','HEAD').decode().strip()==identity()['sourceSha'],'Exact checkout')
    require(git('rev-parse','HEAD:'+PROD).decode().strip()==TREE,'Exact production tree')
    require(git('diff','--name-only',BASE,'HEAD','--',PROD).decode().splitlines()==DELTA,'Exact retained unary and additional lazy-transform production delta')
    require(git('rev-parse',BASE+':'+PROD).decode().strip()=='e567685e5c441a5b0a78d8241f7bae151b48b5ca','Qualified baseline tree')
    paths=list(PINS)+[
        'psc1/scripts/pskernel-transform-lazy-qualification.py','psc1/test/PsKernelTransformLazyProofs.lean',
        'psc1/scripts/pskernel-unary-spine-qualification.py',
        '.github/workflows/psc1-pskernel-t05-header.yml',
        'psc1/scripts/pskernel-validator-qualification.py',
        'psc1/scripts/pskernel-arena-replay.mjs',
        'psc1/scripts/pskernel-arena435-oracle.py',
        'psc1/kernel-lakefile.lean','psc1/lean-toolchain']
    rows=[]
    for name in paths:
        raw=(REPO/name).read_bytes()
        require(raw==git('show','HEAD:'+name),'Worktree/Git identity: '+name)
        if name in PINS: require(digest(raw)==PINS[name],'Reviewed source pin: '+name)
        target=out/'sources'/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(raw)
        rows.append({'path':name,**digest(raw)})
    source={'schema':'psc1-unary-source-v1',**identity(),'productionTree':TREE,
        'baselineSource':BASE,'baselineProductionTree':'e567685e5c441a5b0a78d8241f7bae151b48b5ca',
        'productionChanges':DELTA,'files':rows,'fuel':4096}
    write(out/'source-inventory.json',source)
    return source

def bounded(out,label,command,cwd):
    stdout=out/(label+'.stdout');stderr=out/(label+'.stderr')
    timing=out/(label+'.time');started=time.monotonic()
    with stdout.open('wb') as so,stderr.open('wb') as se:
        process=subprocess.Popen(['/usr/bin/time','-f','peak_rss_kib=%M wall_seconds=%e exit_status=%x',
            '-o',str(timing)]+command,cwd=cwd,env=dict(os.environ,PATH='',NODE_OPTIONS=''),
            stdout=so,stderr=se,start_new_session=True)
        try:status=process.wait(timeout=60)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid,signal.SIGKILL);process.wait()
            write(out/(label+'.status.json'),{'timedOut':True,'seconds':time.monotonic()-started})
            raise RuntimeError('Unchanged60-second limit: '+label)
    write(out/(label+'.status.json'),{'timedOut':False,'exitCode':status,'seconds':time.monotonic()-started})
    require(status==0,'Actual process exit0: '+label)
    return stdout.read_text()

def church_input(out):
    archive=out/'arena.tar.gz'
    subprocess.run(['curl','-fL','--retry','3','--retry-delay','2','-o',str(archive),
        'https://github.com/leanprover/lean-kernel-arena/releases/download/round-2026-09/lean-arena-round-2026-09-tests.tar.gz'],check=True)
    raw=archive.read_bytes()
    require(digest(raw)=={'bytes':3497743,'sha256':ARCHIVE_SHA},'Original pinned corpus')
    spec=importlib.util.spec_from_file_location('oracle',ROOT/'scripts/pskernel-arena435-oracle.py')
    oracle=importlib.util.module_from_spec(spec);spec.loader.exec_module(oracle)
    case,=[row for row in oracle.read_archive(archive) if row[1]=='perf/church-numerals.ndjson']
    data,provenance=oracle.adapt_header(case[2])
    require(hashlib.sha256(data).hexdigest()==INPUT_SHA and
        hashlib.sha256(data.partition(b'\n')[2]).hexdigest()==BODY_SHA,'Original Church body, header-only adaptation')
    (out/'input.ndjson').write_bytes(data);write(out/'input-provenance.json',provenance)
    subprocess.run([sys.executable,str(ROOT/'scripts/pskernel-church-fixture.py'),
        str(out/'input.ndjson'),str(ROOT/'test/PsKernelChurchSource.lean'),'--verify'],check=True)

def parse_church(text,runtime,mode):
    marker='PSC1_ARENA_REPLAY ' if runtime!='native' and mode=='baseline' else 'PSC1_CHURCH_RESULT '
    rows=[json.loads(line[len(marker):]) for line in text.splitlines() if line.startswith(marker)]
    require(len(rows)==1 and rows[0]['verdict']=='accepted','Authentic Church accepted: '+runtime+'/'+mode)
    if mode=='stages':
        stages=[json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_STAGE ')]
        require([s['stage'] for s in stages]==['header','is-prop','body-static','body-check','final-defeq']
            and all(s['status']=='ok' for s in stages),'Every actual production stage accepted')
        prefix,=[json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_PREFIX ')]
        require({k:str(v) for k,v in prefix.items()}=={'requests':'3','sourceNodes':'197','ownedNodes':'249','declarations':'5'},'Actual independent prefix/owner')
    return rows[0]

def native(out):
    source=authenticate(out)
    retained=json.loads((out.parent/'validator/native-receipt.json').read_text())
    require(retained['status']=='pass' and retained['totalProofs']==532 and
        all(retained[k]==v for k,v in identity().items()),'Same-source532 retained reports')
    proof=ROOT/'test/PsKernelUnarySpineProofs.lean'
    names=re.findall(r'(?m)^#print axioms (\S+)\s*$',proof.read_text())
    require(len(names)==len(set(names))==9,'Nine reviewed universal statements')
    with (out/'proof.log').open('w') as handle:
        status=subprocess.run(['lake','-f','kernel-lakefile.lean','env','lean','--root=test',
            '-o','.lake/build/lib/lean/PsKernelUnarySpineProofs.olean','test/PsKernelUnarySpineProofs.lean'],
            cwd=ROOT,stdout=handle,stderr=subprocess.STDOUT).returncode
    log=(out/'proof.log').read_text();print(log,flush=True)
    reports=re.findall(r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)",log)
    require(status==0 and [n for n,_ in reports]==names,'Nine actual ordered successful axiom reports')
    require(not any(t in log for t in ['sorryAx','Lean.ofReduceBool','Lean.trustCompiler']),'No proof escape dependency')
    for _,used in reports:
        require({a.strip() for a in used.split(',') if a.strip()}<={'propext','Classical.choice','Quot.sound'},'Allowed standard axioms only')
    church_input(out)
    original=(ROOT/'kernel-lakefile.lean').read_text()
    config=original+'''
lean_lib PsKernelChurchLiteralSource where
  srcDir := "test"
  roots := #[`PsKernelChurchSource]

lean_exe psc1_kernel_church_stages where
  srcDir := "test"
  root := `PsKernelChurchStageProbe
'''
    (ROOT/'.unary-spine-lakefile.lean').write_text(config)
    (out/'native-lakefile.lean').write_text(config)
    with (out/'native-build.log').open('w') as handle:
        subprocess.run(['lake','-f','.unary-spine-lakefile.lean','build','psc1_kernel_church_stages'],
            cwd=ROOT,stdout=handle,stderr=subprocess.STDOUT,check=True)
    executable=str(ROOT/'.lake/build/bin/psc1_kernel_church_stages')
    results={mode:parse_church(bounded(out,'church-native-'+mode,[executable,mode],out),'native',mode)
        for mode in ['baseline','stages']}
    old_names=[n for row in retained['proofs'] for n in row['names']]
    require(len(set(old_names+names))==len(old_names+names)==541,'541 unique actual reports')
    receipt={'schema':'psc1-unary-native-v1',**identity(),'status':'pass','productionTree':TREE,
        'retainedProofs':532,'newProofs':9,'totalProofs':541,'proofModules':37,'names':names,
        'newProofSource':digest(proof.read_bytes()),'newProofLog':digest((out/'proof.log').read_bytes()),
        'retainedReceipt':digest((out.parent/'validator/native-receipt.json').read_bytes()),
        'sourceInventory':digest((out/'source-inventory.json').read_bytes()),
        'church':results,'fuel':4096,'fullKernel':False,'performanceQualified':False}
    write(out/'native-receipt.json',receipt)
    print('PSC1_UNARY_NATIVE541: PASS '+json.dumps(receipt,separators=(',',':')))

def route(out,native_root,node):
    source=authenticate(out)
    native_dir=native_root/'unary'
    proof=json.loads((native_dir/'native-receipt.json').read_text())
    require(proof['status']=='pass' and proof['totalProofs']==541 and proof['productionTree']==TREE
        and all(proof[k]==v for k,v in identity().items()),'Same-source native541 qualification')
    require(digest((native_dir/'source-inventory.json').read_bytes())==proof['sourceInventory']
        and digest((native_dir/'proof.log').read_bytes())==proof['newProofLog'],'Actual native sources/reports bound')
    for row in json.loads((native_dir/'source-inventory.json').read_text())['files']:
        raw=(native_dir/'sources'/row['path']).read_bytes()
        require(digest(raw)=={'bytes':row['bytes'],'sha256':row['sha256']} and raw==(REPO/row['path']).read_bytes(),'Native/runtime source equality')
    for name in ['native-receipt.json','proof.log','input.ndjson','input-provenance.json']:
        shutil.copyfile(native_dir/name,out/('native-'+name))
    data=(native_dir/'input.ndjson').read_bytes()
    require(hashlib.sha256(data).hexdigest()==INPUT_SHA and
        hashlib.sha256(data.partition(b'\n')[2]).hexdigest()==BODY_SHA,'Actual native/runtime same original body')
    detached=out.parent/'detached';kernel=detached/'kernel.mjs'
    provenance=json.loads((out.parent/'provenance.json').read_text())
    require(provenance['sourceSha']==identity()['sourceSha'] and provenance['kernel']==digest(kernel.read_bytes())
        and provenance['fuel']==4096 and provenance['oldSpaceMiB']==2048 and provenance['emptyPATH'] is True,'Complete authentic generated kernel and unchanged resources')
    shutil.copyfile(ROOT/'scripts/pskernel-unary-spine-smoke.mjs',detached/'pskernel-unary-spine-smoke.mjs')
    text=bounded(out,'unary-controls',[node,'--max-old-space-size=2048','pskernel-unary-spine-smoke.mjs','kernel.mjs'],detached)
    labels=[line.split(' ',1)[1] for line in text.splitlines() if line.startswith('PSC1_UNARY_SPINE_ASSERT ')]
    marker='PSC1_UNARY_SPINE_JS: PASS '
    summary,=[json.loads(line[len(marker):]) for line in text.splitlines() if line.startswith(marker)]
    require(summary['assertions']==len(labels)==len(set(labels))==20 and summary['labels']==labels,'Twenty actual distinct runtime controls')
    for name in ['pskernel-arena-replay.mjs','pskernel-church-stages.mjs']:
        shutil.copyfile(ROOT/'scripts'/name,detached/name)
    (detached/'church-input.ndjson').write_bytes(data)
    driver=(ROOT/'scripts/pskernel-arena-replay.mjs').read_text()
    anchor="    const result=accepted(get('psKernelV1RunDag')(session,nil,S.safe,arena,list(commands)),'kernel-admission');"
    require(driver.count(anchor)==1,'Exact admission boundary')
    transport="import {runChurchStages} from './pskernel-church-stages.mjs';\n"+driver.replace(anchor,
        "    return runChurchStages(kernel,{arena,commands,session,nil,safety:S.safe,list,array,request:order[3].request});")
    (detached/'church-diagnostic-transport.mjs').write_text(transport)
    (detached/'church-staged-runner.mjs').write_text("import {readFileSync} from 'node:fs';\nimport * as kernel from './kernel.mjs';\nimport {replayText} from './church-diagnostic-transport.mjs';\nreplayText(kernel,readFileSync('church-input.ndjson','utf8'));\n")
    commands={'baseline':[node,'--max-old-space-size=2048','pskernel-arena-replay.mjs','kernel.mjs','church-input.ndjson'],
        'stages':[node,'--max-old-space-size=2048','church-staged-runner.mjs']}
    results={mode:parse_church(bounded(out,'church-'+mode,command,detached),provenance['route'],mode)
        for mode,command in commands.items()}
    retained=json.loads((out.parent/'validator/route-receipt.json').read_text())
    require(retained['status']=='pass' and retained['nativeProofs']==532,'Complete retained runtime route')
    receipt={'schema':'psc1-unary-route-v1',**identity(),'status':'pass','route':provenance['route'],
        'productionTree':TREE,'nativeProofs':541,'newRuntimeControls':summary,'church':results,
        'kernel':digest(kernel.read_bytes()),'retainedReceipt':digest((out.parent/'validator/route-receipt.json').read_bytes()),
        'nativeReceipt':digest((native_dir/'native-receipt.json').read_bytes()),
        'sourceInventory':digest((out/'source-inventory.json').read_bytes()),
        'fuel':4096,'processLimitSeconds':60,'oldSpaceMiB':2048,'emptyPATH':True,
        'fullKernel':False,'performanceQualified':False}
    write(out/'route-receipt.json',receipt)
    print('PSC1_UNARY_ROUTE541: PASS '+json.dumps(receipt,separators=(',',':')))

if __name__=='__main__':
    require(os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','GitHub Linux only')
    parser=argparse.ArgumentParser();parser.add_argument('command',choices=['source','native','route'])
    parser.add_argument('--out',type=pathlib.Path,required=True);parser.add_argument('--native-root',type=pathlib.Path);parser.add_argument('--node')
    args=parser.parse_args();out=args.out.resolve()
    if args.command=='source':authenticate(out)
    elif args.command=='native':native(out)
    else:route(out,args.native_root.resolve(),args.node)
