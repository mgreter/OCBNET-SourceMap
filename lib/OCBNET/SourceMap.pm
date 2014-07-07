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
require OCBNET::SourceMap::V3;
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

	my ($smap, $lines, $source) = @_;

	$lines = [] unless defined $lines;

	# expect an array reference
	if (!UNIVERSAL::isa ($lines, 'ARRAY'))
	{
		if (UNIVERSAL::isa ($lines, 'SCALAR'))
		{ $lines = [ split /\r?\n/, ${$lines}, -1 ] }
		else { $lines = [ split /\r?\n/, $lines, -1 ] }
	}

	# array for indexed names
	$smap->{'names'} = [];
	# array for source files
	$smap->{'sources'} = $source ? [ $source ] : [];
	# number of source lines
	$smap->{'lineCount'} = scalar(@{$lines});
	# array for source mappings
	# one map entry for each line
	$smap->{'mappings'} = [ map { [] } @{$lines} ];

#die "==", @{$lines};

	if (scalar(@{$smap->{'mappings'}}) > 0)
	{
		my $len = length $lines->[-1];
		push @{$smap->{'mappings'}->[0]}, [ 0, 0, 0, 0 ];
		push @{$smap->{'mappings'}->[-1]}, [ $len, 0, 0, 0 ];
	}

	return $smap;

}


sub init2
{

	my ($smap, $lines, $source) = @_;


	$lines = [] unless defined $lines;

	# expect an array reference
	if (!UNIVERSAL::isa ($lines, 'ARRAY'))
	{
		if (UNIVERSAL::isa ($lines, 'SCALAR'))
		{ $lines = [ split /\r?\n/, ${$lines}, -1 ] }
		else { $lines = [ split /\r?\n/, $lines, -1 ] }
	}

	# array for indexed names
	$smap->{'names'} = [];
	# array for source files
	$smap->{'sources'} = $source?  [ $source ] : [];
	# number of source lines
	$smap->{'lineCount'} = scalar(@{$lines});
	# array for source mappings
	# one map entry for each line
	$smap->{'mappings'} = [ map { [] } @{$lines} ];


	if (scalar(@{$smap->{'mappings'}}) > 0)
	{
		my $idx = $#{$smap->{'mappings'}};
		my $len = length $lines->[$idx];
		push @{$smap->{'mappings'}->[0]}, [ 0, 0, 0, 0 ];
		push @{$smap->{'mappings'}->[$idx]}, [ $len, 0, $idx, 0 ];
	}

	return $smap;

}

###################################################################################################
###################################################################################################

sub read
{

	my ($smap, $json) = @_;

	# check for correct json
	if (ref $json ne 'HASH')
	{
		# get source from scalar
		if (ref $json eq 'SCALAR')
		{
			# unwrap scalar data
			$json = ${$json};
		}
		# maybe also check for IO::File
		elsif (ref $json eq 'GLOB')
		{
			$json = read_file($json);
			die "fatal" unless defined $json;
		}
		# got a ordinary path
		elsif (defined $json)
		{
			$json = read_file($json);
			die "fatal" unless defined $json;
		}
		# decode json data to perl hash
		$json = decode_json($json);
	}

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

####################################################################################################
# we create an access index for each line to speed up look ups
# this brings down the execution time by a factor of 10 to 1000
# define at which offsets (gaps between) to create access point
####################################################################################################

# set to zero to disable
my $index_col_gap = 15;

####################################################################################################

sub remap
{

	my ($cur, $old) = @_;
	print "generating remap\n";

	my ($fid) = (0);



	use Benchmark;
	my $t0 = Benchmark->new;

	my ($a, $b, $c, $d) = (0, 0, 0, 0);
	# die Data::Dumper::Dumper ($old);

	# map index array
	my @old_map_idx;
	# row index array
	my @old_row_idx;

	# build a lookup data structure to speed up
	# lookup for a specific col offset in a row
	my $old_row_len = scalar @{$old->{'mappings'}};

	# process all old row mappings to create an access index
	# this is used to search for a given map at a given offset
	# maps are basically a linked list for each row, so this gives
	# us an initial offset so we do not need to traverse that much
	for(my $old_row = 0; $old_row < $old_row_len; $old_row++)
	{

		# col index array
		my @old_col_idx;

		# process only if worth the price
		if ( $index_col_gap > 0 &&
			# only create for minimal cols to search for later
			scalar(@{$old->{'mappings'}->[$old_row]}) > 10 &&
			# and some minimal maximum col offset (long lines)
			$old->{'mappings'}->[$old_row]->[-1]->[0] > 20
		)
		{
			# next fixed col offset
			# increment by gap offset
			my $nxt_col_off = 0;
			# process all cols from the old mapping line/row
			my $old_col_len = scalar(@{$old->{'mappings'}->[$old_row]});
			for (my $old_col = 0; $old_col < $old_col_len; $old_col++)
			{
				# get the current offset from the original mappings (absolute offset)
				my $cur_col_off = $old->{'mappings'}->[$old_row]->[$old_col]->[0];
				# fill the index if spots are missings
				while ($cur_col_off > $nxt_col_off)
				{
					push @old_col_idx, $old_col - 1;
					$nxt_col_off += $index_col_gap;
				}
				# set the col index for the next spot
				if ($cur_col_off == $nxt_col_off)
				{
					push @old_col_idx, $old_col - 0;
					$nxt_col_off += $index_col_gap;
				}
			}
			# push the col index array to map index
			$old_map_idx[$old_row] = \ @old_col_idx;
		}
		# EO creating old_map_idx

		if ($old->{'new'})
		{

			# pick up original source context
			if (scalar(@{$old->{'mappings'}->[$old_row]}))
			{
				$old_row_idx[$old_row] = $old->{'mappings'}->[$old_row]->[-1];
				$old_row_idx[$old_row]->[2] = 0;
			}
			elsif ($old_row == 0)
			{
				# create initial map for start of file
				$old_row_idx[$old_row] = [ 0,0,0,0 ];
			}
			else
			{
				# get attributes from previous entry (off, src, row, col)
				$old_row_idx[$old_row] = [ @{$old_row_idx[$old_row - 1]} ];
				# increase previous row index by one
				$old_row_idx[$old_row]->[2] ++;
			}

		}
	}
	# EO process old_row_len

my ($x, $y, $z, $foo) = (0,0,0, 0);

	if ($old->{'new'})
	{

		# Carp::confess;
		$old->{'new'} = 0;

		# return $cur;
		foreach my $line (@{$cur->{'mappings'} || []})
		{
			$a ++;
			# process all tokens of line
			foreach my $group (@{$line})
			{
				# get row were pointing at
				my $row = $group->[2];
				my $original = $old_row_idx[$row];
				# point to where we originaly point
				$fid = $group->[1] = $original->[1]; # fid
				$group->[2] = $original->[2]; # row
				# $group->[3] = $original->[3]; # col
			}
		}

	}
	else
			{
	$cur->{'names'} = $old->{'names'};
print "prepared remap\n";
	# process all existing lines
	# these are the already processed ones
	# they point to somewhere in the originals
	foreach my $line (@{$cur->{'mappings'} || []})
	{
		$a ++;
		# process all tokens of line
		foreach my $group (@{$line})
		{
			$b ++;
my $l;

			# get row were pointing at
			my $row;

			# find last token in the originals to
			# know where it actually was pointing at
			for ($row = $group->[2]; $row != -1; $row --)
			{
				$c ++;
my $fafa = 0;

				# since we can switch between rows anytime
				# we have to redo this search over and over again
				my $maps = $old->{'mappings'}->[$row];
last unless scalar(@{$maps});
die "unexpected loop" if $row ne $group->[2];

				die "remap has invalid state" unless $maps;
				die "remap has invalid state" unless scalar(@{$maps});

# $group->[3];
my $original;

# find a better offset from the cache -> go further on the $l
				my $l = $old_map_idx[$row]->[($group->[3] - $group->[3] % $index_col_gap) / $index_col_gap];
# die $group->[3], " :: ", ($group->[3] - $group->[3] % $index_col_gap) / $index_col_gap if (($group->[3] - $group->[3] % $index_col_gap) / $index_col_gap);
# die "found $l" if $l;
#die "ground index ", $old_map_idx[$row], "$l - " . (($group->[3] - $group->[3] % $index_col_gap) / $index_col_gap);
#die "nop $l ", $old->{'mappings'}->[$row]->[$l]->[0], " -> ", $group->[3] if ($old->{'mappings'}->[$row]->[$l]->[0] ne $group->[3]);

my $dup = $l;
				$l = 0 unless defined $l;
my $qweqwe = 0;
				# find original position from the right
				# $l = scalar(@{$maps}); while ($l --)
				for (; $l < scalar(@{$maps}); $l++)
				{
					$d ++;
					# die "wrong $dup ", scalar @{$old_map_idx[$row]}, " a ", $group->[3], " - ", (($group->[3] - $group->[3] % $index_col_gap) / $index_col_gap) if $qweqwe ++ > 300;
					# get the original group
					$original = $maps->[$l];
					die unless $original;
					die "wha" if @{$original} < 3;
					# check if we found nearest offset
					if ($original->[0] == $group->[3])
					{
						# point to where we originaly point
						$fid = $group->[1] = $original->[1]; # fid
						# $group->[2] = $original->[2]; # row
						# $group->[3] = $original->[3]; # col
						# adjust col by possible previous offset
						die "strange" if $row != $group->[2];
						# found an exact match to go
						$y++; $fafa = 1;
						# $group = [ @{$group}[ 0 .. 1 ], @{$original}[ 2 .. $#{$original} ] ];
						$group->[2] = $original->[2];
						$group->[3] = $original->[3];
						$group->[4] = $original->[4];
						last;
					}
					elsif ($original->[0] > $group->[3])
					{

						# skip
						last;

						# warn $original->[0] - $group->[3] if ($original->[0] - $group->[3]) > 0;

						# point to where we originaly point
						$fid = $group->[1] = $original->[1]; # fid
						$z++; $fafa = 1;
						$group->[2] = $original->[2];
						$group->[3] = $original->[3];
						$group->[4] = $original->[4];
						last;

						die "can abort, will not find me";
					}

				}
				# EO search from right

unless ($fafa)
{

#	die "japa" if $l == -1;

							$foo ++;
#							die "skipp";
						# die "we skipp $group->[0] " . @{$cur->{'mappings'}->[$row]} if $group->[0] && $row;
							# group->[2] points to line 12983, col 3
							# original->[12983] first item points at col 11
							# warn "$a, ", join(", ", @{$group}), " ==== ", join(", ", @{$old->{'mappings'}->[$group->[2]]->[0]}), " --> ", $old->{'sources'}->[0];
							$group->[4] = -1;
							last if $original;
}

				last

			};

			die "nog ood" if $row eq -1 && $l eq -1;
		}
	}
}
	# replace sources (use original mappings)
	$cur->{'sources'} = $old->{'sources'};

	my $counta = 0; my $countb = 0;

	foreach my $foo (@{$cur->{'mappings'}})
	{ $counta += scalar (@{$foo}) }
	foreach my $foo (@{$old->{'mappings'}})
	{ $countb += scalar (@{$foo}) }

	print "finished remap ($counta/$countb) -> init: $x / exact: $y / same line: $z / skipped: $foo\n";

	foreach my $lna (@{$cur->{'mappings'}})
	{
#		@{$lna} = grep { !$_->[4] || $_->[4] != -1 } @{$lna};
	}

	my $t1 = Benchmark->new;
	my $td = timediff($t1, $t0);
	print "the code took:",timestr($td)," $a $b $c $d\n";

	# return object
	return $cur;

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
				$_->[1] - $file,
				$_->[2] - $row,
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
use File::Basename qw(dirname);
use File::Spec::Functions qw(abs2rel);
###################################################################################################

sub render
{

	my ($smap, $path) = @_;

	# create json object
	my $json = new JSON;

	# get the mappins in internal format
	my $mappings = $smap->{'mappings'};

	# call exporter
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

	# call importer
	$smap->importer;

	# prettify json
	$json->pretty(0);

	# get array reference to sources
	# make copy if we alter something
	my $sources = $smap->{'sources'};

	# rebase to output path
	if (defined $path)
	{
		# get the output directory
		my $root = dirname $path;
		# make all sources relative to the output directory
		$sources = [ map { abs2rel($_, $root) } @{$sources} ];
	}

	# decode json data to perl hash
	$json = $json->encode({
		# version of output format
		'version' => $smap->version,
		# number of source lines
		'lines' => $smap->{'lines'},
		# array for indexed names
		'names' => $smap->{'names'},
		# array for source files
		'sources' => $sources,
		# array for source mappings
		# one map entry for each line
		'mappings' => $mappings,

	});

	# return data
	return $json;

}

###################################################################################################
###################################################################################################

sub add
{

	my ($smap, $data, $add) = @_;

	$smap->{'data'} = '' unless exists $smap->{'data'};

	# declare line mapping array
	my $lines = $smap->{'mappings'};
	$lines = [] unless defined $lines;
	# create first group if not yet existing
	# this represents basically an empty string
	$lines->[0] = [] if (scalar(@{$lines}) == 0);

	my $row = $#{$smap->{'mappings'}};

my $col;

	# there is some entry in this row
	# must be the last thing in there
	# we cannot get a better position
	# that why we have mixin with row/col!
	if (scalar(@{$smap->{'mappings'}->[$row]}))
	{
		$col = $smap->{'mappings'}->[$row]->[-1]->[0];
	}
	else
	{
		$col = 0;
	}

#	$row ++ if

#	${$data} =~ m/([^\n]+)\z/;
#	my $col = length $1;


#warn "ADDING ${$data} at $row:$col\n";
#warn "X" x 70, "\n";
#warn Data::Dumper::Dumper($add);
#warn "X" x 70, "\n";

	$smap->mixin([$row, $col], [0, 0], $add);

# warn $row, " - ", $col;

	# push first new line on to previous line
#	push @{$lines->[-1]}

}

# append more source lines
# also adds a new source file
# this operation has nearly no cost
sub append123
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

	if (scalar(@{$oldmaps}))
	{
		$smap->{'lineCount'} += scalar $#newmaps;
	}
	else
	{
		$smap->{'lineCount'} += scalar @newmaps;
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
