<?php
array_map(function($file) {
    @mkdir(str_replace('instances/', 'xml/', pathinfo($file, PATHINFO_DIRNAME)).'/..', 0777, true);
    copy($file, str_replace('/1.xml', '.xml', str_replace('instances/', 'xml/', $file)));
}, glob('instances/*/*/1.xml'));
