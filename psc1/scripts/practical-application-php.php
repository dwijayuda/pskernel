<?php
declare(strict_types=1);
require __DIR__ . '/../host-tools/typed-io.php';
$config=json_decode(file_get_contents($argv[2]),true,512,JSON_THROW_ON_ERROR);
$config['abi']='psc1-php-linux-ffi-string-io/1';
try {$host=new Psc1TypedIo($config);}
catch(RuntimeException $error) {
 if(str_contains($error->getMessage(),'PSC1_IO_REQUIRED_CAPABILITY_DENIED'))exit(78);
 throw $error;
}
try {
 $program=require $argv[1];
 $arguments=json_encode(array_slice($argv,3),JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);
 $success=$program['run']($arguments,$host->execute(...));
} finally {$host->close();}
exit($success?0:2);
