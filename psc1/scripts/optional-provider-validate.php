<?php
declare(strict_types=1);
if(PHP_VERSION !== '8.5.12' || !extension_loaded('gmp') || extension_loaded('ffi')) throw new RuntimeException('PSC1_PHP_RUNTIME_PIN');
$expected=json_decode(file_get_contents($argv[2]),true,512,JSON_THROW_ON_ERROR);
$api=require $argv[1];
if(!is_array($api)||array_keys($api)!==$expected) throw new RuntimeException('PSC1_PROVIDER_PUBLIC_API');
echo json_encode(['accepted'=>true,'publicNames'=>$expected,'runtime'=>'PHP 8.5.12'],JSON_THROW_ON_ERROR)."\n";
