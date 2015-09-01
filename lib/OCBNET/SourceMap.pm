###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-SourceMap (GPL3)
####################################################################################################
package OCBNET::SourceMap;
####################################################################################################

use utf8;
use strict;
use warnings;

our $VERSION = 0.01;

####################################################################################################
use JSON qw(decode_json encode_json);
use File::Slurp qw(read_file write_file);
####################################################################################################
use OCBNET::SourceMap::VLQ qw(decodeVLQ encodeVLQ);
####################################################################################################

sub new
{

	my ($pkg) = @_;

	my $smap = {};

	bless $smap, $pkg;

	$smap->init();

	return $smap;
}

sub init
{

	my ($smap) = @_;

	# number of source lines
	$smap->{'lineCount'} = 0;
	# array for indexed names
	$smap->{'names'} = [];
	# array for source files
	$smap->{'sources'} = [];
	# array for source mappings
	# one map entry for each line
	$smap->{'mappings'} = [];

	return $smap;

}

###################################################################################################
###################################################################################################

sub read
{

	my ($smap, $source) = @_;

	# get source from scalar
	if (ref $source eq 'SCALAR')
	{
		# unwrap scalar data
		$source = ${$source};
	}
	# maybe also check for IO::File
	elsif (ref $source eq 'GLOB')
	{
		$source = read_file($source);
		die "fatal" unless defined $source;
	}
	# got a ordinary path
	elsif (defined $source)
	{
		$source = read_file($source);
		die "fatal" unless defined $source;
	}

	# decode json data to perl hash
	my $json = decode_json($source);
	die "fatal" unless defined $json;

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

}

###################################################################################################
###################################################################################################

sub render
{

	my ($smap, $source) = @_;

	# create json object
	my $json = new JSON;

	# get the mappins in internal format
	my $mappings = $smap->{'mappings'};

	# convert to VLQ encoding
	$mappings = join "", map
	{
		join (',', map {
			encodeVLQ @{$_}
		} @{$_}) . ';'
	}
	# process "lines"
	@{$mappings};

	# prettify json
	$json->pretty(0);

	# decode json data to perl hash
	$json = $json->encode({
		# version of output format
		'version' => $smap->version,
		# number of source lines
		'lines' => $smap->{'lines'},
		# array for indexed names
		'names' => $smap->{'names'},
		# array for source files
		'sources' => $smap->{'sources'},
		# array for source mappings
		# one map entry for each line
		'mappings' => $mappings,

	});

	# return data
	return $json;

}

###################################################################################################
###################################################################################################

# append more source lines
# also adds a new source file
# this operation has nearly no cost
sub append
{

	# get the data and src path
	my ($smap, $lines, $src_path) = @_;

	# get line count for new source
	my $linecount = scalar @{$lines};

	# get the array index for new source file
	my $src_idx = scalar @{$smap->{'sources'}};

	# add the source path to the index array
	push @{$smap->{'sources'}}, $src_path;

	# increase the overall source line count
	$smap->{'lineCount'} += $linecount;

	# loop for all lines to create mapping
	for (my $i = 0; $i < $linecount; $i++)
	{
		# add the bare minimum mapping
		push @{$smap->{'mappings'}}, [
			0, # Generated column
			$src_idx, # Original file
			$i, # Original line number
			0, # Original column
			# has no original name
		]
	}

}

###################################################################################################
###################################################################################################

sub version
{
	Carp::croak "version not implemented";
}

sub file
{
	Carp::croak "file not implemented";
}

sub lineCount
{
	return $_[0]->{'lineCount'};
}

sub mappings
{
	Carp::croak "mappings not implemented";
}

sub sources
{
	return @{$_[0]->{'sources'}};
}

sub names
{
	return @{$_[0]->{'names'}};
}

####################################################################################################
####################################################################################################
1;
