<?php
function cleanText($text) {
    $text = (string) $text;
    // Hilangkan semua karakter kontrol (newline, tab, dll) kecuali spasi biasa
    $text = preg_replace('/[\x00-\x1F\x7F]/u', ' ', $text);
    // Normalisasi spasi ganda jadi satu
    $text = preg_replace('/\s+/u', ' ', $text);
    return trim($text);
}

function sanitizeData($data) {
    if (is_array($data)) {
        foreach ($data as $k => $v) {
            $data[$k] = sanitizeData($v);
        }
        return $data;
    }
    if (is_string($data)) {
        return cleanText($data);
    }
    return $data;
}

function cleanRow($row) {
    return array_map(function($val) {
        return is_string($val) ? cleanText($val) : $val;
    }, $row);
}

function jsonResponse($data) {
    if (function_exists('ob_get_length') && ob_get_length()) {
        ob_clean();
    }
    header_remove("X-Powered-By");
    header('Content-Type: application/json; charset=utf-8');
    $payload = sanitizeData($data);
    $json = json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if (json_last_error() !== JSON_ERROR_NONE) {
        error_log("JSON error in " . __FILE__ . ": " . json_last_error_msg());
    }
    echo trim($json ?? 'null');
    exit;
}