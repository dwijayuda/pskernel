<?php
declare(strict_types=1);
$mode=$argv[1];if(!in_array($mode,['node-properties','node-properties-and-direct-calls'],true))throw new RuntimeException('MODE');
if(PHP_VERSION!=='8.5.12'||!extension_loaded('pcntl'))throw new RuntimeException('EXACT_RUNTIME');
$reports=[];foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator('baseline',FilesystemIterator::SKIP_DOTS))as$entry){if($entry->isFile()&&$entry->getFilename()==='qualification.json')$reports[]=$entry->getPathname();}
if(count($reports)!==1)throw new RuntimeException('REPORT_INVENTORY');
$report=json_decode(file_get_contents($reports[0]),true,512,JSON_THROW_ON_ERROR);
if($report['testedCommit']!=='1174300d0efc2a10cf6887e598a1a4057f36c7cc')throw new RuntimeException('COMMIT');
$base=dirname($reports[0]);$original=$base.'/G1-service/module.php';$source=file_get_contents($original);
if(hash('sha256',$source)!==$report['generations'][0]['sourceSha256'])throw new RuntimeException('SOURCE');
$split=strpos($source,'// declaration ');if($split===false)throw new RuntimeException('DECLARATIONS');
$prefix=substr($source,0,$split);$program=substr($source,$split);
foreach(['string $tag','int $count','mixed $first','mixed $second','array $rest']as$field){$needle='private '.$field.';';if(substr_count($prefix,$needle)!==1)throw new RuntimeException('PROPERTY');$prefix=str_replace($needle,'public private(set) '.$field.';',$prefix);}
// This suffix closes its enclosing module scope; tokenize without standalone-fragment parsing.
// Requiring the complete modified module below still performs PHP's actual syntax validation.
$tokens=token_get_all('<?php '.$program);array_shift($tokens);
$text=static fn($token)=>is_array($token)?$token[1]:$token;
$next=static function(int $index)use($tokens):int{do{++$index;}while(isset($tokens[$index])&&is_array($tokens[$index])&&in_array($tokens[$index][0],[T_WHITESPACE,T_COMMENT,T_DOC_COMMENT],true));return$index;};
$plain=[];$bindings=[];$assignments=[];
for($i=0;$i<count($tokens);++$i){
 if(!is_array($tokens[$i])||$tokens[$i][0]!==T_VARIABLE)continue;
 $name=$tokens[$i][1];$eq=$next($i);if(($tokens[$eq]??null)!=='=')continue;
 $rhs=$next($eq);
 if(preg_match('/^\\$g[0-9]+_/D',$name)===1&&is_array($tokens[$rhs]??null)&&$tokens[$rhs][0]===T_STATIC){
  $fn=$next($rhs);if(is_array($tokens[$fn]??null)&&$tokens[$fn][0]===T_FUNCTION)$plain[$name]=true;
 }
 $assignments[$name]=($assignments[$name]??0)+1;
 if(is_array($tokens[$rhs]??null)&&$tokens[$rhs][0]===T_VARIABLE)$bindings[$name]=$tokens[$rhs][1];
}
$slot=static fn(int $index)=>$index===0?'->tag':($index===1?'->first':($index===2?'->second':'->rest['.($index-3).']'));
$result='';$slots=0;$calls=0;
for($i=0;$i<count($tokens);++$i){
 $token=$tokens[$i];
 if(is_array($token)&&$token[0]===T_VARIABLE){
  $open=$next($i);$number=$next($open);$close=$next($number);
  if(($tokens[$open]??null)==='['&&is_array($tokens[$number]??null)&&$tokens[$number][0]===T_LNUMBER&&preg_match('/^(0|[1-9][0-9]*)$/D',$tokens[$number][1])===1&&($tokens[$close]??null)===']'){
   $result.=$token[1].$slot((int)$tokens[$number][1]);$i=$close;++$slots;continue;
  }
 }
 if($mode==='node-properties-and-direct-calls'&&is_array($token)&&$token[0]===T_YIELD){
  $open=$next($i);$callee=$next($open);$comma=$next($callee);$args=$next($comma);
  $name=is_array($tokens[$callee]??null)&&$tokens[$callee][0]===T_VARIABLE?$tokens[$callee][1]:'';
  $global=$bindings[$name]??'';
  if(($tokens[$open]??null)==='['&&($tokens[$comma]??null)===','&&($tokens[$args]??null)==='['&&($assignments[$name]??0)===1&&isset($plain[$global])){
   $depth=1;$end=$args;
   while($depth>0){++$end;if(!isset($tokens[$end]))throw new RuntimeException('ARGUMENTS');if($tokens[$end]==='[')++$depth;elseif($tokens[$end]===']')--$depth;}
   $requestEnd=$next($end);if(($tokens[$requestEnd]??null)!==']')throw new RuntimeException('CALL_REQUEST');
   $result.=$name.'(';for($part=$args+1;$part<$end;++$part)$result.=$text($tokens[$part]);$result.=')';$i=$requestEnd;++$calls;continue;
  }
 }
 $result.=$text($token);
}
if($slots<1000||($mode==='node-properties-and-direct-calls'&&$calls<100))throw new RuntimeException('EXPECTED_OPTIMIZATION_SITES');
$modified=$prefix.$result;$module=dirname($original).'/diagnostic-'.$mode.'.php';file_put_contents($module,$modified);$module=realpath($module);
$api=require $module;$smoke=[];
foreach(['G1-lean-modules','G1-ps-integer-unicode','G1-ps-list-literal','G1-lean-handler-pattern','G1-lean-ordinary-loop']as$label){
 $response=$api['psCompilerPhpServiceCandidate'](file_get_contents($base.'/'.$label.'.request.json'));
 if(trim($response)!==trim(file_get_contents($base.'/'.$label.'.candidate.json')))throw new RuntimeException('CANDIDATE_DIFFERENCE:'.$label);$smoke[]=$label;
}
$lines=explode("\n",$modified);$markers=[];foreach($lines as$index=>$line){if(preg_match('/^\\s*\/\/ declaration (.*)$/D',$line,$match)===1)$markers[$index+1]=substr($match[1],1,-1);}
$owner=static function(int $line)use($markers):string{$current='<runtime>';foreach($markers as$start=>$name){if($start>$line)break;$current=$name;}return$current;};
$request=$base.'/G2-self.request.json';$event=array_values(array_filter($report['events'],static fn($e)=>($e['id']??'')==='G2-self'))[0];if(hash_file('sha256',$request)!==$event['requestSha256'])throw new RuntimeException('REQUEST');
$wire=file_get_contents($request);$start=hrtime(true);$samples=[];$counts=[];pcntl_async_signals(true);
pcntl_signal(SIGALRM,static function()use(&$samples,&$counts,$start,$module,$owner):void{
 $trace=debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS);$position=null;
 foreach($trace as$frame){if(($frame['file']??'')===$module){$position=$frame['line']??0;break;}}
 $label=$position===null?'<outside>':$owner($position);$counts[$label]=($counts[$label]??0)+1;
 $samples[]=['seconds'=>(hrtime(true)-$start)/1000000000,'owner'=>$label,'line'=>$position,'frames'=>array_slice($trace,0,16),'heapBytes'=>memory_get_usage(true)];
 if(hrtime(true)-$start>=120000000000)throw new RuntimeException('PSC1_PROFILE_BUDGET');pcntl_alarm(1);
});
pcntl_alarm(1);$status='finished';$response=null;
try{$response=$api['psCompilerPhpServiceCandidate']($wire);}catch(RuntimeException$e){if($e->getMessage()!=='PSC1_PROFILE_BUDGET')throw$e;$status='diagnostic-120s-budget-ended';}finally{pcntl_alarm(0);}
arsort($counts);$out='diagnostics/php-node-experiment-'.$mode;@mkdir($out,0777,true);
$receipt=['schema'=>'psc1-php-controlled-node-and-call-experiment/1','qualified'=>false,'mode'=>$mode,'status'=>$status,'elapsedSeconds'=>(hrtime(true)-$start)/1000000000,'originalSourceSha256'=>hash_file('sha256',$original),'modifiedSourceSha256'=>hash('sha256',$modified),'requestSha256'=>hash_file('sha256',$request),'slotSites'=>$slots,'directCallSites'=>$calls,'matchedFrozenCandidates'=>$smoke,'owners'=>$counts,'lastSamples'=>array_slice($samples,-3),'peakPhpAllocatedBytes'=>memory_get_peak_usage(true),'memoryLimit'=>ini_get('memory_limit'),'responseBytes'=>$response===null?null:strlen($response),'scope'=>'controlled backend-runtime/slot/static-call substitutions on exact archived G1/G2 input; five complete frozen candidate responses match; no admission or fixed-point qualification'];
file_put_contents($out.'/receipt.json',json_encode($receipt,JSON_PRETTY_PRINT|JSON_THROW_ON_ERROR)."\n");file_put_contents($out.'/samples.json',json_encode($samples,JSON_THROW_ON_ERROR)."\n");echo 'PSC1_PHP_NODE_EXPERIMENT: '.json_encode($receipt,JSON_THROW_ON_ERROR)."\n";
