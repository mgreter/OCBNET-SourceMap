# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 34;
BEGIN { use_ok('OCBNET::SourceMap::V3') };
BEGIN { use_ok('OCBNET::SourceMap::Utils') };

my $smap = OCBNET::SourceMap->new;

my $data = '';

my $data1 = "A B C \n";
my $data2 = " X Y Z\n";

my $smap1 = tokenize($data1, 'DATA1');
my $smap2 = tokenize($data2, 'DATA2');

####### prepend operation ##########
$smap->mixin([0, 0], [0, 0], $smap2);
$smap->mixin([0, 3], [0, 0], $smap1);

# substr equivalent
substr($data, 0, 0, $data2);
substr($data, 3, 0, $data1);
# die '[' . $data . ']';
# => " X A B C\nY Z\n"

is    (scalar(@{$smap->{'sources'}}),            2,       'sources array has correct item count');
is    ($smap->{'sources'}->[0],                  'DATA2', 'sources index 0 is set to STDIN2');
is    ($smap->{'sources'}->[1],                  'DATA1', 'sources index 1 is set to STDIN1');

is    (scalar(@{$smap->{'names'}}),              6,       'names array has correct item count');
is    ($smap->{'names'}->[0],                    'X',     'names index 0 is set to token A');
is    ($smap->{'names'}->[1],                    'Y',     'names index 1 is set to token B');
is    ($smap->{'names'}->[2],                    'Z',     'names index 2 is set to token C');
is    ($smap->{'names'}->[3],                    'A',     'names index 3 is set to token A');
is    ($smap->{'names'}->[4],                    'B',     'names index 4 is set to token B');
is    ($smap->{'names'}->[5],                    'C',     'names index 5 is set to token C');

is    (scalar(@{$smap->{'mappings'}}),           3,       'mappings array has correct line count');

is    (scalar(@{$smap->{'mappings'}->[0]}),      4,       'mappings line 0 array has correct group count');
is    ($smap->{'mappings'}->[0]->[0]->[4],       0,       'name 0 is correct'); # X
is    ($smap->{'mappings'}->[0]->[0]->[1],       0,       'source 0 is correct'); # 0
is    ($smap->{'mappings'}->[0]->[0]->[0],       1,       'offset 0 is correct'); # X
is    ($smap->{'mappings'}->[0]->[1]->[4],       3,       'name 1 is correct'); # A
is    ($smap->{'mappings'}->[0]->[1]->[1],       1,       'source 1 is correct'); # 1
is    ($smap->{'mappings'}->[0]->[1]->[0],       3,       'offset 1 is correct'); # A
is    ($smap->{'mappings'}->[0]->[2]->[4],       4,       'name 2 is correct'); # B
is    ($smap->{'mappings'}->[0]->[2]->[1],       1,       'source 2 is correct'); # 1
is    ($smap->{'mappings'}->[0]->[2]->[0],       5,       'offset 2 is correct'); # B
is    ($smap->{'mappings'}->[0]->[3]->[4],       5,       'name 4 is correct'); # C
is    ($smap->{'mappings'}->[0]->[3]->[1],       1,       'source 4 is correct'); # 1
is    ($smap->{'mappings'}->[0]->[3]->[0],       7,       'offset 4 is correct'); # C

is    (scalar(@{$smap->{'mappings'}->[1]}),      2,       'mappings line 1 array has correct group count');
is    ($smap->{'mappings'}->[1]->[0]->[4],       1,       'name 5 is correct'); # Y
is    ($smap->{'mappings'}->[1]->[0]->[1],       0,       'source 5 is correct'); # 0
is    ($smap->{'mappings'}->[1]->[0]->[0],       0,       'offset 5 is correct'); # Y
is    ($smap->{'mappings'}->[1]->[1]->[4],       2,       'name 6 is correct'); # Z
is    ($smap->{'mappings'}->[1]->[1]->[1],       0,       'source 6 is correct'); # 0
is    ($smap->{'mappings'}->[1]->[1]->[0],       2,       'offset 6 is correct'); # Z

is    (scalar(@{$smap->{'mappings'}->[2]}),      0,       'mappings line 2 array has correct group count');
