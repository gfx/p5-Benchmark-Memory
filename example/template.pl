#!perl -w
use strict;
use Benchmark::Memory;

use Text::Xslate;
use Text::MicroTemplate::Extended;
use Template;

use FindBin qw($Bin);
use Fatal qw(open close);

use Config; printf "Perl/%vd %s\n", $^V, $Config{archname};

foreach my $mod(qw(
    Text::Xslate
    Text::MicroTemplate
    Text::MicroTemplate::Extended
    Template
)){
    print $mod, '/', $mod->VERSION, "\n";
}

my $path = "$Bin/template";

my @tmpfiles = make_templates($path);
push @tmpfiles, "$path/tiny.txc", "$path/tiny.tt.out";
END{ unlink @tmpfiles }

my @tx_args = (
    path       => [$path],
    cache_dir  =>  $path,
    cache      => 2,
);
my @mt_args = (
    include_path => [$path],
    cache        => 2,
);
my @tt_args = (
    INCLUDE_PATH => [$path],
    COMPILE_EXT  => '.out',
);
my $vars = {
    data => [ ({
            title    => "FOO",
            author   => "BAR",
            abstract => "BAZ",
        }) x 10,
   ],
};

for my $tmpl qw(tiny large) {
    for my $count(qw(first second)) {
        print "Memory Usage for '$tmpl' ($count):\n";
        cmpthese 1 => {
            Xslate => sprintf(q{
                use Text::Xslate;
                my $tx = Text::Xslate->new(%s);
                my $body = $tx->render(%s, %s);
            }, d(@tx_args), d("$tmpl.tx"), d($vars)),

            MTEx => sprintf(q{
                use Text::MicroTemplate::Extended;
                my $mt = Text::MicroTemplate::Extended->new(%s);
                my $body = $mt->render_file(%s, %s);
            }, d(@mt_args), d($tmpl), d($vars)),
            TT => sprintf( q{
                use Template;
                my $tt = Template->new(%s);
                my $body;
                $tt->process(%s, %s, \$body) or die $tt->error;
            }, d(@tt_args), d("$tmpl.tt"), d($vars)),
        };
    }
}

sub slurp {
    my($file) = @_;
    open my $in, '<', $file;
    local $/;
    <$in>;
}

sub make_templates {
    my($path) = @_;

    my @tmpfiles;
    for my $suffix(qw(tt mt tx)) {
        my $tiny_content    = slurp("$path/tiny.$suffix");
        my $include_content = slurp("$path/include.$suffix");

        my $file = "$path/large.$suffix";
        push @tmpfiles, $file;
        push @tmpfiles, $file . 'c'    if $suffix eq 'tx';
        push @tmpfiles, $file . '.out' if $suffix eq 'tt';

        open my $large, '>', $file;
        for my $i(1 .. 128) {
            $file = "$path/tiny$i.$suffix";

            push @tmpfiles, $file;
            push @tmpfiles, $file . 'c'    if $suffix eq 'tx';
            push @tmpfiles, $file . '.out' if $suffix eq 'tt';

            open my $tiny, '>', $file;
            print $tiny $tiny_content;
            close $tiny;

            my $s = $include_content;
            $s =~ s/tiny\./tiny$i\./;
            print $large $s;
        }
        close $large;
    }
    return @tmpfiles;
}
