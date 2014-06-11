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

####################################################################################################
####################################################################################################
1;