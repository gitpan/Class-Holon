#!/usr/local/bin/perl -W

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use lib ( './t', '.' );

use strict;


use Data::Dumper;
print "1..4 \n";

use Molecule ;

my $instance = Molecule::Create_Complex;
print "ok 1\n";


$instance->Print;
print "ok 2\n";

my $val = $instance->[2]->[0]->{electrons};
print "ok 3\n" if ($val == 8);

$val = ref($instance);
if ($val eq 'Molecule')
	{print "ok 4\n";}
else
	{print "FAIL 3\n"; }


