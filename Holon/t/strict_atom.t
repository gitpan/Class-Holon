#!/usr/local/bin/perl -w

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use lib ( './t', '.' );

use strict;

use Data::Dumper;
print "1..2 \n";

use StrictAtom ;
print "ok 1\n";



my $hyd = Class::Holon::New ( 'StrictAtom' );

print "ok 2\n";
