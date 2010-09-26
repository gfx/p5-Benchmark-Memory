#!perl -w
use strict;
use Benchmark::Memory;

for my $count(1, 100) {
    print "Memory usage for $count ",
        $count == 1 ? "class" : "classes", ":\n";
    cmpthese $count => {
        Moose => q{
            use Moose;
            has [qw(foo bar baz)] => (
                is  => 'rw',
                isa => 'Str',
            );
            no Moose;
        },

        Mouse => [ 'Moose'
            => sub { s/\b Moose \b/Mouse/xmsg } ],

        'Moose/im' => [ 'Moose'
            => sub{ $_ .= '__PACKAGE__->meta->make_immutable();' } ],

        'Mouse/im' => [ 'Moose'
            => sub {
                 s/\b Moose \b/Mouse/xmsg;
                 $_ .= '__PACKAGE__->meta->make_immutable();';
           } ],
    };
}
