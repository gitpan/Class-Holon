# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.



####################################################################
package MovableMolecule;
our $VERSION = '0.01';

use strict;

use Data::Dumper;

use Class::Holon 
( 
	To => DescribeLevel, 
	Type => 'Hash',
	Data => { 
		Molecule=> sub{Class::Holon::New('Molecule')},
		Movable=>sub{Class::Holon::New('Movable')} 
		},	
	IncludeLevel => ['Molecule', 'Movable'],
);


1;
