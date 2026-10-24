<?php
// Host transport only: load generated closures and forward unchanged wire bytes.
declare(strict_types=1);
[$script,$module,$mode,$names]=$argv;
$api=require $module;
$expected=json_decode($names,true,512,JSON_THROW_ON_ERROR);
$actual=array_keys($api);sort($actual);$sorted=$expected;sort($sorted);
if($actual!==$sorted)throw new RuntimeException('PSC1_TARGET_API_MISMATCH');
if($mode==='probe')exit(0);
if($mode!=='execute'||count($expected)!==1||count($argv)!==6)throw new RuntimeException('PSC1_TARGET_TRANSPORT_ARGUMENTS');
$wire=file_get_contents($argv[4]);
if($wire===false||strlen($wire)>134217728)throw new RuntimeException('PSC1_TARGET_REQUEST_LIMIT');
$response=$api[$expected[0]]($wire);
if(!is_string($response)||strlen($response)>134217728)throw new RuntimeException('PSC1_TARGET_RESPONSE_LIMIT');
$out=fopen($argv[5],'xb');
if($out===false)throw new RuntimeException('PSC1_TARGET_RESPONSE_WRITE');
$offset=0;
while($offset<strlen($response)){$n=fwrite($out,substr($response,$offset));if($n===false||$n===0)throw new RuntimeException('PSC1_TARGET_RESPONSE_WRITE');$offset+=$n;}
fclose($out);
