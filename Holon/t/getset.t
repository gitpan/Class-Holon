#!/usr/local/bin/perl -w

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use lib ( './t', '.' );

use strict;


use Data::Dumper;

print "1..5 \n";

use Helicopter;

print "ok 1\n";

my $jetranger = Class::Holon::New('Helicopter');
print "ok 2\n" if (ref($jetranger) eq 'Helicopter');


$jetranger->SpeedSet(55);
print "ok 3\n" if ($jetranger->SpeedGet == 55);

$jetranger->AltitudeSet(5000);
print "ok 4\n" if ($jetranger->AltitudeGet == 5000);

my $speed = $jetranger->SpeedGet;
print "ok 5\n" if ($speed == 55);
