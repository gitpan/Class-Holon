#!/usr/local/bin/perl -w

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use lib ( './t', '.' );

use strict;

use Data::Dumper;

print "1..5 \n";

use TestTube ;
print "ok 1\n";

my $instance1 = (Class::Holon::New('TestTube'))->Fill;
print "ok 2\n";

my $instance2 = (Class::Holon::New('TestTube'))->Fill;
print "ok 3\n";

TestTube::DisplayTubeRack;
print "ok 4\n";



print "ok 5\n" if($instance1->isa('Atom'));

