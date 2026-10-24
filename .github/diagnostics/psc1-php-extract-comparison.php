<?php
declare(strict_types=1);
$reports=[];foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator('baseline',FilesystemIterator::SKIP_DOTS)) as $entry){if($entry->isFile()&&$entry->getFilename()==='qualification.json')$reports[]=$entry->getPathname();}if(count($reports)!==1)throw new RuntimeException('REPORT_INVENTORY');
$report=json_decode(file_get_contents($reports[0]),true,512,JSON_THROW_ON_ERROR);
if($report['testedCommit']!=='75f04cfdcafc1fbeea08f66f595f40ff6b777d04')throw new RuntimeException('COMMIT');
$module=dirname($reports[0]).'/G1-service/module.php';
if(hash_file('sha256',$module)!==$report['generations'][0]['sourceSha256'])throw new RuntimeException('SOURCE_HASH');
$api=require $module;
$wrapped=(new ReflectionFunction($api['psCompilerPhpServiceCandidate']))->getStaticVariables();
$helpers=(new ReflectionFunction($wrapped['implementation']))->getStaticVariables();
$old=$helpers['__ps_stringExtract'];$__ps_utf8Valid=$helpers['__ps_utf8Valid'];
    $__ps_stringExtract = static function (string $source, \GMP $start, \GMP $stop) use ($__ps_utf8Valid): string {
        if (gmp_cmp($start, $stop) >= 0) {
            return '';
        }
        if (!$__ps_utf8Valid($source)) {
            throw new \TypeError('PSC1_PHP_INVALID_UTF8');
        }
        $size = strlen($source);
        if (gmp_cmp($start, 0) < 0 || gmp_cmp($start, $size) >= 0) {
            return '';
        }
        $begin = gmp_intval($start);
        if ((ord($source[$begin]) & 0xc0) === 0x80) {
            return '';
        }
        $end = $size;
        if (gmp_cmp($stop, $size) < 0) {
            $candidate = gmp_intval($stop);
            if ((ord($source[$candidate]) & 0xc0) !== 0x80) {
                $end = $candidate;
            }
        }
        return substr($source, $begin, $end - $begin);
    };

$new=$__ps_stringExtract;
function observe(Closure $function,string $source,GMP $begin,GMP $end):array{
 try{return ['ok',base64_encode($function($source,$begin,$end))];}
 catch(Throwable $error){return ['error',get_class($error),$error->getMessage()];}
}
$cases=0;
$compare=static function(string $source,string|int $begin,string|int $end)use($old,$new,&$cases):void{
 $a=observe($old,$source,gmp_init($begin),gmp_init($end));$b=observe($new,$source,gmp_init($begin),gmp_init($end));
 if($a!==$b)throw new RuntimeException('EXTRACT_DIFFERENCE:'.json_encode([base64_encode($source),(string)$begin,(string)$end,$a,$b],JSON_THROW_ON_ERROR));++$cases;
};
$huge='100000000000000000000000000000000000000000000000000000000000000';
$sources=['','abc',"a\0b","λ🙂é",str_repeat('🙂λa',31),"\xff","a\xc0\x80b","\xed\xa0\x80","a\xf4\x90\x80\x80","\x80a","a\xe2\x82"];
foreach($sources as $source){$size=strlen($source);$positions=[-2,-1,0,1,2,3,$size-1,$size,$size+1,$huge];foreach($positions as $begin)foreach($positions as $end)$compare($source,$begin,$end);}
mt_srand(435);$alphabet=['a','z',"\0",'λ','🙂','́',"\n"];
for($case=0;$case<24000;++$case){
 $source='';$length=mt_rand(0,32);for($i=0;$i<$length;++$i)$source.=$alphabet[mt_rand(0,count($alphabet)-1)];
 $size=strlen($source);$compare($source,mt_rand(-1,$size+2),mt_rand(-1,$size+2));
}
$compilerSource=file_get_contents($module);$positions=[0];$position=0;
for($i=0;$i<15;++$i){$next=strpos($compilerSource,"\n",$position+1);if($next===false)break;$position=$next+1;$positions[]=$position;}
$times=[];
foreach(['new'=>$new,'retained'=>$old]as$label=>$function){
 $began=hrtime(true);foreach($positions as $start){$result=$function($compilerSource,gmp_init($start),gmp_init($start+32));if($result!==substr($compilerSource,$start,32))throw new RuntimeException('COMPILER_SLICE');}
 $times[$label]=(hrtime(true)-$began)/1000000000;
}
$result=['schema'=>'psc1-php-extract-retained-comparison/1','qualified'=>false,'passed'=>true,'differentialCases'=>$cases,'compilerSourceSha256'=>hash_file('sha256',$module),'compilerSourceBytes'=>strlen($compilerSource),'actualCompilerSlices'=>count($positions),'elapsedSeconds'=>$times,'peakPhpAllocatedBytes'=>memory_get_peak_usage(true),'memoryLimit'=>ini_get('memory_limit'),'scope'=>'retained runtime differential and actual generated compiler-source operation; not G2/G3 or fixed-point qualification'];
@mkdir('diagnostics/php-extract',0777,true);file_put_contents('diagnostics/php-extract/receipt.json',json_encode($result,JSON_PRETTY_PRINT|JSON_THROW_ON_ERROR)."\n");
echo 'PSC1_PHP_EXTRACT_COMPARISON: '.json_encode($result,JSON_THROW_ON_ERROR)."\n";
