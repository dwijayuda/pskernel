<?php
declare(strict_types=1);
require dirname(__DIR__).'/host-tools/typed-io.php';
function reply(array $value): void { echo json_encode($value, JSON_THROW_ON_ERROR)."\n"; fflush(STDOUT); }
try { $host = new Psc1TypedIo(json_decode($argv[1], true, 512, JSON_THROW_ON_ERROR)); }
catch (Throwable $error) { reply(['trap'=>$error->getMessage()]); exit(0); }
reply(['ready'=>true]);
while (($line = fgets(STDIN)) !== false) {
    $command = json_decode($line, true, 512, JSON_THROW_ON_ERROR);
    if ($command['action'] === 'close') { $host->close(); reply(['closed'=>true]); break; }
    try {
        if ($command['action'] === 'probeClosed') $host->close();
        reply(['ok'=>$host->execute($command['source'] ?? '{"op":"readLine"}')]);
    } catch (Throwable $error) { reply(['trap'=>$error->getMessage()]); }
}
