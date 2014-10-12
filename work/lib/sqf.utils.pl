
sub sqflockup {
    my ($text, $sub) = @_;
    my $even = !0;
    # only for code, but ain`t for a string value
    $text =~ s{(")|([^"]*?)(?="|$)}{
        my $quote = $1;
        my $chunk = $2;
        $even = !$even unless $quote eq "";
        # if current chunk is a code, but not string constant
        $chunk = $sub->($chunk) if $even;
        $quote . $chunk;
    }egs;
    return $text;
}

sub loadSQFCommands {
    my ($filename) = @_;
    local *file;
    open(*file, $filename) or return undef;
    my %commands = map { chomp; lc $_, $_ } <file>;
    close(*file);
    return \%commands;
}

sub readfile {
    my ($filename, $binmode) = @_;
    local *file;
    open(*file, $filename) or return undef;
    binmode *file if $binmode;
    my $string;
    sysread(*file, $string, -s *file);
    close(*file);
    return $string;
}

sub writefile {
    my ($filename, $contents, $binmode) = @_;
    local *file;
    open(*file, "+>$filename");
    binmode *file if $binmode;
    syswrite(*file, $contents, length $contents);
    close(*file);
}

sub foreachdirs {
    # ( path => string, open => sub, proc => sub, close => sub )
    my %option = @_;
    my $deep = 0;

    _traversal($option {'path'});

    sub _traversal {

        my ($path) = @_;

        $option {'proc'} -> ($path, $deep) if $option {'proc'};
        $option {'file'} -> ($path, $deep) if -f $path and $option {'file'};
        $option {'open'} -> ($path, $deep) if -d $path and $option {'open'};

        return unless -d $path;

        local *DIR;

        opendir(*DIR, $path) or die;

        my @filelist = sort {
            -d $path . '\\' . $b cmp -d $path . '\\' . $a
        } readdir(*DIR);

        closedir(*DIR);

        foreach my $filename (@filelist) {
            next if $filename eq '.' or $filename eq '..';
            $deep++;
            _traversal->($path . '\\' . $filename);
            $deep--;
        }

        $option {'close'} -> ($path, $deep) if $option {'close'};
    }
}

1;

