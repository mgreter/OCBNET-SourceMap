# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 51;
BEGIN { use_ok('OCBNET::SourceMap::V3') };
BEGIN { use_ok('OCBNET::SourceMap::Utils') };

my $smap = OCBNET::SourceMap->new;

my $data = '';

my $data1 = "A B C ";
my $data2 = " X Y Z";

my $smap1 = tokenize($data1, 'DATA1');
my $smap2 = tokenize($data2, 'DATA2');

####### prepend operation ##########
$smap->mixin([0, 0], [0, 0], $smap2);
$smap->mixin([0, 0], [0, 0], $smap1);

# substr equivalent
substr($data, 0, 0, $data2);
substr($data, 0, 0, $data1);
# die '[' . $data . ']';
# => "A B C  X Y Z"

is    (scalar(@{$smap->{'sources'}}),            2,       'sources array has correct item number');
is    ($smap->{'sources'}->[0],                  'DATA2', 'sources index 0 is set to STDIN2');
is    ($smap->{'sources'}->[1],                  'DATA1', 'sources index 1 is set to STDIN1');

is    (scalar(@{$smap->{'names'}}),              6,       'names array has correct item number');
is    ($smap->{'names'}->[0],                    'X',     'names index 0 is set to token A');
is    ($smap->{'names'}->[1],                    'Y',     'names index 1 is set to token B');
is    ($smap->{'names'}->[2],                    'Z',     'names index 2 is set to token C');
is    ($smap->{'names'}->[3],                    'A',     'names index 3 is set to token A');
is    ($smap->{'names'}->[4],                    'B',     'names index 4 is set to token B');
is    ($smap->{'names'}->[5],                    'C',     'names index 5 is set to token C');

is    (scalar(@{$smap->{'mappings'}}),           1,       'mappings array has correct line number');
is    (scalar(@{$smap->{'mappings'}->[0]}),      8,       'mappings line array has correct group number');
is    ($smap->{'mappings'}->[0]->[0]->[4],       3,       'name 0 is correct'); # A
is    ($smap->{'mappings'}->[0]->[0]->[1],       1,       'source 0 is correct'); # 1
is    ($smap->{'mappings'}->[0]->[0]->[0],       0,       'offset 0 is correct'); # A
is    ($smap->{'mappings'}->[0]->[1]->[4],       4,       'name 1 is correct'); # B
is    ($smap->{'mappings'}->[0]->[1]->[1],       1,       'source 1 is correct'); # 1
is    ($smap->{'mappings'}->[0]->[1]->[0],       2,       'offset 1 is correct'); # B
is    ($smap->{'mappings'}->[0]->[2]->[4],       5,       'name 2 is correct'); # C
is    ($smap->{'mappings'}->[0]->[2]->[1],       1,       'source 2 is correct'); # 1
is    ($smap->{'mappings'}->[0]->[2]->[0],       4,       'offset 2 is correct'); # C
is    ($smap->{'mappings'}->[0]->[3]->[0],       6,       'offset 3 is correct'); # EOF
is    ($smap->{'mappings'}->[0]->[4]->[4],       0,       'name 4 is correct'); # X
is    ($smap->{'mappings'}->[0]->[4]->[1],       0,       'source 4 is correct'); # 0
is    ($smap->{'mappings'}->[0]->[4]->[0],       7,       'offset 4 is correct'); # X
is    ($smap->{'mappings'}->[0]->[5]->[4],       1,       'name 5 is correct'); # Y
is    ($smap->{'mappings'}->[0]->[5]->[1],       0,       'source 5 is correct'); # 0
is    ($smap->{'mappings'}->[0]->[5]->[0],       9,       'offset 5 is correct'); # Y
is    ($smap->{'mappings'}->[0]->[6]->[4],       2,       'name 6 is correct'); # Z
is    ($smap->{'mappings'}->[0]->[6]->[1],       0,       'source 6 is correct'); # 0
is    ($smap->{'mappings'}->[0]->[6]->[0],       11,      'offset 6 is correct'); # Z
is    ($smap->{'mappings'}->[0]->[7]->[0],       12,      'offset 7 is correct'); # EOF

####### remove operation ##########
$smap->mixin([0, 5], [0, 1], undef);
substr($data, 5, 1, '');
# die '[' . $data . ']';
# => "A B C X Y Z"

is    (scalar(@{$smap->{'mappings'}->[0]}),      8,       'mappings line array has correct group number');
is    ($smap->{'mappings'}->[0]->[0]->[0],       0,       '2: offset 0 is correct'); # A
is    ($smap->{'mappings'}->[0]->[1]->[0],       2,       '2: offset 1 is correct'); # B
is    ($smap->{'mappings'}->[0]->[2]->[0],       4,       '2: offset 2 is correct'); # C
is    ($smap->{'mappings'}->[0]->[3]->[0],       5,       '2: offset 3 is correct'); # EOF
is    ($smap->{'mappings'}->[0]->[4]->[0],       6,       '2: offset 4 is correct'); # X
is    ($smap->{'mappings'}->[0]->[5]->[0],       8,       '2: offset 5 is correct'); # Y
is    ($smap->{'mappings'}->[0]->[6]->[0],       10,      '2: offset 6 is correct'); # Z
is    ($smap->{'mappings'}->[0]->[7]->[0],       11,      '2: offset 7 is correct'); # EOF

####### remove operation ##########
$smap->mixin([0, 0], [0, 1], undef);
substr($data, 0, 1, '');
#die '[' . $data . ']';
# => " B C X Y Z"

is    (scalar(@{$smap->{'mappings'}->[0]}),      7,       'mappings line array has correct group number');
is    ($smap->{'mappings'}->[0]->[0]->[0],       1,       '3: offset 1 is correct'); # B
is    ($smap->{'mappings'}->[0]->[1]->[0],       3,       '3: offset 2 is correct'); # C
is    ($smap->{'mappings'}->[0]->[2]->[0],       4,       '3: offset 3 is correct'); # EOF
is    ($smap->{'mappings'}->[0]->[3]->[0],       5,       '3: offset 4 is correct'); # X
is    ($smap->{'mappings'}->[0]->[4]->[0],       7,       '3: offset 5 is correct'); # Y
is    ($smap->{'mappings'}->[0]->[5]->[0],       9,       '3: offset 6 is correct'); # Z
is    ($smap->{'mappings'}->[0]->[6]->[0],       10,      '3: offset 7 is correct'); # EOF
