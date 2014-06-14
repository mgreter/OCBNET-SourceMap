# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 19;
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
		[]
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
		[]
	],
	'version' => 3,
	'lineCount' => 3
}, 'OCBNET::SourceMap::V3' );


my $smap = OCBNET::SourceMap->new;

########################################################################################################################
$smap->mixin([0,0],[0,0],$smap1);
########################################################################################################################

is    (scalar(@{$smap->{'sources'}}),            1,            'sources array has correct item count');
is    ($smap->{'sources'}->[0],                  'input1.js',  'sources index 0 is set to input1.js');

is    (scalar(@{$smap->{'mappings'}->[0]}),      1,            'mappings line 0 array has correct group count');
is    ($smap->{'mappings'}->[0]->[0]->[0],       0,            'offset is correct');
is    ($smap->{'mappings'}->[0]->[0]->[1],       0,            'source is correct');

is    (scalar(@{$smap->{'mappings'}->[1]}),      0,            'mappings line 1 array has correct group count');
is    (scalar(@{$smap->{'mappings'}->[2]}),      0,            'mappings line 2 array has correct group count');

########################################################################################################################
$smap->mixin([2,0],[0,0],$smap2);
########################################################################################################################

is    (scalar(@{$smap->{'sources'}}),            2,            'sources array has correct item count');
is    ($smap->{'sources'}->[0],                  'input1.js',  'sources index 0 is set to input1.js');
is    ($smap->{'sources'}->[1],                  'input2.js',  'sources index 1 is set to input2.js');

is    (scalar(@{$smap->{'mappings'}->[0]}),      1,            'mappings line 1 array has correct group count');
is    ($smap->{'mappings'}->[0]->[0]->[0],       0,            'offset is correct');
is    ($smap->{'mappings'}->[0]->[0]->[1],       0,            'source is correct');

is    (scalar(@{$smap->{'mappings'}->[1]}),      0,            'mappings line 1 array has correct group count');

is    (scalar(@{$smap->{'mappings'}->[2]}),      1,            'mappings line 2 array has correct group count');
is    ($smap->{'mappings'}->[0]->[0]->[0],       0,            'offset is correct');
is    ($smap->{'mappings'}->[0]->[0]->[1],       0,            'source is correct');

