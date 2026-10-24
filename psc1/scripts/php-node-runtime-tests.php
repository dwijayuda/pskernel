<?php
declare(strict_types=1);
$make=require $argv[1];
$empty=$make('empty');
if(!$empty instanceof ArrayAccess||$empty[0]!=='empty'||isset($empty[1]))throw new RuntimeException('EMPTY_LAYOUT');
$child=$make('one',42);
$many=$make('many',null,true,'λ🙂',[1,2],$child,static fn()=>7);
foreach([0=>'many',1=>null,2=>true,3=>'λ🙂',4=>[1,2],5=>$child] as $index=>$value){
 if(!isset($many[$index])||$many[$index]!==$value)throw new RuntimeException('FIELD_POSITION');
}
if(($many[6])()!==7)throw new RuntimeException('CALLABLE_FIELD');
foreach([static function()use($many){$many[1]=9;},static function()use($many){unset($many[1]);}] as $mutate){
 try{$mutate();throw new RuntimeException('MUTATION_ACCEPTED');}
 catch(LogicException $error){if($error->getMessage()!=='PSC1_PHP_IMMUTABLE_CONSTRUCTOR')throw $error;}
}
foreach([-1,7,'head'] as $offset){
 try{$unused=$many[$offset];throw new RuntimeException('BAD_OFFSET_ACCEPTED');}
 catch(UnexpectedValueException $error){if($error->getMessage()!=='PSC1_PHP_CONSTRUCTOR_FIELD')throw $error;}
}
$left=$make('cons',1,$child);$right=$make('cons',2,$child);
unset($left);
if($child[1]!==42||$right[2]!==$child)throw new RuntimeException('SHARED_OWNER_CHANGED');
$leaf=$make('leaf');$weak=WeakReference::create($leaf);$parent=$make('parent',$leaf);
unset($leaf);if($weak->get()===null)throw new RuntimeException('PREMATURE_COLLECTION');
unset($parent);gc_collect_cycles();if($weak->get()!==null)throw new RuntimeException('DEAD_DESCENDANT_RETAINED');
$cycle=null;$callback=static function()use(&$cycle){return $cycle;};
$cycle=$make('cycle',$callback);$weakCycle=WeakReference::create($cycle);
unset($cycle,$callback);gc_collect_cycles();
if($weakCycle->get()!==null)throw new RuntimeException('CYCLE_RETAINED');
// A two-million-node dead spine must release under the unchanged stack limit.
$root=$make('nil');
for($index=0;$index<2000000;$index++)$root=$make('cons','x',$root);
$weakRoot=WeakReference::create($root);$retainedChild=$root[2];
unset($root);if($weakRoot->get()!==null)throw new RuntimeException('ROOT_RETAINED');
if($retainedChild[0]!=='cons'||$retainedChild[1]!=='x')throw new RuntimeException('LIVE_SHARED_TAIL_MUTATED');
unset($retainedChild);gc_collect_cycles();
echo 'PSC1_PHP_NODE_RUNTIME: '.json_encode([
 'passed'=>true,'fields'=>'zero/one/six including null/bool/Unicode/array/node/closure',
 'immutableOffsets'=>true,'invalidOffsetRefusals'=>true,'sharedOwnersPreserved'=>true,
 'deadDescendantsCollected'=>true,'cyclesCollected'=>true,'iterativeDeadSpine'=>2000000,
 'memoryLimit'=>ini_get('memory_limit'),'stackLimit'=>'unchanged'
],JSON_THROW_ON_ERROR)."\n";
