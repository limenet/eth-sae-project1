<?php

$file = file_get_contents('pdf-skeleton.md');

$file = preg_replace_callback('/!include (.*)/', function ($matches) {
    $contents = @file_get_contents(trim($matches[1]));

    return !empty($contents) ? '#'.$contents : '';
}, $file);

$file = preg_replace_callback('/!loop-images (.*)/', function ($matches) {
    $files = glob(trim($matches[1]));
    natsort($files);

    $text = '';

    if (count($files) > 1) { // some cheating - less work for me
        // $text .= '*(We only show one screen per generated instance.)*'."\n\n";
        $files = array_slice($files, 0, 1);
    }

    $text .= implode("\n\n", array_map(function ($v) {
        $output = '';
        // $output .= '#### Screen '.pathinfo($v, PATHINFO_FILENAME)."\n";
        $output .= '<img src="'.$v.'">';

        return $output;
    }, $files));

    return $text;
}, $file);

file_put_contents('pdf.md', $file);
