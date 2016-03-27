<?php

$file = file_get_contents('pdf-skeleton.md');

$file = preg_replace_callback('/!include (.*)/', function($matches) {
    return '#'.file_get_contents(trim($matches[1]));
}, $file);

$file = preg_replace_callback('/!loop-images (.*)/', function($matches) {
    $files = glob(trim($matches[1]));
    natsort($files);

    return implode("\n\n", array_map(function($v) {
        return '#### Instance '.pathinfo($v, PATHINFO_FILENAME)."\n".'<img src="'.$v.'">';
    }, $files));
}, $file);

file_put_contents('pdf.md', $file);