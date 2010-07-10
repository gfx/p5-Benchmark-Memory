#!perl -w

use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Benchmark::Memory' }

diag "Testing Benchmark::Memory/$Benchmark::Memory::VERSION";
