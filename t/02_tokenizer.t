# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 40;
BEGIN { use_ok('OCBNET::SourceMap::Utils') };

use OCBNET::SourceMap::Utils qw(tokenize debugger);

my $smap = tokenize("A B C", 'STDIN');

ok    (exists $smap->{'names'},                           'names exists');
ok    (exists $smap->{'sources'},                         'sources exists');
ok    (exists $smap->{'mappings'},                        'mappings exists');
ok    (exists $smap->{'lineCount'},                       'lineCount exists');

is    (ref $smap->{'names'},                   'ARRAY',   'names is an array');
is    (ref $smap->{'sources'},                 'ARRAY',   'sources is an array');
is    (ref $smap->{'mappings'},                'ARRAY',   'mappings is an array');

is    ($smap->{'lineCount'},                   1,         'lineCount is set correctly');

is    (scalar(@{$smap->{'names'}}),            3,         'names array has correct item count');
is    (scalar(@{$smap->{'sources'}}),          1,         'sources array has correct item count');
is    (scalar(@{$smap->{'mappings'}}),         1,         'mappings array has correct line count');
is    (scalar(@{$smap->{'mappings'}->[0]}),    4,         'mappings line array has correct group count');

is    ($smap->{'sources'}->[0],                'STDIN',   'sources index 0 is set to STDIN');

is    ($smap->{'names'}->[0],                  'A',       'names index 0 is set to token A');
is    ($smap->{'names'}->[1],                  'B',       'names index 1 is set to token B');
is    ($smap->{'names'}->[2],                  'C',       'names index 2 is set to token C');

my $tokenA = $smap->{'mappings'}->[0]->[0];
my $tokenB = $smap->{'mappings'}->[0]->[1];
my $tokenC = $smap->{'mappings'}->[0]->[2];
my $tokenEOL = $smap->{'mappings'}->[0]->[3];

ok    ($tokenA,                                           'tokenA is available');
ok    ($tokenB,                                           'tokenB is available');
ok    ($tokenC,                                           'tokenC is available');
ok    ($tokenEOL,                                         'tokenEOL is available');

is    ($tokenA->[0],                           0,         'tokenA dest offset is correct');
is    ($tokenA->[1],                           0,         'tokenA source file is correct');
is    ($tokenA->[2],                           0,         'tokenA source row is correct');
is    ($tokenA->[3],                           0,         'tokenA source col is correct');
is    ($tokenA->[4],                           0,         'tokenA name index is correct');

is    ($tokenB->[0],                           2,         'tokenB dest offset is correct');
is    ($tokenB->[1],                           0,         'tokenB source file is correct');
is    ($tokenB->[2],                           0,         'tokenB source row is correct');
is    ($tokenB->[3],                           2,         'tokenB source col is correct');
is    ($tokenB->[4],                           1,         'tokenB name index is correct');

is    ($tokenC->[0],                           4,         'tokenC dest offset is correct');
is    ($tokenC->[1],                           0,         'tokenC source file is correct');
is    ($tokenC->[2],                           0,         'tokenC source row is correct');
is    ($tokenC->[3],                           4,         'tokenC source col is correct');
is    ($tokenC->[4],                           2,         'tokenC name index is correct');

is    ($tokenEOL->[0],                         5,         'tokenEOL dest offset is correct');
is    ($tokenEOL->[1],                         0,         'tokenEOL source file is correct');
is    ($tokenEOL->[2],                         0,         'tokenEOL source row is correct');
is    ($tokenEOL->[3],                         5,         'tokenEOL source col is correct');
