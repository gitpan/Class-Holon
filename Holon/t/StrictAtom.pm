package StrictAtom;
our $VERSION = '0.01';

use strict;

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Class::Holon 
( 
	To => DescribeLevel, 
	Type => Hash,
	Data => { protons=>0, neutrons=>0, electrons=>0 },
);


1;
