
use strict;
use warnings;

use Data::Dumper qw();
use JSON qw(decode_json);
use File::Slurp qw(read_file write_file);
use MIME::Base64 qw( decode_base64 encode_base64 );
# my $content = read_file ( 'jquery-1.11.1.min.map' );
my $content = read_file ( 'output.tst.map' );

my @chars = ('A' .. 'Z', 'a' ..'z', '0' .. '9', '+', '/');

my %idx; for (my $i = 0; $i < scalar(@chars); $i++) { $idx{$chars[$i]} = $i }


my $VLQ_BASE_SHIFT = 5;

  #// binary: 100000
my $VLQ_BASE = 1 << $VLQ_BASE_SHIFT;

  #// binary: 011111
my $VLQ_BASE_MASK = $VLQ_BASE - 1;

  #// binary: 100000
my $VLQ_CONTINUATION_BIT = $VLQ_BASE;


sub fromVLQSigned
{

	my ($aValue) = @_;
 my $isNegative = ($aValue & 1) == 1;
    my $shifted = $aValue >> 1;
    return $isNegative
      ? -$shifted
      : $shifted;


}

my $srcmap = decode_json ($content);

$srcmap->{'lines'} = [ map {
	[ map {
												my @values;
												my $off = 0;
												my $val = 0;


											    my $strLen = length($_);
											    my $i = 0;

#    Generated column
#    Original file this appeared in
#    Original line number
#    Original column
#    And if available original name.


											while($i < $strLen)
											{
											    my $result = 0;
											    my $shift = 0;
											    my $continuation;
											    my $digit;
											    do {
											      if ($i >= $strLen) {
											        die("Expected more digits in base 64 VLQ value.");
											      }
											      $digit = $idx{substr($_, $i++, 1)}; # base64.decode(aStr.charAt(i++));
											      $continuation = !!($digit & $VLQ_CONTINUATION_BIT);
														$digit &= $VLQ_BASE_MASK;
											      $result = $result + ($digit << $shift);
											      $shift += $VLQ_BASE_SHIFT;
											    } while ($continuation);

											    push @values, fromVLQSigned($result);
											}


												[ @values ]

	} split /,/, $_ ];

} split /;/, $srcmap->{'mappings'} ];


# my $org = read_file ( 'jquery-1.11.1.min.js' );
my $src = read_file ( 'input.js' );
my $org = read_file ( 'output.js' );

my @srcs = split(/\n/, $src);
my @lines = split(/\n/, $org);
my $i = 0;

my $closer;

my $row = 0;
my $col = 0;
my $file = 0;
my $factory = 0;

#die Data::Dumper::Dumper $srcmap->{'lines'}->[1];
foreach my $line (@{$srcmap->{'lines'}})
{

	my $offset = 0;

	$lines[$i] =~ s/</[/g;
	$lines[$i] =~ s/>/]/g;

	foreach my $entry (@{$line})
	{

		my $title = "";

		$offset += $entry->[0];

		# this one can be negative ...
		if (scalar(@{$entry}) == 5)
		{
			$factory += $entry->[4];
			$title = $srcmap->{'names'}->[$factory];
		}

		if (scalar(@{$entry}) >= 4)
		{
			$file += $entry->[1];
			$row += $entry->[2];
			$col += $entry->[3];

			my ($start, $slen) = ($col - 10, 10);
			my $endlen = length($srcs[$row]) - $col;
			$endlen = 10 if $endlen > 10;

			if ($start < 0) { $slen += $start; $start = 0; }
			my $excerpt = substr($srcs[$row], $start, $slen);
			# die $col, " vs ", length($srcs[$row]) if ($col > length($srcs[$row]));
			$excerpt  .= '>>' . substr($srcs[$row], $col - 1, $endlen);

			$excerpt =~ s/</&lt;/g;
			$excerpt =~ s/>/&gt;/g;
			$excerpt =~ s/\"/&quot;/g;

			$title .= sprintf("\nfile: %d", $file);
			$title .= sprintf("\nrow: %d", $row);
			$title .= sprintf("\ncol: %d", $col);
			$title .= sprintf("\n%s", $excerpt);
		}

		if (scalar(@{$entry}) == 1)
		{
			die "whoip";
		}

		my $insert = '<span title="' . $title . '">';

		if (defined $closer)
		{
			substr($lines[$i], $offset, 0) = $closer;
			$offset += length($closer);  $closer = '';
		}
		$closer = '</span>';

		substr($lines[$i], $offset, 0) = $insert;
		$offset += length($insert) ;

	}
	# $offset -= 2;
# $offset ++;
$i++;

}

write_file ( 'output.html', join("\n", @lines) );

