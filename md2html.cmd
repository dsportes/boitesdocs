@echo off
echo "<!DOCTYPE html><html><head><title>" %1 "</title><meta charset='utf-8'><style>" > %1.html
type md.css >> %1.html
echo "</style></head><body>" >> %1.html
md2html %1.md >> %1.html
echo "</body></html>" >> %1.html
