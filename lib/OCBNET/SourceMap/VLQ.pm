###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-SourceMap (GPL3)
####################################################################################################
# helper module for vlq conversion
####################################################################################################
package OCBNET::SourceMap::VLQ;
####################################################################################################

use utf8;
use strict;
use warnings;

####################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw(decodeVLQ encodeVLQ); }

# define our functions that can be exported
BEGIN { our @EXPORT_OK = qw(toVLQSigned fromVLQSigned); }

####################################################################################################

# declare array with 64 chars for the BASE64 encoding
my @VLQ = ('A' .. 'Z', 'a' ..'z', '0' .. '9', '+', '/');

# create a lookup hash from the VQL chars to their representing numbers
my %VLQ; for (my $i = 0; $i < scalar(@VLQ); $i++) { $VLQ{$VLQ[$i]} = $i }

####################################################################################################

# declare the base shifting
my $VLQ_BASE_SHIFT = 5;

# shift bit into position (011111 -> 32)
my $VLQ_BASE = 1 << $VLQ_BASE_SHIFT;

# create reversed bitmask (011111 -> 31)
my $VLQ_BASE_MASK = $VLQ_BASE - 1;

# the continuation bit equals the base (32)
my $VLQ_CONTINUATION_BIT = $VLQ_BASE;

####################################################################################################

sub fromVLQSigned
{
	# take away first bit (aka "signum")
	$_[0] & 1 ? - $_[0] >> 1 : $_[0] >> 1;
}

####################################################################################################

sub decodeVLQ
{

	# get encoded string
	my ($encoded) = @_;

	# declare and init local loop variables
	my ($i, $len, @values) = (0, length($encoded));

	# process whole string
	# create array of numbers
	while($i < $len)
	{

		# loop variables
		my $value = 0;
		my $shifted = 0;
		my $continuation;

		# read continously
		do
		{
			# assertion that we are not reading anything non standard
			die "expected more digits in BASE64 VLQ value" if $i >= $len;
			# decode base 64 nibble at position to number
			my $nibble = $VLQ{substr($encoded, $i ++, 1)};
			# maybe read next nibble into this value
			$continuation = $nibble & $VLQ_CONTINUATION_BIT;
			# remove continuation bit
			$nibble &= $VLQ_BASE_MASK;
			# add shifted value to value
			$value += $nibble << $shifted;
			# increate shifting base
			$shifted += $VLQ_BASE_SHIFT;
		}
		# EO read continously
		while $continuation;

		# add actual number to the result array
		push @values, fromVLQSigned($value);

	}
	# EO parsed all

	# return results
	return \ @values;

}

####################################################################################################
####################################################################################################
1;