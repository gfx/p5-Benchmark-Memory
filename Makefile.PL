use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Benchmark/Memory.pm';

requires 'JSON';

test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive;
author_tests 'xt';

#auto_set_repository() if -d '.git';

clean_files qw(
    Benchmark-Memory-* *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
