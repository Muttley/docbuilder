@echo off
setlocal
set PERL5LIB=%~dp0\lib;%PERL5LIB%
perl %~dp0\document-builder.pl %*
endlocal
