# Read-only bounded-memory inspection of a retained qualification artifact.
import hashlib,json,pathlib,re
root=pathlib.Path("retained")
candidates=list(root.rglob("G1-bootstrap.candidate.json"))
reports=list(root.rglob("qualification.json"))
assert len(candidates)==1 and len(reports)==1,(candidates,reports)
candidate=candidates[0]
report=json.loads(reports[0].read_text())
class Reader:
 def __init__(self,path):
  self.file=path.open("rb");self.buffer=b"";self.pos=0;self.offset=0
 def more(self):
  self.offset+=self.pos;self.buffer=self.buffer[self.pos:]+self.file.read(1048576);self.pos=0
  return bool(self.buffer)
 def peek(self):
  if self.pos==len(self.buffer): assert self.more(),"unexpected EOF"
  return self.buffer[self.pos]
 def take(self):
  byte=self.peek();self.pos+=1;return byte
 def at(self): return self.offset+self.pos
 def ws(self):
  while self.peek() in b" \r\n\t": self.take()
 def string(self,callback=None,collect=False):
  assert self.take()==34
  result=[] if collect else None
  while True:
   if self.pos==len(self.buffer): assert self.more()
   match=re.search(rb'["\\]',self.buffer[self.pos:])
   end=len(self.buffer) if match is None else self.pos+match.start()
   data=self.buffer[self.pos:end];self.pos=end
   if callback: callback(data)
   if collect: result.append(data)
   if match is None: continue
   byte=self.take()
   if byte==34: break
   escaped=bytes([byte,self.take()])
   if callback: callback(escaped)
   if collect: result.append(escaped)
  return json.loads(b'"'+b"".join(result)+b'"') if collect else None
 def compound(self):
  assert self.take() in b"{["
  depth=1
  while depth:
   if self.pos==len(self.buffer): assert self.more()
   match=re.search(rb'["{}\[\]]',self.buffer[self.pos:])
   if match is None:self.pos=len(self.buffer);continue
   self.pos+=match.start()
   byte=self.peek()
   if byte==34:self.string();continue
   self.take()
   depth+=1 if byte in b"{[" else -1
class Metrics:
 def __init__(self):
  self.tail=b"";self.bytes=0
  self.patterns={"globalReferenceCaptures":rb'&\$g[0-9]+_', "captureClauses":rb' use \(',
   "staticFunctions":rb'static function \(', "generatorCalls":rb'\(yield \['}
  self.counts={key:0 for key in self.patterns};self.prefix=b""
 def add(self,data):
  self.bytes+=len(data)
  if len(self.prefix)<512:self.prefix+=data[:512-len(self.prefix)]
  joined=self.tail+data
  for key,pattern in self.patterns.items():
   self.counts[key]+=sum(m.end()>len(self.tail) for m in re.finditer(pattern,joined))
  self.tail=joined[-128:]
reader=Reader(candidate);reader.ws();assert reader.take()==123
fields=[];metrics=Metrics()
while True:
 reader.ws()
 if reader.peek()==125:reader.take();break
 key=reader.string(collect=True);reader.ws();assert reader.take()==58;reader.ws()
 start=reader.at();kind=reader.peek()
 if kind==34:reader.string(metrics.add if key=="source" else None)
 elif kind in b"{[":reader.compound()
 else:
  while reader.peek() not in b",}":reader.take()
 fields.append({"key":key,"encodedBytes":reader.at()-start,"kind":chr(kind)})
 reader.ws()
 if reader.peek()==44:reader.take();continue
 assert reader.take()==125;break
digest=hashlib.sha256()
with candidate.open("rb") as file:
 for block in iter(lambda:file.read(1048576),b""):digest.update(block)
receipt={"schema":"psc1-retained-candidate-envelope-diagnosis/1",
 "qualified":False,"compilerExecuted":False,
 "sourceRunId":40069631375,"sourceRequestCommit":"30389b1f218ec9c2f35321e93104edb7bb19d747",
 "target":report["target"],"sourceClosureDigest":report["sourceClosureDigest"],
 "candidateFile":str(candidate),"candidateBytes":candidate.stat().st_size,"candidateSha256":digest.hexdigest(),
 "candidateLimitBytes":134217728,"fields":fields,
 "sourceEncodedBytesWithoutQuotes":metrics.bytes,"sourceTextPatternCounts":metrics.counts,
 "patternCountsAreDiagnosticNotParsedPhpSemantics":True,
 "sourcePrefix":metrics.prefix.decode("utf-8",errors="replace"),
 "events":report.get("events"),"failure":report.get("failure"),
 "scope":"Exact retained file envelope/size and textual source pattern diagnosis; no compiler execution, admission or qualification."}
pathlib.Path("diagnosis.json").write_text(json.dumps(receipt,indent=2)+"\n")
print("PSC1_CANDIDATE_ENVELOPE_DIAGNOSIS: "+json.dumps(receipt))
