###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-SourceMap (GPL3)
####################################################################################################
package OCBNET::SourceMap::Utils;
####################################################################################################

use utf8;
use strict;
use warnings;

####################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw(tokenize); }

# define our functions that can be exported
BEGIN { our @EXPORT_OK = qw(debugger); }

####################################################################################################
# The tokenizer parses generic code and returns
# a sourcemap structure to be further processed.
####################################################################################################

sub tokenize
{

	# get input arguments
	my ($lines, $source) = @_;

	# expect an array reference
	if (!UNIVERSAL::isa ($lines, 'ARRAY'))
	{
		if (UNIVERSAL::isa ($lines, 'SCALAR'))
		{ $lines = [ split /\r?\n/, ${$lines}, -1 ] }
		else { $lines = [ split /\r?\n/, $lines, -1 ] }
	}

	# declare local variables
	my (@maps, %tokens);

	my $row;
	my $col = 0;

	foreach my $line2 (@{$lines})
	{
my $line = $line2;

		$col = 0;

		my @row;
		$row = \@row;

		while ($line ne '')
		{

			# parse the next token (and leading "white" space)
			if ($line =~ s/^([^a-zA-Z0-9_\.]*)([a-zA-Z0-9_\.]*)//)
			{

				# skip white space
				$col += length $1;

				# check if we have a token
				if (defined $2 && $2 ne '')
				{

					# create token and assign index
					unless ( exists $tokens{$2} )
					{ $tokens{$2} = scalar (keys %tokens) }

					# create a initial mapping for the current token
					push @row, [ $col, 0, scalar(@maps) ? 1 : 0, $col, $tokens{$2} ];

					# skip token length
					$col += length $2;

				}

			}
			# assertion for regular expression
			else { die "invalid tokenizer state" }

		}

		push @maps, \@row;

	}

	if ($col > 0)
	{
		push @{$row}, [$col, 0, $#maps, $col];
	}

	# also need the tokens/names!
	# sources must be created outside?

	my @tokens; $tokens[$tokens{$_}] = $_ foreach keys %tokens;

	return {
		'names' => \@tokens,
		'mappings' => \@maps,
		'sources' => [ $source || 'STDIN' ],
		'lineCount' => scalar(@{$lines})
	}

}

####################################################################################################
# debugger is really just usefull during developement
####################################################################################################

sub debugger
{

	my $rv = '';

	my ($lines, $smap) = @_;

my $maps = $smap->{'mappings'};

	# expect an array reference
	if (!UNIVERSAL::isa ($lines, 'ARRAY'))
	{
		if (UNIVERSAL::isa ($lines, 'SCALAR'))
		{ $lines = [ split /\r?\n/, ${$lines}, -1 ] }
		else { $lines = [ split /\r?\n/, $lines, -1 ] }
	}

	# basic assertion that map is valid
	if (scalar(@{$lines}) != scalar(@{$maps}) )
	{ die "map and input have different amount of lines
		", scalar(@{$lines}), " != ", scalar(@{$maps})
		 }

	for (my $row = 0; $row < scalar(@{$maps}); $row++)
	{

		my $cols = $maps->[$row];
		my $line = $lines->[$row];

		$line =~ s/</[/g;
		$line =~ s/>/]/g;

		my $offset = 0;

		foreach my $col (@{$cols})
		{

			my $title;

			# this entry has a token name
			if (scalar(@{$col}) == 5)
			{
				$title = $smap->{'names'}->[$col->[4]];
				die "invalid title access" unless defined $title;
			}

			# this is a "real" token
			# but may not have a title
			if (scalar(@{$col}) >= 4)
			{
			}

			next if (scalar(@{$col}) != 5);

			if (length ($title))
			{
				my $opener = '<span title="' . $title . '">';
				substr $line, $col->[0] + $offset, 0, $opener;
				$offset += length($opener);

				#eval
				{
					my $l = 1;
				my $closer = '</span>';
				print length($line), ">", $col->[0] + $offset + 1, " vs \n";
				if (length($line) >= ($col->[0] + $offset + $l))
				{
					substr($line, $col->[0] + $offset + $l, 0) = $closer;
					$offset += length($closer);
				}
				else
				{
					die "invalid range $offset";
				}
				}
			}

		}

		$rv .= $line . '<br/>';

	}

	return $rv;

}

####################################################################################################
####################################################################################################
1;