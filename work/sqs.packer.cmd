@rem='
@perl.exe "%~dpnx0" %*
@exit
@rem';

use strict;
require 'sqf.utils.pl';

my ($source, $target) = @ARGV;

die qq(File "mcpp.exe" not found \nPlease get mcpp.exe from http://sourceforge.net/projects/mcpp/\n)
    unless -f 'mcpp.exe';

die qq(No input sqf-file specified\n)
    unless $source;

die qq(File not found: "$source"\n)
    unless -f $source;

{
    my $preprocessedFilename = $target || "$source.(preprocessed).sqf";
    my $packedFilename       = $target || "$source.(packed).sqf";
    my $sourceText = readfile($source);
    local *hndlMCPP;
    open (hndlMCPP, qq(| mcpp.exe -P -+ >$preprocessedFilename));
    print hndlMCPP $sourceText;
    close (hndlMCPP);
    writefile($packedFilename, sqf_pack(readfile($preprocessedFilename)));
}

sub sqf_pack {
    return sqf_process(shift, sub {
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

