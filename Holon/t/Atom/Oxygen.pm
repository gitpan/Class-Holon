package Atom::Oxygen;

our $VERSION = '0.01';

use strict;

use Class::Holon (
	To => SpecifyLevel, 
	Data => { protons=>8, neutrons=>8, electrons=>8 },	
);

1;
