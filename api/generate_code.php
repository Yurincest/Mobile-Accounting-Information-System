<?php
function generateCode($prefix, $length = 7) {
    // Pastikan panjang kode tepat $length agar sesuai kolom VARCHAR(10) (contoh: 'JUR' + 7 = 10)
    $bytes = (int) ceil($length / 2);
    $hex = bin2hex(random_bytes($bytes)); // menghasilkan 2*bytes karakter
    $hex = substr($hex, 0, $length);      // potong agar tepat $length karakter
    return $prefix . strtolower($hex);    // gunakan lowercase agar konsisten dengan data awal
}