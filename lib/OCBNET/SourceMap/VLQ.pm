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
# Converts from a two-complement value to a value where the sign bit is
# is placed in the least significant bit.  For example, as decimals:
#   1 becomes 2 (10 binary), -1 becomes 3 (11 binary)
#   2 becomes 4 (100 binary), -2 becomes 5 (101 binary)
####################################################################################################

sub toVLQSigned ($)
{
	# last bit always indicates the "sign"
	$_[0] < 0 ? ((- $_[0]) << 1) + 1 : $_[0] << 1
}

####################################################################################################
# Converts to a two-complement value from a value where the sign bit is
# is placed in the least significant bit.  For example, as decimals:
#   2 (10 binary) becomes 1, 3 (11 binary) becomes -1
#   4 (100 binary) becomes 2, 5 (101 binary) becomes -2
####################################################################################################

sub fromVLQSigned ($)
{
	# last bit always indicates the "sign"
	$_[0] & 1 ? - ($_[0] >> 1) : $_[0] >> 1;
}

####################################################################################################
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

sub encodeVLQ
{

	# final string
	my $encoded = '';

	# read all passed values
	foreach my $value (@_)
	{

		# get vlq representation
		my $vlq = toVLQSigned($value);

		# write continously
		do
		{
			# create the digit (one base64 char)
			my $digit = $vlq & $VLQ_BASE_MASK;
			# remove bits we processed
			$vlq >>= $VLQ_BASE_SHIFT;
			# add continuation bit to this digit
			$digit |= $VLQ_CONTINUATION_BIT if $vlq > 0;
			# add the base 64 character
			$encoded .= $VLQ[$digit];
		}
		# EO write continously
		while ($vlq > 0);

	}

	# encoded string
	return $encoded;

}

####################################################################################################
####################################################################################################
1;