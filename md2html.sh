#!/bin/bash
echo '<style>' > $1.html
cat md.css >> $1.html
echo '</style>' >> $1.html
markdown-it $1.md >> $1.html
