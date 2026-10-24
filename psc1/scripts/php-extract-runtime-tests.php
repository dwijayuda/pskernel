<?php
declare(strict_types=1);
$root=$argv[1];
$old=require $root.'/retained-helper.php';$new=require $root.'/actual-helper.php';
$oldApi=require $root.'/retained.php';$newApi=require $root.'/actual.php';
function observe(Closure $function,string $source,GMP $begin,GMP $end):array{
 try{return ['ok',base64_encode($function($source,$begin,$end))];}
 catch(Throwable $error){return ['error',get_class($error),$error->getMessage()];}
}
$cases=0;
$compare=static function(string $source,string|int $begin,string|int $end)use($old,$new,$oldApi,$newApi,&$cases):void{
 $a=observe($old,$source,gmp_init($begin),gmp_init($end));$b=observe($new,$source,gmp_init($begin),gmp_init($end));
 if($a!==$b)throw new RuntimeException('EXTRACT_DIFFERENCE:'.json_encode([base64_encode($source),(string)$begin,(string)$end,$a,$b],JSON_THROW_ON_ERROR));
 $a=observe($oldApi['extract'],$source,gmp_init($begin),gmp_init($end));$b=observe($newApi['extract'],$source,gmp_init($begin),gmp_init($end));
 if($a!==$b)throw new RuntimeException('PUBLIC_EXTRACT_DIFFERENCE');++$cases;
};
$huge='100000000000000000000000000000000000000000000000000000000000000';
$sources=['','abc',"a\0b","λ🙂é",str_repeat('🙂λa',31),"\xff","a\xc0\x80b","\xed\xa0\x80","a\xf4\x90\x80\x80","\x80a","a\xe2\x82"];
foreach($sources as $source){$size=strlen($source);$positions=[-2,-1,0,1,2,3,$size-1,$size,$size+1,$huge];foreach($positions as $begin)foreach($positions as $end)$compare($source,$begin,$end);}
mt_srand(435);$alphabet=['a','z',"\0",'λ','🙂','́',"\n"];
for($case=0;$case<24000;++$case){
 $source='';$length=mt_rand(0,32);for($i=0;$i<$length;++$i)$source.=$alphabet[mt_rand(0,count($alphabet)-1)];
 $size=strlen($source);$compare($source,mt_rand(-1,$size+2),mt_rand(-1,$size+2));
}
$large=str_repeat("λ🙂a\0",125000);
for($index=0;$index<16;++$index){$start=$index*8;$actual=$newApi['extract']($large,gmp_init($start),gmp_init($start+32));if($actual!==substr($large,$start,32))throw new RuntimeException('LARGE_SOURCE_SLICE');}
echo 'PSC1_PHP_EXTRACT_RUNTIME: '.json_encode(['passed'=>true,'retainedHelperCases'=>$cases,'retainedEmittedCases'=>$cases,'unicodeByteBoundaries'=>true,'invalidUtf8AndErrorPriority'=>true,'hugeAndNegativeIndices'=>true,'largeSourceBytes'=>strlen($large),'largeSourceSlices'=>16,'memoryLimit'=>ini_get('memory_limit'),'validationCache'=>'existing two-key UTF8 validity helper; no extra retained cache','scope'=>'same emitter production and retained policy; strict IR fixture; exact helper/public observations'],JSON_THROW_ON_ERROR)."\n";
