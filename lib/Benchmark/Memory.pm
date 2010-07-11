package Benchmark::Memory;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(Exporter);
our @EXPORT = qw(cmpthese d);

use Carp       qw(croak);
use IPC::Open3 qw(open3);
use JSON         ();

our $GUTS = __PACKAGE__;

my $trace = $ENV{BM_TRACE} || 0;

sub d {
    require Data::Dumper;
    my $dd = Data::Dumper->new([\@_], ['*args']);
    $dd->Indent(0);
    $dd->Purity(1);
    return sprintf 'do{ my %s; @args }', $dd->Dump();
}

sub new {
    my($class) = @_;

    return bless {
        mstat_class => 'Benchmark::Memory::Procfs',
    }, $class;
}

sub cmpthese {
    my $bm = $GUTS->new();
    my $result = $bm->execute(@_);
    print $bm->report($result);
    return;
}

sub execute {
    my $self  = shift;
    my $count = shift;
    my @map;

    if(@_ == 1) {
        my($ref) = @_;
        if(ref $ref eq 'ARRAY') {
            @map = @{$ref};
        }
        else {
            foreach my $name(sort keys %{$ref}) {
                push @map, $name => $ref->{$name};
            }
        }
    }
    else {
        @map = @_;
    }

    my %map = @map;
    my %result;

    while(my($name, $code) = splice @map, 0, 2) {
        print STDERR "$name:\n" if $trace;

        if(ref $code eq 'ARRAY') {
            my($proto, $filter) = @{$code};
            local $_ = $map{$proto}
                or croak("'$proto' does not exist");

            if(ref $_) {
                croak("Cannot apply a filter to another filter");
            }

            $filter->();
            $code = $_;
        }
        elsif(ref $code) {
            croak("Code for '$name' must be a source code");
        }

        $result{$name} = $self->_eval($count, $name, $code);
    }
    return \%result;
}

my $ns_tmpl = __PACKAGE__ . '::_tmp%d';
my $ns_id   = 0;

sub _eval {
    my($self, $count, $name, $code) = @_;

    local(*CIN, *COUT, *CERR);

    my $pid = open3(\*CIN, \*COUT, \*CERR, $^X);

    printf CIN <<'CODE', $self->{mstat_class}, join(", ", map { "q{$_}" } @INC), strict::bits(qw(vars refs subs));
my($mstat, $m0, $pu0, $ps0, $cu0, $cs0);
BEGIN{
    @INC = (%2$s);
    require %1$s;
    $mstat                   = %1$s->new();
    $m0                      = $mstat->memory_usage();
    ($pu0, $ps0, $cu0, $cs0) = times();

    $^H                     |= %3$d; # use strict
}
CODE

    foreach my $c(1 .. $count) {
            my $ns = sprintf $ns_tmpl, ++$ns_id;
            printf CIN <<'CODE', $name, $c, $ns, $code;
# %s (%d)
package %s;
{
%s
}
CODE

    }

    print CIN <<'CODE';
my($pu1, $ps1, $cu1, $cs1) = times();
my $m1                     = $mstat->memory_usage();
my %result = (
    memory => $m1  - $m0,
    pu     => $pu1 - $pu0,
    ps     => $ps1 - $ps0,
    cu     => $cu1 - $cu0,
    cs     => $cs1 - $cs0,
);
require 'JSON.pm';
print JSON->new()->encode(\%result);
CODE
    close CIN;

    my($cout, $cerr);
    {
        local $/;
        $cout = <COUT>;
        close COUT;
        $cerr = <CERR>;
        close CERR;
    }

    if($cerr) {
        croak("Failed to eval for '$name':\n"
            . "Source:\n"
            . $code
            . "Error:\n"
            . $cerr);
    }

    my $json = JSON->new()->decode($cout);
    # valide it here?
    return $json;
}

my $B   = 2 **   1;
my $KiB = 2 **  10;
my $MiB = 2 **  20;

sub report {
    my($self, $result) = @_;

    my $s = '';

    my $name_len = 0;
    foreach my $name(keys %{$result}) {
        if($name_len < length($name)) {
            $name_len = length($name);
        }
    }

    my $max_memory = 0;
    foreach my $r(values %{$result}) {
        if($max_memory < $r->{memory}) {
            $max_memory = $r->{memory};
        }
    }

    my $scale_tag;
    my $scale;
    if($max_memory >= $MiB) {
        $scale_tag = 'MiB';
        $scale     = $MiB;
    }
    elsif($max_memory >= $KiB) {
        $scale_tag = 'KiB';
        $scale     = $KiB;
    }
    else {
        $scale_tag = 'B';
        $scale     = $B;
    };

    foreach my $name( sort keys %{$result} ) {
        my $r = $result->{$name};
        $s .= sprintf "%-${name_len}s: %8.03f $scale_tag (times: user=%.03f, sys=%.03f)\n",
            $name, $r->{memory} / $scale, $r->{pu}, $r->{ps};
    }

    return $s;
}

1;
__END__

=head1 NAME

Benchmark::Memory - Measures memory usage of Perl code

=head1 VERSION

This document describes Benchmark::Memory version 0.01.

=head1 SYNOPSIS

    use Benchmark::Memory;

    cmpthese 5 => {
        Moose => q{
            use Moose;
            has [qw(foo bar)] => (
                is  => 'rw',
                isa => 'Str',
            );
            __PACKAGE__->meta->make_immutable();
        },

        Mouse => [ Moose => sub { s/\b Moose \b/Mouse/xmsg } ],
    };

=head1 DESCRIPTION

Benchmark::Memory provides blah blah blah.

=head1 INTERFACE

=head2 Class methods

=over 4

=item *

=back

=head2 Instance methods

=over 4

=item *

=back


=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
