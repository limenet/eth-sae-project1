rm hand-in.zip
rm hand-in.pdf

mkdir src
mkdir xml

cp ../src/task-a/UML.zargo src/task-a_UML.zargo
cp ../src/task-b/alloy-model.als src/task-b_alloy-model.als
cp ../src/task-d/alloy-model.als src/task-d_alloy-model.als

php gather-files.php

7z a "hand-in.zip" "src" "xml"

php parse-md.php
marked pdf.md -o out.html
wkhtmltopdf --print-media-type out.html hand-in.pdf

rm -r src/
rm -r xml/
rm out.html
rm pdf.md