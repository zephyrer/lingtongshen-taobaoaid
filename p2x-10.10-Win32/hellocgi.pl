#!/usr/bin/perl

# simple hello world cgi script
print "Content-type: text/html\n\n";
print "<html><body>\n";
$date = localtime();
print "<hr>Hello, world! on $date<br><hr>\n";

print "</body></html>\n";
