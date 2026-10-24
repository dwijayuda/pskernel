<?php
// Independent syntax boundary: only canonical node slot reads may differ.
declare(strict_types=1);
function normalized(string $file,bool $restore):array{
 $tokens=token_get_all(file_get_contents($file),TOKEN_PARSE);
 $text=static fn($t)=>is_array($t)?$t[1]:$t;
 $next=static function(int $i)use($tokens):int{
  do{++$i;}while(isset($tokens[$i])&&is_array($tokens[$i])&&in_array($tokens[$i][0],[T_WHITESPACE,T_COMMENT,T_DOC_COMMENT],true));
  return $i;
 };
 $prefix='';$output='';$program=false;$reads=0;
 for($i=0;$i<count($tokens);++$i){
  $t=$tokens[$i];
  if(is_array($t)&&$t[0]===T_COMMENT&&str_starts_with($t[1],'// declaration '))$program=true;
  if(!$program){$prefix.=$text($t);continue;}
  if(is_array($t)&&in_array($t[0],[T_WHITESPACE,T_COMMENT,T_DOC_COMMENT],true))continue;
  if($restore&&is_array($t)&&$t[0]===T_VARIABLE){
   $arrow=$next($i);$property=$next($arrow);
   if(is_array($tokens[$arrow]??null)&&$tokens[$arrow][0]===T_OBJECT_OPERATOR&&is_array($tokens[$property]??null)&&$tokens[$property][0]===T_STRING){
    $name=$tokens[$property][1];$index=null;$end=$property;
    if(in_array($name,['tag','first','second'],true))$index=['tag'=>0,'first'=>1,'second'=>2][$name];
    elseif($name==='rest'){
     $open=$next($property);$number=$next($open);$close=$next($number);
     if(($tokens[$open]??null)!=='['||!is_array($tokens[$number]??null)||$tokens[$number][0]!==T_LNUMBER||
        preg_match('/^(0|[1-9][0-9]*)$/D',$tokens[$number][1])!==1||($tokens[$close]??null)!==']')throw new RuntimeException('NONCANONICAL_OVERFLOW_SLOT');
     $value=(int)$tokens[$number][1];if($value<0||$value>PHP_INT_MAX-3)throw new RuntimeException('OVERFLOW_SLOT');
     $index=$value+3;$end=$close;
    }else throw new RuntimeException('UNAPPROVED_PROPERTY_READ');
    $output.=$t[1].'['.$index.']';$i=$end;++$reads;continue;
   }
  }
  $output.=$text($t);
 }
 if(!$program)throw new RuntimeException('DECLARATIONS_MISSING');
 return ['prefix'=>$prefix,'tokens'=>$output,'reads'=>$reads];
}
$a=normalized($argv[1],true);$b=normalized($argv[2],false);
if($a['reads']<4)throw new RuntimeException('NO_SLOT_REWRITE_COVERAGE');
if($a['prefix']!==$b['prefix']||$a['tokens']!==$b['tokens'])throw new RuntimeException('NON_SLOT_SOURCE_CHANGED');
echo 'PSC1_PHP_NODE_ACCESS_TOKENS: '.json_encode(['passed'=>true,'canonicalReadsRestored'=>$a['reads'],'allOtherTokensExact'=>true,'runtimePrefixExact'=>true],JSON_THROW_ON_ERROR)."\n";
