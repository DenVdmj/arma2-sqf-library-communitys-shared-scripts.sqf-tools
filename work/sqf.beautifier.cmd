@rem='
@"%~dp0/bin/perl.exe" -I"%~dp0lib" "%~dpnx0" %*
@goto:eof
@rem';
use strict;
require 'sqf.utils.pl';

my $targetdir = shift;

die qq(No input directory specified\n) unless $targetdir;
die qq(Input directory not found: "$targetdir"\n) unless -d $targetdir;

my $commands = loadSQFCommands('lib/sqf.commands.lst') or die;

foreachdirs(
    path => $targetdir,
    proc => sub {
        my $fn = shift;
        beautify($fn) if -f $fn && $fn =~ /\.sqf$/
    }
);

sub beautify {

    my $filename = shift;

    print "processing file: $filename\n";

    my $text = readfile($filename);

    my $indent = ' ' x 4;
    my $deep = 0;

    writefile($filename, sqflockup($text, sub {

        my $chunk = shift;

        # indentation and curly brackets
        $chunk =~ s{\s*(?:(\{)|(\})|(\;))\s*}{
            if ($1) {
                "{\n" . $indent x (++$deep);
            } elsif ($2) {
                "\n" . $indent x (--$deep) . "}\n";
            } elsif ($3) {
                ";\n" . $indent x ($deep);
            }
        }egis;

        # single-line "while" code
        $chunk =~ s/while\s*\{\s*([^\{\}\;\n]+)\s*\}/while \{ $1 \}/gis;

        # formatting for other keywords
        $chunk =~ s/while\s*\{/while \{/gis;
        $chunk =~ s/\s*do\s*\{/ do \{/gis;
        $chunk =~ s/if\s*\(/if (/gis;
        $chunk =~ s/\)\s*then\s*\{/) then {/gis;
        $chunk =~ s/\}\s*else\s*\{/} else {/gis;
        $chunk =~ s/\}\s*(foreach|count)\s*/\} $1 /gis;
        $chunk =~ s/\s*(exec|loadfile)\s*\{\s*(.*?)\s*\}/ $1 "$2"/gis;

        # corrects all spaces
        $chunk =~ s/\s+;/;/gis;
        $chunk =~ s/\s*([\&\|=<>!]+)\s*/ $1 /gis;
        $chunk =~ s/(\w+)(\[|\()/$1 $2/gis;
        $chunk =~ s/(\)|\])(\w+)/$1 $2/gis;
        $chunk =~ s/\s*,\s*/, /gis;

        # Круглые скобки не учитываются индетатором, поэтому, если они содержат внутри себя фигурные,
        # то закрывающая круглая скобка отбиваются переводом строки. Подтянем её обратно:
        $chunk =~ s/\s*\n\s*\)/)/gis;

        # reduce all double line breaks
        $chunk =~ s/\n\s*\n+/\n/gis;

        # set double line break for function
        $chunk =~ s/\n(\w+)\s*=\s*\{/\n\n$1 = \{/gis;

        # camelize command names
        $chunk =~ s{\b(\w+)\b}{
            exists $commands->{lc $1} ? $commands->{lc $1} : $1
        }egis;

        return $chunk;
    }));
}

