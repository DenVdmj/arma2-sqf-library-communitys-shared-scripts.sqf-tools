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
    my $minifiedFilename     = $target || "$source.(minified).sqf";
    my $sourceText = readfile($source);
    local *hndlMCPP;
    open (hndlMCPP, qq(| "./bin/mcpp.exe" -P -+ >$preprocessedFilename));
    print hndlMCPP $sourceText;
    close (hndlMCPP);
    my $packedtext = sqfpack(readfile($preprocessedFilename));
    writefile($packedFilename, $packedtext);
    writefile($minifiedFilename, minifyVarNames($packedtext));
}

sub sqfpack {
    return sqflockup(shift, sub {
        my $chunk = shift;
        # сжать пробелы и переводы строк
        $chunk =~ s/\s\s+/ /g;
        # сжать пробелы до и после скобок и операторов
        $chunk =~ s/\s*([\{\}\(\)\[\]\*\/\+\-\,\;\=\!\%])\s*/$1/g;
        # удалить завершающий semicolon
        $chunk =~ s/;\}/\}/g;
        # удалить стартовые пробелы и переводы строк
        $chunk =~ s/^\s+//;
        # удалить финальные пробелы и переводы строк
        $chunk =~ s/\s+$//;
        return $chunk;
    });
}

sub minifyVarNames {
    my $text = shift;
    my $names = {};
    my $counter = 0;
    $text =~ s/(_\w+)/_X$1/g;
    $text =~ s{\b(_\w+)\b}{
        my $varname = $1;
        my $varnamelc = lc $varname;
        $names->{$varnamelc} = '_' . intToBase36($counter++)
            unless defined $names->{$varnamelc};
        $names->{$varnamelc};
    }egis;
    return $text;
}

BEGIN {

    my @basechars = map { chr $_ } (48 .. 57, 65 .. 90, 97 .. 122, 95);

    sub intToRadix {
        my ($number, $radix, @range) = @_;
        my $offset = @range && length @range == 1 ? 10 : 0;
        my @chars = @range && length @range > 1 ? map { chr $_ } @range : @basechars;
        my $result = '';
        $radix = 16 unless $radix;
        while ($number) {
            $result = @chars [ $offset + int ( $number % $radix ) ] . $result;
            $number = int ($number / $radix);
        }
        return $result || 0;
    }

    sub intToBase36 {
        return intToRadix(shift, 36);
    }
}





