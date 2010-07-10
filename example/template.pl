#!perl -w

use strict;
use Benchmark::Memory;

use Text::Xslate;
use Text::MicroTemplate::Extended;
use Template;

use FindBin qw($Bin);

my $tmpl = 'include'; # 'include' or 'list'

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

cmpthese 1 => {
    Xslate => sub {
        my $tx = Text::Xslate->new(@tx_args);
        my $body = $tx->render("$tmpl.tx", $vars);
        return;
    },
    MTEx => sub {
        my $mt = Text::MicroTemplate::Extended->new(@mt_args);
        my $body = $mt->render_file($tmpl, $vars);
        return;
    },
    TT => sub {
        my $tt = Template->new(@tt_args);
        my $body;
        $tt->process("$tmpl.tt", $vars, \$body) or die $tt->error;
        return;
    },
};
