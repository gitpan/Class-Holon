package StrictMolecule;
our $VERSION = '0.01';

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;

use Class::Holon 
( 
	To => DescribeLevel, 
	Type => 'Array',
	Data => [ 
		Atom=> sub{Class::Holon::New('StrictAtom')},
		],	
	IncludeLevel=>['StrictAtom'],
);


1;
