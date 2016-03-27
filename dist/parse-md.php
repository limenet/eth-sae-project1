<?php

$file = file_get_contents('pdf-skeleton.md');

$file = preg_replace_callback('/!include (.*)/', function($matches) {
    $contents = @file_get_contents(trim($matches[1]));
    return !empty($contents) ? '#'.$contents : '';
}, $file);

$file = preg_replace_callback('/!loop-images (.*)/', function($matches) {
    $files = glob(trim($matches[1]));
    natsort($files);

    $text = '';

    if (count($files) >= 10) { // some cheating - less work for me
        $text = '*(output truncated to 10 images)*'."\n";
        $files = array_slice($files, 0, 10);
    }

    $text .= implode("\n\n", array_map(function($v) {
        return '#### Screen '.pathinfo($v, PATHINFO_FILENAME)."\n".'<img src="'.$v.'">';
    }, $files));

    return $text;
}, $file);

file_put_contents('pdf.md', $file);