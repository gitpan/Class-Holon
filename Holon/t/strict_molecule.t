#!/usr/local/bin/perl -W

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use lib ( './t', '.' );

use strict;


use Data::Dumper;
print "1..2 \n";

use StrictMolecule ;
print "ok 1\n";

my $instance = Class::Holon::New('StrictMolecule');
print "ok 2\n";


