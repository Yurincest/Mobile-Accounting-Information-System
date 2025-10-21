<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

function getDatabaseName($koneksi) {
    $db = '';
    if ($res = $koneksi->query('SELECT DATABASE() AS db')) {
        if ($row = $res->fetch_assoc()) {
            $db = $row['db'] ?? '';
        }
        $res->close();
    }
    return $db;
}

function loadSchema($koneksi) {
    $schema = ['tables' => [], 'columns' => []];
    if ($res = $koneksi->query('SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE()')) {
        while ($row = $res->fetch_assoc()) {
            $t = $row['TABLE_NAME'];
            $schema['tables'][$t] = true;
            $schema['columns'][$t] = [];
        }
        $res->close();
    }
    foreach (array_keys($schema['tables']) as $t) {
        if ($res = $koneksi->query("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '" . $koneksi->real_escape_string($t) . "'")) {
            while ($row = $res->fetch_assoc()) {
                $schema['columns'][$t][$row['COLUMN_NAME']] = true;
            }
            $res->close();
        }
    }
    return $schema;
}

function normalizeToken($s) {
    $s = trim($s);
    $s = preg_replace('/`|"/','', $s);
    $s = preg_replace('/\bAS\b\s+.+$/i', '', $s); // drop alias
    $s = preg_replace('/\bIFNULL\s*\(|\bSUM\s*\(|\bCOUNT\s*\(|\bMAX\s*\(|\bMIN\s*\(|\bAVG\s*\(/i', '(', $s);
    $s = preg_replace('/\)\s*$/', '', $s);
    return $s;
}

function scanFile($filePath) {
    $content = file_get_contents($filePath);
    $usedTables = [];
    $usedColumns = []; // table => [col => true]

    // Tables from INSERT/UPDATE/FROM/JOIN
    if (preg_match_all('/\b(?:FROM|JOIN|UPDATE|INSERT\s+INTO)\s+`?([A-Z0-9_]+)`?/i', $content, $m)) {
        foreach ($m[1] as $t) { $usedTables[$t] = true; }
    }

    // Columns in INSERT
    if (preg_match_all('/INSERT\s+INTO\s+`?[A-Z0-9_]+`?\s*\(([^\)]+)\)/i', $content, $mIns)) {
        foreach ($mIns[1] as $colsStr) {
            $cols = array_map('normalizeToken', preg_split('/\s*,\s*/', $colsStr));
            foreach ($usedTables as $t => $_) {
                foreach ($cols as $c) { if ($c !== '*') { $usedColumns[$t][$c] = true; } }
            }
        }
    }

    // Columns in UPDATE ... SET
    if (preg_match_all('/UPDATE\s+`?[A-Z0-9_]+`?\s+SET\s+(.+?)\s+(?:WHERE|$)/is', $content, $mUpd)) {
        foreach ($mUpd[1] as $setStr) {
            if (preg_match_all('/`?([A-Z0-9_]+)`?\s*=\s*/i', $setStr, $mCols)) {
                foreach ($usedTables as $t => $_) {
                    foreach ($mCols[1] as $c) { $usedColumns[$t][$c] = true; }
                }
            }
        }
    }

    // Columns in SELECT list
    if (preg_match_all('/SELECT\s+(.+?)\s+FROM\s+`?[A-Z0-9_]+`?/is', $content, $mSel)) {
        foreach ($mSel[1] as $selStr) {
            $parts = preg_split('/\s*,\s*/', $selStr);
            foreach ($parts as $p) {
                $tok = normalizeToken($p);
                if (preg_match('/^([A-Z0-9_]+)\.([A-Z0-9_]+)$/i', $tok, $mm)) {
                    $usedColumns[$mm[1]][$mm[2]] = true;
                } else {
                    foreach ($usedTables as $t => $_) { if ($tok !== '*') { $usedColumns[$t][$tok] = true; } }
                }
            }
        }
    }

    // Columns in WHERE with table prefix
    if (preg_match_all('/\b([A-Z0-9_]+)\.([A-Z0-9_]+)\b\s*(?:=|IN|LIKE|>|<)/i', $content, $mWhere)) {
        foreach ($mWhere[1] as $i => $t) { $usedColumns[$t][$mWhere[2][$i]] = true; }
    }

    return ['tables' => array_keys($usedTables), 'columns' => $usedColumns];
}

$dbName = getDatabaseName($koneksi);
$schema = loadSchema($koneksi);
$dir = __DIR__;
$files = glob($dir . DIRECTORY_SEPARATOR . '*.php');

$report = [
    'status' => 'success',
    'schema_source' => 'INFORMATION_SCHEMA',
    'database' => $dbName,
    'generated_at' => date('c'),
    'files' => []
];

foreach ($files as $file) {
    $scan = scanFile($file);
    $fileReport = [
        'file' => basename($file),
        'tables' => [],
        'columns' => [],
        'summary' => 'OK'
    ];

    // Tables
    foreach ($scan['tables'] as $t) {
        $exists = isset($schema['tables'][$t]);
        $fileReport['tables'][] = ['name' => $t, 'exists' => $exists];
        if (!$exists) { $fileReport['summary'] = 'ISSUES'; }
    }

    // Columns
    foreach ($scan['columns'] as $t => $colsMap) {
        foreach (array_keys($colsMap) as $c) {
            $exists = isset($schema['columns'][$t]) && isset($schema['columns'][$t][$c]);
            $fileReport['columns'][] = ['table' => $t, 'name' => $c, 'exists' => $exists];
            if (!$exists) { $fileReport['summary'] = 'ISSUES'; }
        }
    }

    $report['files'][] = $fileReport;
}

jsonResponse($report);
exit;