# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.



####################################################################
package Molecule;
our $VERSION = '0.01';

use strict;

use Data::Dumper;

use Class::Holon 
( 
	To => DescribeLevel, 
	Type => 'Array',
	IncludeLevel => ['MovableAtom'],
	SubInstances => Enabled,
);

sub Create_Water 
{
	my $molecule = Holon::New('Molecule');

	push	( @{$molecule},
		$molecule->Class::Holon::New('Atom::Hydrogen'),
		$molecule->Class::Holon::New('Atom::Oxygen'),
		$molecule->Class::Holon::New('Atom::Oxygen'),
		);

	return $molecule;
};

sub Create_Complex 
{
	my $molecule = Class::Holon::New('Molecule');

	@{$molecule} =
	(
		$molecule->Class::Holon::New('Atom::Hydrogen'),
		$molecule->Class::Holon::New('Atom::Oxygen'),
		[
			$molecule->Class::Holon::New('Atom::Oxygen'),
			[
				$molecule->Class::Holon::New('Atom::Hydrogen'),
				$molecule->Class::Holon::New('Atom::Oxygen'),
				$molecule->Class::Holon::New('Atom::Hydrogen'),
			],
			$molecule->Class::Holon::New('Atom::Oxygen'),
		],

		$molecule->Class::Holon::New('Atom::Oxygen'),
		$molecule->Class::Holon::New('Atom::Hydrogen'),

	);

	return $molecule;
};


sub Print
{
	my $molecule = shift;

	print "Printing Molecule ....\n";

	my $subinstance_arr_ref = $Molecule::SubInstances{$molecule};

	foreach my $subinst (@{$subinstance_arr_ref})
		{
		print "\tsubinst is ".ref($subinst)." \n";
		}

}

1;
