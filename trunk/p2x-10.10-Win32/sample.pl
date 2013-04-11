#!/usr/bin/perl

#perl2exe_info CompanyName=My Company
#perl2exe_info FileDescription=My File Description
#perl2exe_info FileVersion=1.2.3.4
#perl2exe_info InternalName=My International Name
#perl2exe_info LegalCopyright=My Legal Copyright
#perl2exe_info LegalTrademarks=My Legal Trademarks
#perl2exe_info OriginalFilename=My Original Filename
#perl2exe_info ProductName=My Product Name
#perl2exe_info ProductVersion=My Product Version
#perl2exe_info Comment=My Comment

print "This is sample.pl\n";
print "ARGV = ", join(" ", @ARGV), "\n";

print "Script path \$0 = $0\n";
print "Exe path \$^X = $^X\n";
print "Perl verison \$] = $]\n";

print "\@INC=\n", join("\n", @INC), "\n";
sleep (1);
