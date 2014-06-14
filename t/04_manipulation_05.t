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
$smap->mixin([0, 0], [0, 0], $smap1);
$smap->mixin([1, 0], [0, 0], $smap2);

# substr equivalent
substr($data, 0, 0, $data1);
substr($data, 7, 0, $data2);
# die '[' . $data . ']';
# => "A B C \n X Y Z\n"

is    (scalar(@{$smap->{'sources'}}),            2,       'sources array has correct item count');
is    ($smap->{'sources'}->[0],                  'DATA1', 'sources index 0 is set to DATA1');
is    ($smap->{'sources'}->[1],                  'DATA2', 'sources index 1 is set to DATA2');

is    (scalar(@{$smap->{'names'}}),              6,       'names array has correct item count');
is    ($smap->{'names'}->[0],                    'A',     'names index 0 is set to token A');
is    ($smap->{'names'}->[1],                    'B',     'names index 1 is set to token B');
is    ($smap->{'names'}->[2],                    'C',     'names index 2 is set to token C');
is    ($smap->{'names'}->[3],                    'X',     'names index 3 is set to token X');
is    ($smap->{'names'}->[4],                    'Y',     'names index 4 is set to token Y');
is    ($smap->{'names'}->[5],                    'Z',     'names index 5 is set to token Z');


# exit;

is    (scalar(@{$smap->{'mappings'}}),           3,       'mappings array has correct line count');

is    (scalar(@{$smap->{'mappings'}->[0]}),      3,       'mappings line 0 array has correct group count');
is    ($smap->{'mappings'}->[0]->[0]->[4],       0,       'name 1 is correct'); # A
is    ($smap->{'mappings'}->[0]->[0]->[1],       0,       'source 1 is correct'); # 0
is    ($smap->{'mappings'}->[0]->[0]->[0],       0,       'offset 1 is correct'); # A
is    ($smap->{'mappings'}->[0]->[1]->[4],       1,       'name 2 is correct'); # B
is    ($smap->{'mappings'}->[0]->[1]->[1],       0,       'source 2 is correct'); # 0
is    ($smap->{'mappings'}->[0]->[1]->[0],       2,       'offset 2 is correct'); # B
is    ($smap->{'mappings'}->[0]->[2]->[4],       2,       'name 3 is correct'); # C
is    ($smap->{'mappings'}->[0]->[2]->[1],       0,       'source 3 is correct'); # 0
is    ($smap->{'mappings'}->[0]->[2]->[0],       4,       'offset 3 is correct'); # C

is    (scalar(@{$smap->{'mappings'}->[1]}),      3,       'mappings line 1 array has correct group count');
is    ($smap->{'mappings'}->[1]->[0]->[4],       3,       'name 4 is correct'); # X
is    ($smap->{'mappings'}->[1]->[0]->[1],       1,       'source 4 is correct'); # 1
is    ($smap->{'mappings'}->[1]->[0]->[0],       1,       'offset 4 is correct'); # X
is    ($smap->{'mappings'}->[1]->[1]->[4],       4,       'name 5 is correct'); # Y
is    ($smap->{'mappings'}->[1]->[1]->[1],       1,       'source 5 is correct'); # 1
is    ($smap->{'mappings'}->[1]->[1]->[0],       3,       'offset 5 is correct'); # Y
is    ($smap->{'mappings'}->[1]->[2]->[4],       5,       'name 6 is correct'); # Z
is    ($smap->{'mappings'}->[1]->[2]->[1],       1,       'source 6 is correct'); # 1
is    ($smap->{'mappings'}->[1]->[2]->[0],       5,       'offset 6 is correct'); # Z

is    (scalar(@{$smap->{'mappings'}->[2]}),      0,       'mappings line 2 array has correct group count');
