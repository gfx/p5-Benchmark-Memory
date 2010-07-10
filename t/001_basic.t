#!perl -w

use strict;
use Test::More;

use Benchmark::Memory;

my $bm = Benchmark::Memory->new();
my $result = $bm->execute(1,
    foo => q{ '.' x 1000000 },
);

my $r = $bm->report($result);
note $r;
like $r, qr/\b foo \b/xms;


done_testing;
