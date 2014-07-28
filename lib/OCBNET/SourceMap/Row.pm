###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-SourceMap (GPL3)
####################################################################################################
package OCBNET::SourceMap::Row;
####################################################################################################

use utf8;
use strict;
use warnings;

####################################################################################################

sub new
{

	# get package name
	my ($pkg, $parent) = @_;

	# create new hash reference
	my $self = {
		# initialize rows array
		'cols' => [],
		# connect parent node
		'parent' => $parent
	};

	# return blessed object
	return bless $self, $pkg;

}


sub findRightCol
{

	# get input arguments
	my ($row, $off) = @_;

	# search for the column with given offset inside the row
	for (my $col = 0; $col < scalar(@{$row}); $col ++)
	{ return $col if ($row->[$col]->[0] > $off); }

	# not found
	return -1;

}

sub findLeftCol
{

	# get input arguments
	my ($row, $off) = @_;

	# search for the column with given offset inside the row
	my $col = scalar(@{$row}); while($col --)
	{ return $col if ($row->[$col]->[0] < $off); }

	# not found
	return -1;

}

sub addOffset
{

	# get input arguments
	my ($row, $off, $skip) = @_;
	# add offset to all columns after skip offset
	for (my $col = 0; $col < scalar(@{$row}); $col ++)
	{ $row->[$col]->[0] += $off if $row->[$col]->[0] >= ($skip || -1); }

}


####################################################################################################
####################################################################################################
1;