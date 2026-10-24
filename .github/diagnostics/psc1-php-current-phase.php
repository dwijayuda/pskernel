<?php
declare(strict_types=1);
if(PHP_VERSION!=='8.5.12'||!extension_loaded('pcntl'))throw new RuntimeException('EXACT_RUNTIME_OR_PCNTL');
$reports=[];foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator('baseline',FilesystemIterator::SKIP_DOTS))as$entry){if($entry->isFile()&&$entry->getFilename()==='qualification.json')$reports[]=$entry->getPathname();}
if(count($reports)!==1)throw new RuntimeException('REPORT_INVENTORY');
$report=json_decode(file_get_contents($reports[0]),true,512,JSON_THROW_ON_ERROR);
if($report['testedCommit']!=='1174300d0efc2a10cf6887e598a1a4057f36c7cc'||$report['target']!=='php')throw new RuntimeException('PROVENANCE');
$base=dirname($reports[0]);$module=$base.'/G1-service/module.php';$request=$base.'/G2-self.request.json';
$g1=$report['generations'][0];if(hash_file('sha256',$module)!==$g1['sourceSha256'])throw new RuntimeException('SOURCE_HASH');
$event=array_values(array_filter($report['events'],static fn($e)=>($e['id']??'')==='G2-self'))[0];
if(hash_file('sha256',$request)!==$event['requestSha256'])throw new RuntimeException('REQUEST_HASH');
$lines=explode("\n",file_get_contents($module));$markers=[];
foreach($lines as$index=>$line){if(preg_match('/^\\s*\/\/ declaration (.*)$/D',$line,$match)===1)$markers[$index+1]=substr($match[1],1,-1);}
$owner=static function(int $line)use($markers):string{$current='<runtime>';foreach($markers as$start=>$name){if($start>$line)break;$current=$name;}return$current;};
$api=require $module;$wire=file_get_contents($request);$start=hrtime(true);$samples=[];$counts=[];
pcntl_async_signals(true);
pcntl_signal(SIGALRM,static function()use(&$samples,&$counts,$start,$module,$owner):void{
 $trace=debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS);$position=null;$function=null;
 foreach($trace as$frame){if(($frame['file']??'')===$module){$position=$frame['line']??0;$function=$frame['function']??'<unknown>';break;}}
 $label=$position===null?'<outside-module>':$owner($position);$counts[$label]=($counts[$label]??0)+1;
 $samples[]=['seconds'=>(hrtime(true)-$start)/1000000000,'owner'=>$label,'interruptedCallsite'=>$position,'function'=>$function,'frames'=>array_slice($trace,0,20),'heapBytes'=>memory_get_usage(true)];
 if(hrtime(true)-$start>=120000000000)throw new RuntimeException('PSC1_PHP_PROFILE_120S');
 pcntl_alarm(1);
});
pcntl_alarm(1);$status='finished';$response=null;
try{$response=$api['psCompilerPhpServiceCandidate']($wire);}catch(RuntimeException$error){if($error->getMessage()!=='PSC1_PHP_PROFILE_120S')throw$error;$status='diagnostic-120s-budget-ended';}finally{pcntl_alarm(0);}
arsort($counts);$out='diagnostics/php-current-phase';@mkdir($out,0777,true);
$result=['schema'=>'psc1-exact-php-async-phase-sampling/1','qualified'=>false,'status'=>$status,'elapsedSeconds'=>(hrtime(true)-$start)/1000000000,'sourceSha256'=>hash_file('sha256',$module),'requestSha256'=>hash_file('sha256',$request),'sourceClosureDigest'=>$report['sourceClosureDigest'],'responseBytes'=>$response===null?null:strlen($response),'sampledInterruptedOwners'=>$counts,'lastSamples'=>array_slice($samples,-5),'peakPhpAllocatedBytes'=>memory_get_peak_usage(true),'memoryLimit'=>ini_get('memory_limit'),'scope'=>'exact generated G1 compiling actual G2 request,unmodified compiler source,1-second asynchronous callsite/stack samples; approximate phase evidence,not CPU attribution or qualification'];
file_put_contents($out.'/receipt.json',json_encode($result,JSON_PRETTY_PRINT|JSON_THROW_ON_ERROR)."\n");
file_put_contents($out.'/all-samples.json',json_encode($samples,JSON_PRETTY_PRINT|JSON_THROW_ON_ERROR)."\n");
echo 'PSC1_PHP_CURRENT_PHASE: '.json_encode($result,JSON_THROW_ON_ERROR)."\n";
