###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-SourceMap (GPL3)
####################################################################################################
package OCBNET::SourceMap::V3;
####################################################################################################
use base 'OCBNET::SourceMap';
####################################################################################################
use OCBNET::SourceMap::VLQ qw(decodeVLQ encodeVLQ);
####################################################################################################

use utf8;
use strict;
use warnings;

####################################################################################################

sub init
{

	my ($smap) = @_;

	$smap->{'version'} = 3;

	$smap->SUPER::init();

	return $smap;

}

sub decoder
{

	my ($smap, $json) = @_;

	# map the mappings string to
	# the real mapping values, which
	# are still offset from each other

	my $maps = [ map { [
	                     map { decodeVLQ($_) }
	                     split /\s*,\s*/, $_
	                 ] }
	                 split /\s*;\s*/,
	                 $json->{'mappings'}
	           ];

	$smap->{'mappings'} = $maps;

	$smap->{'names'} = $json->{'names'};
	$smap->{'sources'} = $json->{'sources'};
	$smap->{'lineCount'} = $json->{'lineCount'};

	$json->{'lineCount'} = $#{$smap->{'mappings'}} unless defined $json->{'lineCount'};
	$#{$smap->{'mappings'}} = $json->{'lineCount'} if defined $json->{'lineCount'};

}

# return format version
sub version { return 3 }

####################################################################################################
####################################################################################################
1;