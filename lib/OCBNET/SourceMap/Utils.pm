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
use File::Slurp qw(read_file);
####################################################################################################

sub debugger
{

	my $rv = '';
my @rv;
	my ($lines, $smap) = @_;
return;
my $maps = $smap->{'mappings'};

	# use Data::Dumper;
	# warn Dumper($smap);

	print "start debugger\n";
	# expect an array reference
	if (!UNIVERSAL::isa ($lines, 'ARRAY'))
	{
		if (UNIVERSAL::isa ($lines, 'SCALAR'))
		{ $lines = [ split /\r?\n/, ${$lines}, -1 ] }
		else { $lines = [ split /\r?\n/, $lines, -1 ] }
	}

	# assertion for input data
	die "no lines" unless $lines;
	die "no lines" unless @{$lines};

	# basic assertion that map is valid
	if (scalar(@{$lines}) != scalar(@{$maps}) )
	{
		Carp::croak sprintf "%s [lines: %d, rows: %d]",
			"map and input have different amount of lines",
			scalar(@{$lines}), scalar(@{$maps}); sleep 1;
	}

	# cache of loaded source files
	# only load each source once
	my %sources;

	# process everything from the end
	# this way we can manipulate the input
	my $row = scalar(@{$maps}); while ($row --)
	{

		my $cols = $maps->[$row];
		my $line = $lines->[$row];

		$line =~ s/</[/g;
		$line =~ s/>/]/g;

		my $offset = 0;

		foreach my $col (reverse @{$cols})
		{

			my ($title);

# next unless $col->[4] && $col->[4] eq -1;


			die "what" if (scalar(@{$col}) < 2);

			# fix it for our test cases, sort this out
			# correctly later when it works reliable
			my $src = $smap->{'sources'}->[$col->[1]];
			$src =~ s/html-14rooms\/global\///;

			unless (exists $sources{$src})
			{
				my $filedata = read_file($src) or die "no read_file $src";
				my $filelines = [ split /\r?\n/, $filedata, -1 ];
				$sources{$src} = [ $filedata, $filelines ];

			}

			my ($filedata, $filelines) = @{ $sources{$src} };

			# this entry has a token name
			if (scalar(@{$col}) >= 4)
			{
				my $tok = '_';
				my $title = '[NA]';

				$title = $smap->{'names'}->[$col->[4]] if defined $col->[4];

				if (defined $col->[4] && $col->[4] eq -1)
				{
					$tok = "[-]";
					$title = "[LOST]";
				}

				my $text;

				$text = substr($filelines->[$col->[2]], $col->[3], 24) if defined $col->[2] && defined $filelines->[$col->[2]] && length($filelines->[$col->[2]]) >= $col->[3] ;
				$text = 'err' unless defined $text;
				$text =~ s/\"/&quot;/g;
				$text =~ s/</&lt;/g;
				$text =~ s/>/&gt;/g;

				my ($prow, $pcol) = (0, 0);
				my $pre = substr $line, 0, $col->[0] + $offset;
				$pre =~ m/([^\n]*)$/;
				$prow = $pre =~ tr/\n/\n/;
				$pcol = length $1;

				if (defined $col->[4] && $col->[4] eq -1)
				{
					$title .= sprintf("\n[%d, %d] -> [%d, %d] ?", $prow, $pcol, $col->[2], $col->[3]);
				}
				else
				{
					$title .= sprintf("\n[%d, %d] -> %s [%d, %d]", $prow, $pcol, substr($src, - 16), $col->[2], $col->[3]);
				}

				$title .= sprintf("\n]]%s", $text);

				my $opener = '<span title="' . $title . '">'.$tok.'</span>';

				substr $line, $col->[0] + $offset, 0, $opener;

			}
			else
			{
				die "have invalid group";
			}

		}

		push (@rv, $line);
		# $rv = $line . '<br/>' . $rv;

	}

print "final debugger\n";

	return join("<br/>", reverse @rv);

}

####################################################################################################
####################################################################################################
1;