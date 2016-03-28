rm hand-in.zip

mkdir src
mkdir xml

cp ../src/task-a/UML.zargo src/task-a_UML.zargo
cp ../src/task-b/alloy-model.als src/task-b_alloy-model.als
cp ../src/task-d/alloy-model.als src/task-d_alloy-model.als

php gather-files.php


php parse-md.php
marked pdf.md -o out.html
wkhtmltopdf --print-media-type --orientation landscape out.html hand-in.pdf

7z a "hand-in.zip" "src" "xml" "hand-in.pdf"

rm -r src/
rm -r xml/
rm out.html
rm pdf.md
rm hand-in.pdf
