#!/usr/local/bin/perl -w

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use lib ( './t', '.' );

use strict;

use Data::Dumper;
print "1..3 \n";

use MovableAtom ;
print "ok 1\n";

my $hyd = Class::Holon::New ( 'MovableAtom' );
if (ref($hyd) eq 'MovableAtom')
	{print "ok 2\n";}
else
	{print "FAIL 2\n";}


my $val = $hyd->{Atom}->{electrons};
if ($val == 0)
	{print "ok 3\n";}
else
	{print "FAIL 3\n";}




