OCBNET-SourceMap
================

Perl Module to read/write/manipulate Source Maps (V3 only)

The idea would be to be able to use it with webmerge. To do
this I will need rather complete functionallity to manipulate
the source maps easily. Like inserting content into a file while
preserving the mappings back to the original file. This means we
need to update the offset of the content that fallows to the one
that got inserted.

I also need a feature to make it possible to merge two source maps
to get rid of an intermediate file. This might sound crazy, but
should be doable (although I'm a bit concerned about performance).
This feature is needed as we only can get a source map from compilers
for the content we fed in (which in this case would be multiple
files that have been joined). So we need to have a source map for
the concatenated content mapping back to the actual input files.
The intermediate content gets fed into ie. closure compiler, which
will create a source map pointing back to the intermediate content.
We now want to merge these two source maps, so we can point from
the compiled content back to the actual input files.

We also need to create source maps for our internal processors
(i.e. css compiler, prefixer, spriteset or inlinedata). Basically
for everything that changes the content programatically. I guess
the best way is to create specific file class that connects with
a source map and offers some manipulation methods, which will keep
the source map in sync.

One way to do it could be to "unpack" the source map to absolute offset
values. This would make it easier to manipulate the data directly.

Merge: The packed source map will be the main reference. Every mapping
in the final source map should be converted to the "root" mapping.
There doesn't seem to be any reason why this should not work over
multiple source maps. The last source map will point to an offset
in the intermediate file. Its source map should have a mapping
that points to this location, which should be used for replacement.
If this connection can't be made we should issue a warning. It needs
to be tested if this will actually work perferctly or with hickups.

So create a class that can:
Maybe can be used for watchdog?
->add($content, $smap)

A merge file creates a source map out of other merge files which
can in turn have source map, etc ... that's the idea.

Source maps also tackle the css importer/resolver as we would
like to have the actual references here too. I guess we will not
be able to also make all this source map mayhen configurable ...