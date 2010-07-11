#!perl -w
use strict;
use FindBin qw($Bin);

my $path = "$Bin/template";

sub slurp {
    my($file) = @_;
    open my $in, '<', $file;
    local $/;
    <$in>;
}

for my $suffix(qw(tt mt tx)) {
    my $tiny_content    = slurp("$path/tiny.$suffix");
    my $include_content = slurp("$path/include.$suffix");

    print "make large.$suffix\n";
    open my $large, '>', "$path/large.$suffix";
    for my $i(1 .. 128) {
        print "make tiny$i.$suffix\n";

        open my $tiny, ">", "$path/tiny$i.$suffix";
        print $tiny $tiny_content;
        close $tiny;

        my $s = $include_content;
        $s =~ s/tiny\./tiny$i\./;
        print $large $s;
    }
    close $large;
}
