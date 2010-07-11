#!perl -w

use strict;
use Benchmark::Memory;

my $count = shift(@ARGV) || 1;

print "Memory usage (x $count):\n";
cmpthese $count => {
    Moose => q{
        use Moose;
        has [qw(foo bar)] => (
            is  => 'rw',
            isa => 'Str',
        );
    },

    Mouse => [ Moose => sub { s/\b Moose \b/Mouse/xmsg } ],

    'Moose/im' => q{
        use Moose;
        has [qw(foo bar)] => (
            is  => 'rw',
            isa => 'Str',
        );
        __PACKAGE__->meta->make_immutable();
    },

    'Mouse/im' => [ 'Moose/im' => sub { s/\b Moose \b/Mouse/xmsg } ],
};
