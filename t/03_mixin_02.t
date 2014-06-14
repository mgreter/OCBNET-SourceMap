# -*- perl -*-

use strict;
use warnings;

# documents an expected behaviour
# we may insert markers for end of file
# if you append some other file, this marker
# will be pushed further away (looking like
# the second file was inserted into the first)

use Test::More tests => 39;
BEGIN { use_ok('OCBNET::SourceMap::V3') };
BEGIN { use_ok('OCBNET::SourceMap::Utils') };

my $smap1 = bless({
	'names' => [],
	'sources' => [ 'input1.js' ],
	'mappings' => [
		# file start at first line
		[ [ 0, 0, 0, 0 ] ],
		# has a second line
		[],
		# empty last line
		# with eof indicator
		[ [ 0, 0, 2, 0 ] ]
	],
	'version' => 3,
	'lineCount' => 3
}, 'OCBNET::SourceMap::V3' );

my $smap2 = bless({
	'names' => [],
	'sources' => [ 'input2.js' ],
	'mappings' => [
		# file start at first line
		[ [ 0, 0, 0, 0 ] ],
		# has a second line
		[],
		# empty last line
		# with eof indicator
		[ [ 0, 0, 2, 0 ] ]
	],
	'version' => 3,
	'lineCount' => 3
}, 'OCBNET::SourceMap::V3' );


my $smap = OCBNET::SourceMap->new;

########################################################################################################################

is    ($smap->{'lineCount'},                     0,            'got the correct line count');
is    (scalar(@{$smap->{'mappings'}}),           0,            'mappings array has correct item count');

########################################################################################################################
$smap->mixin([0,0],[0,0],$smap1);
########################################################################################################################

is    ($smap->{'lineCount'},                     3,            'got the correct line count');
is    (scalar(@{$smap->{'mappings'}}),           3,            'mappings array has correct item count');

is    (scalar(@{$smap->{'sources'}}),            1,            'sources array has correct item count');
is    ($smap->{'sources'}->[0],                  'input1.js',  'sources index 0 is set to input1.js');

is    (scalar(@{$smap->{'mappings'}->[0]}),      1,            'mappings line 0 array has correct group count');
is    ($smap->{'mappings'}->[0]->[0]->[0],       0,            'offset is correct');
is    ($smap->{'mappings'}->[0]->[0]->[1],       0,            'source is correct');

is    (scalar(@{$smap->{'mappings'}->[1]}),      0,            'mappings line 1 array has correct group count');

is    (scalar(@{$smap->{'mappings'}->[2]}),      1,            'mappings line 2 array has correct group count');
is    ($smap->{'mappings'}->[2]->[0]->[0],       0,            'offset is correct');
is    ($smap->{'mappings'}->[2]->[0]->[1],       0,            'source is correct');

########################################################################################################################
$smap->mixin([2,0],[0,0],$smap2);
########################################################################################################################

is    ($smap->{'lineCount'},                     5,            'got the correct line count');
is    (scalar(@{$smap->{'mappings'}}),           5,            'mappings array has correct item count');

is    (scalar(@{$smap->{'sources'}}),            2,            'sources array has correct item count');
is    ($smap->{'sources'}->[0],                  'input1.js',  'sources index 0 is set to input1.js');
is    ($smap->{'sources'}->[1],                  'input2.js',  'sources index 1 is set to input2.js');

is    (scalar(@{$smap->{'mappings'}->[0]}),      1,            'mappings line 1 array has correct group count');
is    ($smap->{'mappings'}->[0]->[0]->[0],       0,            'offset is correct');
is    ($smap->{'mappings'}->[0]->[0]->[1],       0,            'source is correct');

is    (scalar(@{$smap->{'mappings'}->[1]}),      0,            'mappings line 1 array has correct group count');

is    (scalar(@{$smap->{'mappings'}->[2]}),      1,            'mappings line 2 array has correct group count');
is    ($smap->{'mappings'}->[2]->[0]->[0],       0,            'dest offset is correct');
is    ($smap->{'mappings'}->[2]->[0]->[1],       1,            'original source is correct');
is    ($smap->{'mappings'}->[2]->[0]->[2],       0,            'original row is correct');
is    ($smap->{'mappings'}->[2]->[0]->[3],       0,            'original col is correct');

is    (scalar(@{$smap->{'mappings'}->[3]}),      0,            'mappings line 3 array has correct group count');

is    (scalar(@{$smap->{'mappings'}->[4]}),      2,            'mappings line 4 array has correct group count');
is    ($smap->{'mappings'}->[4]->[0]->[0],       0,            'dest offset is correct');
is    ($smap->{'mappings'}->[4]->[0]->[1],       1,            'original source is correct');
is    ($smap->{'mappings'}->[4]->[0]->[2],       2,            'original row is correct');
is    ($smap->{'mappings'}->[4]->[0]->[3],       0,            'original col is correct');
is    ($smap->{'mappings'}->[4]->[1]->[0],       0,            'dest offset is correct');
is    ($smap->{'mappings'}->[4]->[1]->[1],       0,            'original source is correct');
is    ($smap->{'mappings'}->[4]->[1]->[2],       2,            'original row is correct');
is    ($smap->{'mappings'}->[4]->[1]->[3],       0,            'original col is correct');

1;