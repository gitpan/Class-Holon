package Atom::Hydrogen;

our $VERSION = '0.01';
use strict;


use Class::Holon (
	To => SpecifyLevel, 
	Data => { protons=>1, neutrons=>0, electrons=>1 },	
);

1;
