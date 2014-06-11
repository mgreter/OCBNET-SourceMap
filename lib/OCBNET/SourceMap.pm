###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-SourceMap (GPL3)
####################################################################################################
package OCBNET::SourceMap;
####################################################################################################

use utf8;
use strict;
use warnings;

####################################################################################################
use JSON qw(decode_json encode_json);
use File::Slurp qw(read_file write_file);
####################################################################################################
use OCBNET::SourceMap::VLQ qw(decodeVLQ encodeVLQ);
####################################################################################################
require OCBNET::SourceMap::Map;
require OCBNET::SourceMap::Row;
require OCBNET::SourceMap::Col;
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

	if ($json->{'version'} eq '3')
	{

		# upgrade the object to the given implementation
		bless $smap, 'OCBNET::SourceMap::V3';
		# call decoder method
		$smap->decoder($json);

	}
	else
	{
		# assertion that we load the sourcemap from an existing implemententation
		Carp::croak "source map version ", $json->{'version'}, " not implemented\n";
	}


	$smap->importer;

return $smap;

}

sub importer
{

	my ($smap) = @_;

	my $file = 0;
	my $row = 0;
	my $col= 0;
	my $name = 0;

	foreach my $line (@{$smap->{'mappings'}})
	{
		my $offset = 0;
		foreach (@{$line})
		{
			my $group = [ @{$_} ];
			$_ = [
				$offset += $_->[0],
				$file += $_->[1],
				$row += $_->[2],
				$col += $_->[3]
			];
			next unless defined $group->[4];
			$_->[4] = $name += $group->[4];
		}
	}

}

sub exporter
{

	my ($smap) = @_;

	my $file = 0;
	my $row = 0;
	my $col= 0;
	my $name = 0;

	foreach my $line (@{$smap->{'mappings'}})
	{

		my $offset = 0;

		foreach (@{$line})
		{

			my $group = [ @{$_} ];

			$_ = [
				$_->[0] - $offset,
				$_->[1] - $file ,
				$_->[2] - $row ,
				$_->[3] - $col
				# $_->[4]
			];

			$offset = $group->[0];
			$file = $group->[1];
			$row = $group->[2];
			$col = $group->[3];

			next unless defined $group->[4];
			$_->[4] = $group->[4] - $name;
			$name = $group->[4];

		}
	}

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

	$smap->exporter;

	# convert to VLQ encoding
	$mappings = join "", map
	{
		join (',', map {
			encodeVLQ @{$_}
		} @{$_}) . ';'
	}
	# process "lines"
	@{$mappings};

	$smap->importer;

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
		push @{$smap->{'mappings'}}, [ [
			0, # Generated column
			$src_idx, # Original file
			$i, # Original line number
			0, # Original column
			# has no original name
		] ]
	}

}

###################################################################################################
# insert a generic string into the existing source map
# the string may reference an existing file scope or pass
# a new one. It can also have its own mapping, which
# should then be mixed into the existing source map ...
###################################################################################################

sub mixin
{

	my ($smap, $start, $len, $insert) = @_;

$insert = { 'mappings' => [], 'names' => [], 'sources' => [] } unless defined $insert;

	my $row = $start->[0];
	my $col = $start->[1];

	my $delrow = $len->[0];
	my $delcol = $len->[1];

	# lookup variables
	my $names = 0; my %names;
	my $sources = 0; my %sources;

	# create index of existing names
	foreach (@{$smap->{'names'}})
	{ $names{$_} = $names ++ }
	foreach (@{$smap->{'sources'}})
	{ $sources{$_} = $sources ++ }

	# add new names to index
	foreach (@{$insert->{'names'}})
	{
		# skip if name is known
		next if exists $names{$_};
		# append name to our source map
		push @{$smap->{'names'}}, $_;
		# add name to lookup index
		$names{$_} = $names ++;
	}
	foreach (@{$insert->{'sources'}})
	{
		# skip if name is known
		next if exists $sources{$_};
		# append name to our source map
		push @{$smap->{'sources'}}, $_;
		# add name to lookup index
		$sources{$_} = $sources ++;
	}

	# we may adjust index right now for newmaps?

	# map offset
	my $off = 0;
	my $offset = 0;
	my $relocate = 0;

	# get the source mappings (lines)
	my $oldmaps = $smap->{'mappings'};
	my @newmaps = @{$insert->{'mappings'}};

	my $oldnames = $smap->{'names'};
	my $newnames = $insert->{'names'};

	my $oldsources = $smap->{'sources'};
	my $newsources = $insert->{'sources'};

	while ($delrow --)
	{
		if ($delrow > 0)
		{
			# remove the complete linie
			splice @{$oldmaps}, $row + 1, 1;
		}
		elsif ($delrow == 0)
		{

			push @{$oldmaps->[$row]}, map {

				my @copy = @{$_};

				$copy[0] += $col;

				\ @copy;

			} @{$oldmaps->[$row + 1]};
			# remove leading maps up to delcol from last line

			# remove the complete linie
			splice @{$oldmaps}, $row + 1, 1;

			# move from
			# die "hi";
		}
		else
		{
#			die "eleasd";
		}
	}

	# have offset
	if ($col > 0)
	{

		# search existing cols from left
		foreach my $oldcol (@{$oldmaps->[$row]})
		{
			# increase status variables
			$offset = $oldcol->[0];
			# abort if next group is over $col
			last if $oldcol->[0] >= $col;
#print "OFFSET $offset $col\n";
			$off ++;
		}

	}

	# and current source mapping groups

	if ($delcol > 0)
	{

		while (
			(scalar(@{$oldmaps->[$row]}) > $off) &&
			($oldmaps->[$row]->[$off]->[0] < $delcol + $col)
		)
		{
			splice @{$oldmaps->[$row]}, $off, 1;
		}

		for (my $i = $off; $i < scalar(@{$oldmaps->[$row]}); $i++)
		{
			$oldmaps->[$row]->[$i]->[0] -= $delcol;
		}

	}

# warn "X" x 50;
return $smap unless scalar @newmaps;

	# process each row to insert
	do
	{

		my $line = shift @newmaps;

		#my $offset = $off ? $oldmaps->[$row]->[$off - 1]->[0] : 0;

if ($line)
{

		splice @{$oldmaps->[$row]}, $off, 0, map
		{

			my @copy = @{$_};

			if (scalar(@copy) >= 1) { $copy[1] = $sources{$newsources->[$copy[1]]}; }
			if (scalar(@copy) >= 5) { $copy[4] = $names{$newnames->[$copy[4]]}; }

			$copy[0] += $col;

			\ @copy;

		} @{$line};

		$off += scalar(@{$line});
}

	}
	while (do
	{


		if (scalar(@newmaps))
		{
		# remove trailing tokens to a new line
		my @line = splice @{$oldmaps->[$row]}, $off;

		splice @{$oldmaps}, $row + 1, 0, [ map
		{

			my @copy = @{$_};

			$copy[0] -= $col;

			#if (scalar(@copy) >= 1) { $copy[1] = $sources{$oldsources->[$copy[1]]}; }
			#if (scalar(@copy) >= 5) { $copy[4] = $names{$oldnames->[$copy[4]]}; }

			\ @copy;

		} @line ];
		}
		else
		{

			my $offset = $off ? $oldmaps->[$row]->[$off - 1]->[0] : 0;

			for (my $i = $off; $i < scalar(@{$oldmaps->[$row]}); $i++)
			{
				$oldmaps->[$row]->[$i]->[0] += $offset - $col;
			}
		}

		$row ++; $off = 0; $col = 0;

		scalar(@newmaps)

	});

use Data::Dumper;

#print Dumper($smap);
	return $smap;

}

sub insert
{

	# string may has its own mapping which in turn can have
	# their own sources, so we need the whole object or maybe
	# we really just need the contexts and the mappings (names)?

	my ($smap, $data, $row, $col, $mapping) = @_;

	# we can just push source mappings after $line
	# we only need to mangle the start and end point

	die "No mapping " unless ($mapping);

	# lookup variables
	my $names = 0; my %names;
	my $sources = 0; my %sources;

	# create index of existing names
	foreach (@{$smap->{'names'}})
	{ $names{$_} = $names ++ }
	foreach (@{$smap->{'sources'}})
	{ $sources{$_} = $sources ++ }

	# add new names to index
	foreach (@{$mapping->{'names'}})
	{
		# skip if name is known
		next if exists $names{$_};
		# append name to our source map
		push @{$smap->{'names'}}, $_;
		# add name to lookup index
		$names{$_} = $names ++;
	}
	foreach (@{$mapping->{'sources'}})
	{
		# skip if name is known
		next if exists $sources{$_};
		# append name to our source map
		push @{$smap->{'sources'}}, $_;
		# add name to lookup index
		$sources{$_} = $sources ++;
	}

	# if we insert after position 0 we have to offset the
	# mappings of the first line in the new source map.

	# some of the original mapping groups may need to
	# go to another line afterwards!!

	# process the input line by line to update mappings
	while ($data ne '' && $data =~ s/^([^\n]*)(\n?)//)
	{

		# store matches into variables
		my ($line, $eol) = ($1, $2);

		# group count and col offset
		my ($pos, $offset) = (0, 0);

		# get the source mappings (lines)
		my $maps = $smap->{'mappings'};
		# and current source mapping groups
		my $groups = $maps->[$row];

		# find map position
		if ($col > 0)
		{

			# need to find offset in current source map
			# to know where we should insert new mappings
			# mappings afterwards (eol?) may need to move

			# process groups from left
			foreach my $group (@{$groups})
			{
				# abort if next group is over $col
				last if $offset + $group->[0] > $col;
				# increase status variables
				$offset += $group->[0]; $pos ++;
			}

		}

die "what 1" if ($pos == 0 && $offset != 0);
# die "what 2" if ($offset == 0 && $pos != 0);

		# get the new mapping groups
		# my $nmap = shift @{$mapping};

		if ($pos == 0)
		{
			die "prepend all";
		}

		if ($pos > scalar(@{$groups}))
		{
			die "append all";


		}

		if ($eol)
		{
			die "move them too a new line";
		}
		elsif ($offset > 0)
		{
			die "offset the rest";
		}

die $groups->[$pos];

# my $offset = $group->[$pos]

# I cannot know how far the actual name index is at this point
# therefore I prefer to have absolute values at this point

			# maybe we should check if it exists first?
			# offset all groups by given col position (new)
			foreach my $group (@{$mapping->{'mappings'}->[0]})
			{
				splice(@{$groups}, $pos, 0,
				[
					$group->[0] + $col, # Generated column
					$sources{$mapping->{'sources'}->[$group->[1]]}, # Original file
					$group->[2], $group->[3], # Original line number and column
					defined $group->[4] ? $names{$mapping->{'names'}->[$group->[4]]} : undef
				]);

				$pos ++;

			}

			if ($eol)
			{
				# move away items from old row to new
				my @row = splice @{$groups}, $pos;
				# normalize the row offsets
				# maybe we can just add, now, we have absolutes
				# we probably need to know where to offset these
				# or we use a row object

				# insert new row into the source mapping
				splice @{$smap->{'mappings'}}, $row, 0, @row;

				die "rest goes on a new line $pos ", scalar(@{$groups}), "!";
			}
#		}
#		else
#		{
#			$smap->{'lineCount'} ++;
#			splice @{$smap->{'mappings'}}, $row, 0, shift @{$mapping->{'mappings'}};
#		}

		# insert now from beginning
		# only first line needs this
		$col = 0; $row ++;

#		die $line;

	}

	# whole line on position 0 can be inserted easily

	if ($col > 0)
	{


	}

	if ($data =~ s/^([^\n]*\n)//)
	{

		die "hi $1";

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
