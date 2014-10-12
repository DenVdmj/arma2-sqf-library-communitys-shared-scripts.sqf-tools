@rem='
@"%~dp0/bin/perl.exe" -I"%~dp0lib" "%~dpnx0" %*
@exit
@rem';

use strict;
require 'sqf.utils.pl';

my ($source, $target) = @ARGV;

die qq(File "mcpp.exe" not found \nPlease get mcpp.exe from http://sourceforge.net/projects/mcpp/\n)
    unless -f './bin/mcpp.exe';

die qq(No input sqf-file specified\n)
    unless $source;

die qq(File not found: "$source"\n)
    unless -f $source;

{
    my $preprocessedFilename = $target || "$source.(preprocessed).sqf";
    my $packedFilename       = $target || "$source.(packed).sqf";
    my $sourceText = readfile($source);
    local *hndlMCPP;
    open (hndlMCPP, qq(| "./bin/mcpp.exe" -P -+ >$preprocessedFilename));
    print hndlMCPP $sourceText;
    close (hndlMCPP);
    writefile($packedFilename, sqfpack(readfile($preprocessedFilename)));
}

sub sqfpack {
    return sqflockup(shift, sub {
        my $chunk = shift;
        # ����� ������� � �������� �����
        $chunk =~ s/\s\s+/ /g;
        # ����� ������� �� � ����� ������ � ����������
        $chunk =~ s/\s*([\{\}\(\)\[\]\*\/\+\-\,\;\=\!\%])\s*/$1/g;
        # ������� ����������� semicolon
        $chunk =~ s/;\}/\}/g;
        # ������� ��������� ������� � �������� �����
        $chunk =~ s/^\s+//;
        # ������� ��������� ������� � �������� �����
        $chunk =~ s/\s+$//;
        return $chunk;
    });
}

