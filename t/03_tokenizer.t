# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 40;
BEGIN { use_ok('OCBNET::SourceMap::Utils') };

use OCBNET::SourceMap::Utils qw(tokenize debugger);

my $smap = tokenize("A B C", 'STDIN');

ok    (exists $smap->{'names'},                           'names exists');
ok    (exists $smap->{'sources'},                         'sources exists');
ok    (exists $smap->{'mappings'},                        'mappings exists');
ok    (exists $smap->{'lineCount'},                       'lineCount exists');

is    (ref $smap->{'names'},                   'ARRAY',   'names is an array');
is    (ref $smap->{'sources'},                 'ARRAY',   'sources is an array');
is    (ref $smap->{'mappings'},                'ARRAY',   'mappings is an array');

is    ($smap->{'lineCount'},                   1,         'lineCount is set correctly');

is    (scalar(@{$smap->{'names'}}),            3,         'names array has correct item number');
is    (scalar(@{$smap->{'sources'}}),          1,         'sources array has correct item number');
is    (scalar(@{$smap->{'mappings'}}),         1,         'mappings array has correct line number');
is    (scalar(@{$smap->{'mappings'}->[0]}),    4,         'mappings line array has correct group number');

is    ($smap->{'sources'}->[0],                'STDIN',   'sources index 0 is set to STDIN');

is    ($smap->{'names'}->[0],                  'A',       'names index 0 is set to token A');
is    ($smap->{'names'}->[1],                  'B',       'names index 1 is set to token B');
is    ($smap->{'names'}->[2],                  'C',       'names index 2 is set to token C');

my $tokenA = $smap->{'mappings'}->[0]->[0];
my $tokenB = $smap->{'mappings'}->[0]->[1];
my $tokenC = $smap->{'mappings'}->[0]->[2];
my $tokenEOL = $smap->{'mappings'}->[0]->[3];

ok    ($tokenA,                                           'tokenA is available');
ok    ($tokenB,                                           'tokenB is available');
ok    ($tokenC,                                           'tokenC is available');
ok    ($tokenEOL,                                         'tokenEOL is available');

is    ($tokenA->[0],                           0,         'tokenA dest offset is correct');
is    ($tokenA->[1],                           0,         'tokenA source file is correct');
is    ($tokenA->[2],                           0,         'tokenA source row is correct');
is    ($tokenA->[3],                           0,         'tokenA source col is correct');
is    ($tokenA->[4],                           0,         'tokenA name index is correct');

is    ($tokenB->[0],                           2,         'tokenB dest offset is correct');
is    ($tokenB->[1],                           0,         'tokenB source file is correct');
is    ($tokenB->[2],                           0,         'tokenB source row is correct');
is    ($tokenB->[3],                           2,         'tokenB source col is correct');
is    ($tokenB->[4],                           1,         'tokenB name index is correct');

is    ($tokenC->[0],                           4,         'tokenC dest offset is correct');
is    ($tokenC->[1],                           0,         'tokenC source file is correct');
is    ($tokenC->[2],                           0,         'tokenC source row is correct');
is    ($tokenC->[3],                           4,         'tokenC source col is correct');
is    ($tokenC->[4],                           2,         'tokenC name index is correct');

is    ($tokenEOL->[0],                         5,         'tokenEOL dest offset is correct');
is    ($tokenEOL->[1],                         0,         'tokenEOL source file is correct');
is    ($tokenEOL->[2],                         0,         'tokenEOL source row is correct');
is    ($tokenEOL->[3],                         5,         'tokenEOL source col is correct');


__DATA__



ok    (exists $smap->{'names'},                           'names exists');
ok    (exists $smap->{'sources'},                         'sources exists');
ok    (exists $smap->{'mappings'},                        'mappings exists');
ok    (exists $smap->{'lineCount'},                       'lineCount exists');


is    (ref $smap->{'names'},             'ARRAY',         'names is an array');
is    (ref $smap->{'sources'},           'ARRAY',         'sources is an array');
is    (ref $smap->{'mappings'},          'ARRAY',         'mappings is an array');

is    ($smap->{'lineCount'},                   0,         'lineCount is inited to zero');
is    ($#{$smap->{'mappings'}},               -1,         'mappings has no entries?');



__DATA__

my $block1 = OCBNET::CSS3::DOM::Selector->new;
my $block2 = OCBNET::CSS3::DOM::Selector->new;

$css->add($block1, $block2);

is    ($block1->parent,      $css,         'add connects parent');
is    ($block2->parent,      $css,         'add connects parent');
is    ($css->children->[0],  $block1,      'add pushes children in array');
is    ($css->children->[1],  $block2,      'add pushes children in array');

$block1->{'parent'} = undef;
$block2->{'parent'} = undef;
$css->prepend($block2, $block1);

is    ($block1->parent,      $css,         'prepend connects parent');
is    ($block2->parent,      $css,         'prepend connects parent');
is    ($css->children->[0],  $block2,      'prepend unshifts children in array');
is    ($css->children->[1],  $block1,      'prepend unshifts children in array');

$css = OCBNET::CSS3::Stylesheet->new;

my $code = '/* pre1 */ /* pre2 */ ke/* in key */y /* */ : /**/ va/* in value */lue; ;;;/* post1 */;/* post2 */';
my $rv = $css->parse($code);
is    ($rv,                        $css,            'parse returns ourself');
is    ($css->children->[0]->type,  'comment',       'parses pre1 to comment type');
is    ($css->children->[0]->text,  '/* pre1 */ ',   'parses pre1 with correct text');
is    ($css->children->[1]->type,  'comment',       'parses pre2 to comment type');
is    ($css->children->[1]->text,  '/* pre2 */ ',   'parses pre2 with correct text');
is    ($css->children->[2]->type,  'property',      'upgrade to selector type');
is    ($css->children->[2]->text,  'ke/* in key */y /* */ : /**/ va/* in value */lue',   'parses preperty with correct text');
is    ($css->children->[3]->type,  'whitespace',    'upgrade to selector type');
is    ($css->children->[3]->text,  ' ',             'parses whitespace with correct text');
is    ($css->children->[3]->suffix, ';;;',          'parses whitespace suffix correctly');
is    ($css->children->[4]->type,  'comment',       'parses post1 to whitespace type');
is    ($css->children->[4]->text,  '/* post1 */',   'parses post2 with correct text');
is    ($css->children->[5]->type,  'comment',       'parses post1 to whitespace type');
is    ($css->children->[5]->text,  '/* post2 */',   'parses post2 with correct text');
is    (scalar(@{$css->children}),  6,               'parses correct amount of dom nodes');
is    ($css->render,               $code,           'render the same as parsed');
is    ($css->clone(1)->render,     $code,           'clone renders the same as parsed');
