# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package MovableAtom;
our $VERSION = '0.01';

use strict;

use Class::Holon 
( 
	To => DescribeLevel, 
	Type => 'Hash',
	Data => { 
		Atom=> sub{Class::Holon::New('Atom')},
		Movable=>sub{Class::Holon::New('Movable')} 
		},	
	IncludeLevel=>['Atom', 'Movable'],
);


1;
