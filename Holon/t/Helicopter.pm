# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Helicopter;

our $VERSION = '0.01';

use strict;

use Class::Holon 
	(
	To => DescribeLevel,
	Type => GetSet,
	Data => { 
		Speed=>0, 
		Altitude=>0 
		},
	);

1;
