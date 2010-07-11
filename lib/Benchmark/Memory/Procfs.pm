package Benchmark::Memory::Procfs;
BEGIN{ $^H |= 0x0602; } # use strict

sub new {
    my($class) = @_;
    return bless {}, $class;
}

sub proc_stat {
    my($self, $pid) = @_;
    $pid = $$ unless defined $pid;
    return "/proc/$pid/stat";
}

sub memory_usage {
    my($self) = @_;

    open my $in, '<', $self->proc_stat;
    my $mstat = (split ' ', <$in>)[22];
    close $in;

    return $mstat;
}

1;
