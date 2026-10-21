<?php
declare(strict_types=1);
$api = require $argv[1];
$runtime = require $argv[2];
function check(bool $condition, string $name): void {
    if (!$condition) { throw new RuntimeException($name); }
}
function rejects(Closure $action, string $message): void {
    try { $action(); }
    catch (TypeError $error) {
        check(str_contains($error->getMessage(), $message), 'wrong foreign error channel');
        return;
    }
    throw new RuntimeException('expected UTF8/type refusal');
}
$text = "A😀é";
$expected = ["A","😀","A","A","A","é","A","A"];
foreach ($expected as $position => $value) {
    $offset = gmp_init($position);
    check($api["peek"]($text,$offset) === $value,'byte boundary character');
    check(gmp_cmp($api["step"]($text,$offset),$position+strlen($value)) === 0,'byte boundary next');
}
check($api["peek"]("",gmp_init(0)) === "A",'empty default');
$huge = gmp_init("184467440737095516160");
check($api["peek"]($text,$huge) === "A",'huge offset default');
check(gmp_cmp($api["step"]($text,$huge),gmp_add($huge,1)) === 0,'huge next exact');
foreach ([[1,5,"😀"],[1,3,"😀é"],[2,7,""],[5,7,"é"],[0,0,""]] as [$start,$stop,$value]) {
    check($api["extract"]($text,gmp_init($start),gmp_init($stop)) === $value,'extract policy unchanged');
}
foreach (["0","-0","123","0123","9223372036854775807","9223372036854775808"] as $numericText) {
    check($api["peek"]($numericText,gmp_init(0)) === $numericText[0],'numeric String validation key');
}
rejects(fn()=>$api["peek"]("123\xff",gmp_init(0)),'PSC1_PHP_ARGUMENT_TYPE');
$changed = $api["append"]($text,"Z");
check($api["peek"]($text,gmp_init(5)) === "é",'old value survives append');
check($api["peek"]($changed,gmp_init(7)) === "Z",'new value indexing');
check($api["peek"]("cat",gmp_init(0)) === "c",'cache first value');
check($api["peek"]("bat",gmp_init(0)) === "b",'cache same-size distinct value');
check($api["peek"]("Ω",gmp_init(0)) === "Ω",'third value');
check($api["peek"]($text,gmp_init(1)) === "😀",'cache eviction safe');
$copy = $text;
$copy[1] = "X";
rejects(fn()=>$api["peek"]($copy,gmp_init(0)),'PSC1_PHP_ARGUMENT_TYPE');
check($api["peek"]($text,gmp_init(1)) === "😀",'copy-on-write cache safety');
foreach (["\xff","\x80","\xc0\xaf","\xed\xa0\x80","\xf4\x90\x80\x80","\xe2\x82",
    "valid-prefix\xff"] as $invalid) {
    rejects(fn()=>$api["peek"]($invalid,gmp_init(0)),'PSC1_PHP_ARGUMENT_TYPE');
    rejects(fn()=>$api["peek"]($invalid,$huge),'PSC1_PHP_ARGUMENT_TYPE');
    rejects(fn()=>$runtime["get"]($invalid,gmp_init(0)),'PSC1_PHP_INVALID_UTF8');
    rejects(fn()=>$runtime["get"]($invalid,$huge),'PSC1_PHP_INVALID_UTF8');
}
rejects(fn()=>$api["peek"]($text,gmp_init(-1)),'PSC1_PHP_ARGUMENT_TYPE');
rejects(fn()=>$api["peek"]($text,0),'PSC1_PHP_ARGUMENT_TYPE');
$left = str_repeat("x",499999)."A";
$right = str_repeat("x",499999)."B";
$offset = gmp_init(499999);
$next = gmp_init(500000);
$start = hrtime(true);
for ($index=0;$index<100000;$index++) {
    check($api["peek"]($left,$offset) === "A",'large left lookup');
    check(gmp_cmp($api["step"]($left,$offset),$next) === 0,'large left next');
    check($api["peek"]($right,$offset) === "B",'large right lookup');
    check(gmp_cmp($api["step"]($right,$offset),$next) === 0,'large right next');
}
$elapsed = (hrtime(true)-$start)/1e9;
check($elapsed <= 5,'cached repeated byte lookup bound');
echo json_encode(["passed"=>true,"iterations"=>100000,"inputBytes"=>500000,"elapsedSeconds"=>$elapsed,
    "checks"=>["UTF8 scalar byte boundaries","middle-byte and empty defaults","exact huge next",
        "extract policy unchanged","persistent String values","same-length content and eviction",
        "copy-on-write cache safety","malformed UTF8 public guard","malformed UTF8 helper even out of range",
        "Nat argument type refusal","two large immutable Strings cache","runtime-free echo retained"]],
    JSON_THROW_ON_ERROR),"\n";
