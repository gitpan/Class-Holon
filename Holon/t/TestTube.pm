package TestTube;
our $VERSION = '0.01';

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;

use Data::Dumper;

use Class::Holon 
( 
	To => DescribeLevel, 
	Type => 'Array',
	IncludeLevel=>['MovableMolecule'],
	Instances => Enabled,
);


sub Fill
{
	my $testtube = shift;
	for(my$i=1;$i<10;$i++)
		{
		push(@{$testtube}, Class::Holon::New('MovableMolecule'));
		}
	return $testtube;
}


sub DisplayTubeRack
{
	print "displaying all testtubes in experiment: \n";
	foreach my $tube (@TestTube::Instances)
		{
		print "\t $tube \n";
		}

}

1;
