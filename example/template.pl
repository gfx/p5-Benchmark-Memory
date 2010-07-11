#!perl -w

use strict;
use Benchmark::Memory;

use Text::Xslate;
use Text::MicroTemplate::Extended;
use Template;

use File::Find qw(find);
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

system $^X, "$Bin/mk_template.pl"
    if not -e "$path/large.tx";

find sub {
    unlink $_ if /\.txc$/ or /\.out/;
}, $path;

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
    for my $count(1, 2) {
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
