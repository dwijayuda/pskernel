// Artifact transport only. Pins successful Linux G1 bytes before any import.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import crypto from 'node:crypto';
const request=JSON.parse(fs.readFileSync(process.argv[2]));
assert.equal(request.schema,'psc1-modular-selfhost-request/1');
assert.ok(['performance-240s','correctness-1800s'].includes(request.profile));
assert.match(request.seedCommit,/^[a-f0-9]{40}$/);assert.match(request.archiveSha256,/^[a-f0-9]{64}$/);
assert.ok(Number.isSafeInteger(request.runId)&&request.runId>0);
assert.ok(Number.isSafeInteger(request.artifactId)&&request.artifactId>0);
const repository='dwijayuda/pskernel';
assert.equal(process.env.GITHUB_REPOSITORY,repository);
const headers={Authorization:'Bearer '+process.env.GH_TOKEN,Accept:'application/vnd.github+json',
 'X-GitHub-Api-Version':'2022-11-28'};
async function api(route){
 const response=await fetch('https://api.github.com/repos/'+repository+route,{headers,signal:AbortSignal.timeout(120000)});
 assert.equal(response.status,200);return response.json();
}
const run=await api('/actions/runs/'+request.runId);
assert.equal(run.head_sha,request.seedCommit);assert.equal(run.conclusion,'success');
assert.equal(run.path,'.github/workflows/psc1-portable-modules.yml');
const artifact=await api('/actions/artifacts/'+request.artifactId);
assert.equal(artifact.workflow_run.id,request.runId);assert.equal(artifact.expired,false);
assert.equal(artifact.name,'psc1-portable-modules-'+request.seedCommit);
assert.equal(artifact.digest,'sha256:'+request.archiveSha256);
const response=await fetch(artifact.archive_download_url,{headers,signal:AbortSignal.timeout(120000)});
assert.equal(response.status,200);
const bytes=Buffer.from(await response.arrayBuffer());
assert.ok(bytes.length<=134217728,'PSC1_MODULAR_COMPRESSED_ARTIFACT_BOUND');
assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),request.archiveSha256);
const archive=path.join(process.env.RUNNER_TEMP,'psc1-portable-g1.zip');fs.writeFileSync(archive,bytes);
const extract=spawnSync('python3',['-c',`
import pathlib,stat,sys,zipfile
root=pathlib.Path("dist").resolve()
assert not (root/"portable-modules").exists()
with zipfile.ZipFile(sys.argv[1]) as archive:
    rows=archive.infolist()
    selected=[r for r in rows if r.filename.startswith("portable-modules/")]
    assert selected and len(selected)<=16384
    assert sum(r.file_size for r in selected)<=536870912
    for row in selected:
        p=pathlib.PurePosixPath(row.filename)
        assert not p.is_absolute() and ".." not in p.parts and "\\\\" not in row.filename
        mode=row.external_attr>>16
        assert not stat.S_ISLNK(mode)
        target=root.joinpath(*p.parts)
        if row.is_dir(): target.mkdir(parents=True,exist_ok=True)
        else:
            target.parent.mkdir(parents=True,exist_ok=True)
            with archive.open(row) as source,open(target,"xb") as output: output.write(source.read())
`,archive],{encoding:'utf8',timeout:120000,maxBuffer:33554432});
assert.equal(extract.error,undefined);assert.equal(extract.status,0,extract.stderr);
const input=JSON.parse(fs.readFileSync('dist/portable-modules/input.json'));
const receipt=JSON.parse(fs.readFileSync('dist/portable-modules/g1-receipt.json'));
assert.equal(input.sourceCommit,request.seedCommit);assert.equal(receipt.sourceCommit,request.seedCommit);
assert.equal(receipt.status,'passed-native-reference-and-portable-generation');
assert.equal(input.g1.manifestSha256,receipt.manifestSha256);
console.log('PSC1_MODULAR_PINNED_G1 '+JSON.stringify(request));
