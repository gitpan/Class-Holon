# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Movable;
our $VERSION = '0.01';

use strict;

use Class::Holon  
( 
	To => DescribeLevel, 
	Type => Hash,
	Data => { posx=>0, posy=>0, posz=>0 },	
	 
);



1;
