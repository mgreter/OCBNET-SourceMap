use strict;
use warnings;

use lib 'lib';

use OCBNET::SourceMap;
use OCBNET::SourceMap::V3;
use OCBNET::SourceMap::Utils;

my $data = "hi world
 a  lorem ipsum
  dollar
sit amet
";

my $smap = tokenize($data);

bless $smap, 'OCBNET::SourceMap::V3';

$smap->replace( \ $data, qr/hi world\n/, sub {

	("test", tokenize("test"))

});


$smap->debug;

print $data;

use File::Slurp qw(write_file);

write_file('test.map.html', { binmode => ':encoding(utf8)' }, OCBNET::SourceMap::Utils::debugger($data, $smap)) if $smap;
