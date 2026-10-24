<?php
// Independent token boundary: only unused global-by-reference captures may change.
declare(strict_types=1);
function normalized(string $file): array {
 $tokens=token_get_all(file_get_contents($file),TOKEN_PARSE);
 $out=[];$globals=[];$function=0;$total=0;
 for($i=0;$i<count($tokens);$i++){
  $token=$tokens[$i];
  if(is_array($token)&&$token[0]===T_WHITESPACE)continue;
  if(is_array($token)&&in_array($token[0],[T_FUNCTION,T_FN],true))$function++;
  if(is_array($token)&&$token[0]===T_USE){
   do{$i++;$next=$tokens[$i];}while(is_array($next)&&$next[0]===T_WHITESPACE);
   if($next!=='(')throw new RuntimeException('CAPTURE_HEADER');
   $items=[];$item='';
   for($i++;$i<count($tokens);$i++){
    $part=$tokens[$i];
    if(is_array($part)&&$part[0]===T_WHITESPACE)continue;
    $text=is_array($part)?$part[1]:$part;
    if($text===','||$text===')'){
     if($item!=='')$items[]=$item;
     $item='';
     if($text===')')break;
    }else $item.=$text;
   }
   $keep=[];
   foreach($items as $item){
    if(preg_match('/^&\\$g[0-9]+_[A-Za-z0-9_]+$/D',$item)===1){
     $globals[$function][]=$item;$total++;
    }else $keep[]=$item;
   }
   if($keep!==[])$out[]='use('.implode(',',$keep).')';
   continue;
  }
  $out[]=is_array($token)?$token[1]:$token;
 }
 return ['tokens'=>implode('',$out),'globals'=>$globals,'total'=>$total];
}
$a=normalized($argv[1]);$b=normalized($argv[2]);
if($a['tokens']!==$b['tokens'])throw new RuntimeException('NON_CAPTURE_SOURCE_CHANGED');
foreach($a['globals'] as $function=>$actual){
 $expected=$b['globals'][$function]??[];
 if(array_values(array_intersect($expected,$actual))!==$actual)throw new RuntimeException('CAPTURE_NOT_ORDERED_SUBSET');
}
echo json_encode(['passed'=>true,'productionGlobalCaptures'=>$a['total'],'referenceGlobalCaptures'=>$b['total']],JSON_THROW_ON_ERROR);
