<?php
// Compare every unselected declaration, restoring only saved-callee calls to proven fixture leaves.
declare(strict_types=1);
function sections(string $file):array{
 $source=token_get_all(file_get_contents($file),TOKEN_PARSE);$out=[];$name=null;$prefix='';
 foreach($source as$t){
  if(is_array($t)&&$t[0]===T_COMMENT&&preg_match('/^\/\/ declaration (["\'])([A-Za-z0-9_]+)\1$/D',$t[1],$m)===1){$name=$m[2];$out[$name]=[];continue;}
  if($name===null){$prefix.=is_array($t)?$t[1]:$t;continue;}
  if(is_array($t)&&in_array($t[0],[T_WHITESPACE,T_COMMENT,T_DOC_COMMENT],true))continue;
  $out[$name][]=$t;
 }
 return[$prefix,$out];
}
$text=static fn($t)=>is_array($t)?$t[1]:$t;
[$ap,$a]=sections($argv[1]);[$bp,$b]=sections($argv[2]);
if($ap!==$bp||array_keys($a)!==array_keys($b))throw new RuntimeException('DIRECT_UNRELATED_PREFIX_OR_INVENTORY');
$known=[];
foreach(['leaf','wrap']as$name){
 $tokens=$a[$name];
 if(!is_array($tokens[0])||$tokens[0][0]!==T_VARIABLE||$tokens[1]!=='='||
    !is_array($tokens[2])||$tokens[2][0]!==T_STATIC||!is_array($tokens[3])||$tokens[3][0]!==T_FUNCTION)throw new RuntimeException('EXPECTED_ORDINARY_LEAF');
 foreach($tokens as$t)if(is_array($t)&&in_array($t[0],[T_YIELD,T_YIELD_FROM],true))throw new RuntimeException('LEAF_YIELDS');
 $known[$tokens[0][1]]=true;
}
$total=0;
foreach($a as$name=>$tokens){
 if(in_array($name,['leaf','wrap'],true))continue;
 $assignments=[];$bindings=[];
 for($i=0;$i<count($tokens)-2;++$i){
  if(is_array($tokens[$i])&&$tokens[$i][0]===T_VARIABLE&&$tokens[$i+1]==='='){
   $v=$tokens[$i][1];$assignments[$v]=($assignments[$v]??0)+1;
   if(is_array($tokens[$i+2])&&$tokens[$i+2][0]===T_VARIABLE)$bindings[$v]=$tokens[$i+2][1];
  }
 }
 $result='';$count=0;
 for($i=0;$i<count($tokens);++$i){
  $t=$tokens[$i];$v=is_array($t)&&$t[0]===T_VARIABLE?$t[1]:'';
  if($v!==''&&($tokens[$i+1]??null)==='('&&($assignments[$v]??0)===1&&isset($known[$bindings[$v]??''])){
   $depth=1;$end=$i+1;
   while($depth>0){++$end;if(!isset($tokens[$end]))throw new RuntimeException('UNBALANCED_CALL');if($tokens[$end]==='(')++$depth;elseif($tokens[$end]===')')--$depth;}
   $arguments='';for($j=$i+2;$j<$end;++$j)$arguments.=$text($tokens[$j]);
   $result.='(yield['.$v.',['.$arguments.']])';$i=$end;++$count;continue;
  }
  $result.=$text($t);
 }
 $reference=implode('',array_map($text,$b[$name]));
 if($result!==$reference)throw new RuntimeException('NON_STATIC_CALL_SOURCE_CHANGED:'.$name);
 if($name==='third'&&$count!==1)throw new RuntimeException('SCHEDULED_CALLER_NOT_DIRECT');
 if(in_array($name,['apply','shadow','localShadow','useAlias'],true)&&$count!==0)throw new RuntimeException('DYNAMIC_OR_SHADOW_CALL_PROMOTED');
 $total+=$count;
}
if($total<1)throw new RuntimeException('NO_DIRECT_SITE_COVERAGE');
echo 'PSC1_PHP_DIRECT_SITE_TOKENS: '.json_encode(['passed'=>true,'restoredStaticSites'=>$total,'unselectedDeclarationsOtherwiseExact'=>true,'savedCalleeIdentity'=>true,'argumentAndErrorOrder'=>'exact tokens','dynamicAliasAndShadows'=>'retained'],JSON_THROW_ON_ERROR)."\n";
