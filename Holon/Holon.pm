package Class::Holon;

# Copyright (c) 2001 Greg London. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## See POD after __END__

require 5.005_62;
use strict;
use warnings;

our $VERSION = '0.01';


# Preloaded methods go here.

use Carp;
use Data::Dumper;

# use WeakRef;	# will need this to do proper garbage collection on warehouses.

my $DEBUG=0;

# %master_config keeps track of each level of holon's configuration.
# The hash key is the name of the package that defines a holon.
# The data is a hash ref which defines that level of holon.

my %master_config;


my %is_valid_config_key = 
	(
	# functional information
	To => [ 'DescribeLevel', 'SpecifyLevel' ],
	IncludeLevel => 1,

	# instance information
	Type => [ 'Hash', 'Array', 'GetSet' ],		# instance type
	Data => 1,				# instance data

	# Track all instances for this Holon level (perl package).
	# This creates an array called @package::Instances
	# This array contains references to every instance of this level.
	Instances => [ 'Enabled', 'Disabled' ], 

	# Track all SubInstances of each instance.
	# A SubInstance is defined as a holon instance of an IncludedLevel.
	# This creates a hash called %package::SubInstances
	# Use an object/instance as the hash key,
	# this will return an array reference which lists all the 
	# subinstances for this instance.
	SubInstances => [ 'Enabled', 'Disabled' ], # sub-instances for instance

	# deprecated terms.
	instance_data => "Deprecated, use 'Data' instead.",
	);

###############################################################################
sub import
###############################################################################
{
	my $holon = shift;	# this is always 'Class::Holon'
	return unless @_;

	#######################################################################
	# package is the name of the perl package which
	# is attempting to create a new Holon.
	# i.e. 'Atom' or 'Molecule'
	#######################################################################
	my $pkg = caller(0); 
	print "in holon::import for $pkg\n" if $DEBUG;

	#######################################################################
	# prevent duplicate call 'use Class::Holon' from calling package.
	#######################################################################
	if(exists($master_config{$pkg}))
		{
		confess "use Class::Holon already called for package $pkg \n";
		}

	#######################################################################
	# remaining parameters describes the object configuration.
	# must be in the form of a flattened HASH.  get it.
	#######################################################################
	my %config = @_;

	#######################################################################
	# error check the keys.
	#######################################################################

	# the 'To' key, MUST EXIST
	confess "Error: use Class::Holon must be called with 'To' parameter \n".
		"Valid values are 'DescribeLevel' and 'SpecifyLevel' \n"
		unless(exists($config{To}));

	# if 'To'=>'DescribeLevel', then 'Type' MUST EXIST
	if($config{To} eq 'DescribeLevel')
		{
		confess "Error: use Class::Holon ( To => DescribeLevel ... \n".
			"must specify Type. Valid values are ".
			"Array, Hash, GetSet \n"
			unless(exists($config{Type}));
		}

	######################################################################
	# make sure {Data} and {Type} correspond.
	######################################################################
	if ($config{To} eq 'DescribeLevel')
		{
		$config{Data}=undef unless(exists($config{Data}));

		# if no Data, then define an empty one
		unless(defined($config{Data}))
			{
			if 
			(	
				($config{Type} eq 'Hash') or 
				($config{Type} eq 'GetSet') 
			)

				{ $config{Data} = {}; }
			elsif ($config{Type} eq 'Array')
				{ $config{Data} = []; }
			else
				{
				confess "Error: use Class::Holon received bad ".
					"Type=> attribute \n";
				}

			}

		if( ($config{Type} eq 'Hash') or ($config{Type} eq 'GetSet') )
			{
			my $ok=0;
			$ok=1 if (ref($config{Data}) eq 'HASH');
			$ok=1 if (ref($config{Data}) eq 'ARRAY');

			confess "Error: use Class::Holon bad value for ".
				"Data=>  parameter for defined type.\n".
				"Must receive an array ref or a hash ref\n"
				unless $ok;

			if(ref($config{Data}) eq 'ARRAY')
				{
				my %hash;
				foreach my $element (@{$config{Data}})
					{
					if (exists($hash{$element}))
						{
						confess "Error: use Class::Holon ".
						"Data => was defined ".
						"using an array reference, \n".
						"but the same attribute name ".
						"('$element') appears twice ".
						"in the array. \n".
						"Did you intend to use ".
						"a hash with initial ".
						"values instead?\n";
						}
					$hash{$element}=undef;
					}
				$config{Data}=\%hash;
				}
			}
		
		if( $config{Type} eq 'Array' )
			{
			confess "Error: use Class::Holon must pass an array ".
				"reference to Data => attribute. \n"
				unless(ref($config{Data}) eq 'ARRAY');
			}
		}



	my @keys = keys(%config);
	foreach my $key (@keys)
		{
		confess "use Class::Holon called with invalid parameter '$key' \n"
			unless ( exists ($is_valid_config_key{$key} ) );

		###############################################################
		# if not an array ref, check for "Deprecated..." string.
		###############################################################
		my $ref = ref($is_valid_config_key{$key});
		unless($ref)
			{
			my $err_msg = $is_valid_config_key{$key};

			if ($err_msg =~ s/^Deprecated//)
				{
				confess "use Class::Holon has deprecated key ".
				"'$key' $err_msg \n";
				}

			next;
			}


		###############################################################
		# otherwise, look through possible literal values and
		# make sure user passed in an allowed value.
		###############################################################
		my $actual_data = $config{$key};
		my @possible_data = @{$is_valid_config_key{$key}};

		my $good_data = 0;
		foreach my $possible (@possible_data)
			{
			$good_data = 1 if ($possible eq $actual_data);
			}
		next if $good_data;

		###############################################################
		# user data didn't match anything in possible list, send error.
		# first, warn valid choices for this key. then confess.
		###############################################################
		warn "use Class::Holon passed invalid data ($actual_data) ".
			"for given key ($key). \n";
		warn "Valid data choices are: \n";
		foreach my $possible (@possible_data)
			{
			warn "\t$possible\n";
			}

		confess "use Class::Holon given invalid data for given key \n";

		}




	#######################################################################
	#split the package name between last '::' mark.
	#######################################################################
	$pkg =~ /^(.*)::(.*)$/;
	my $desc = $1;
	my $spec = $2;

	#######################################################################
	# handle SpecifyLevel testing... 
	#######################################################################
	if ($config{To} eq 'SpecifyLevel')
		{
		###############################################################
		# if Atom::Hydrogen is specifying a holon level,
		# then Atom holon MUST already exist.
		###############################################################
		confess "use Class::Holon() error: cannot SpecifyLevel '$pkg' ".
			"without defining its description '$desc' \n"
				unless(exists($master_config{$desc}));

		# @Atom::Hydrogen::ISA to include Atom
		no strict;
		push (@{$pkg.'::ISA'}, $desc)
			unless $pkg->isa($desc); # skip if already did this

		###############################################################
		# user cannot specify type. must inherit it.
		###############################################################
		if(exists($config{Type}))
			{
			warn "use Class::Holon to SpecifyLevel ($pkg) must inherit ".
				"Type from Described Level ($desc) \n";
			confess "use Class::Holon ( To => SpecifyLevel ) cannot".
				" indicate Type \n";
			}
		###############################################################
		# inherit type from described level.
		###############################################################
		$config{Type} = $master_config{$desc}->{Type};

		###############################################################
		# compare Data keys between specified and described level.
		# keys must match.
		###############################################################
		if($config{Type} eq 'Hash')
			{
			my @spec_keys = sort keys (%{$config{Data}});
			foreach my $spec_key (@spec_keys)
				{
				unless
					(exists
						(
				$master_config{$desc}->{Data}->{$spec_key}
						)	
					)
					{
					warn "use Class::Holon could not find Data ".
						" key '$spec_key' for $pkg ".
						"to match in $desc\n";
					confess "use Class::Holon ( ".
						"To=>SpecifyLevel,".
						"Data => {key=>value,...}) \n";
					}
				}
			}
		}

	#######################################################################
	# it passed all tests. store away in master configuration.
	#######################################################################
	$master_config{$pkg} = \%config;

	##########################################################
	# handle GetSet types
	# for every attribute name, we need to create a method
	# in the calling package to get and set the attributes.
	##########################################################
	if($config{Type} eq 'GetSet')
		{
		my $counter = 0;
		my @attributes = keys(%{$config{Data}});
		foreach my $attrib (@attributes)
			{
			my $holder = $counter;
			my %suffixes = 
			(
				'Get' => sub{return $_[0]->[$holder];},
				'Set' => sub{$_[0]->[$holder]=$_[1];},
			);

			my @keys = keys(%suffixes);
			foreach my $suffix (@keys)
				{
				my $method = $pkg.'::'.$attrib.$suffix;
				print "installing method $method \n" if $DEBUG;
				no strict;
				*{$method} = $suffixes{$suffix};
				}
			$counter++;
			}
		}



	#######################################################################
	# if 	SubInstances => Enabled,
	# then need to create a warehouse in the calling package
	# that will store any created holons and their sub_instances.
	#######################################################################
	if
	( 
		    exists($config{SubInstances}) 
		and ($config{SubInstances} eq 'Enabled') 
	)
		{
		no strict;
		%{$pkg.'::SubInstances'} = ();
		}

	#######################################################################
	# if this level includes any sublevels ('IncludeLevel')
	# then use them as base
	# else use Class::Holon as base
	#######################################################################
	my @sublevel = 'Class::Holon';
	if
	( 	exists($config{IncludeLevel})
		and defined($config{IncludeLevel})
	)
		{
		my $ref = ref($config{IncludeLevel});
		unless( $ref )
			{
			@sublevel = $config{IncludeLevel};
			}
		elsif ( $ref eq 'ARRAY' )
			{
			@sublevel = @{$config{IncludeLevel}};
			}
		else
			{
			confess "use Class::Holon (IncludeLevel=>...); ".
				"must point to a scalar or array ref \n";
			}
		}
	use_base($pkg, @sublevel);


	return 1;
}


##################################################################
# want to 'use base' from the calling package.
# and want all the 'included levels' to be base packages.
##################################################################

sub use_base 
{
	# using strings to find variables, turn off strict refs.
	no strict;

	my $pkg = shift;
	foreach my $base (@_)
		{	
		my $string = "package $pkg; \n use base $base; \n";
		eval($string);
		}
}



##################################################################
##################################################################

sub New
{
	my $container_instance='';
	if (ref($_[0]))
		{
		$container_instance = shift ;
		print "in Class::Holon::new for container_instance ".
			" $container_instance \n"
			if $DEBUG;
		}

	my $new_level=shift;
	print "in Class::Holon::new for new_level $new_level \n" if $DEBUG;

	confess "Error in call to Class::Holon::New(level). ".
		"Undefined / unspecified Holon Level '$new_level' \n"
		unless (exists($master_config{$new_level}));

	my %config = %{$master_config{$new_level}};

	##########################################################
	# Error check:
	# if Holon Description says to maintain a list of Subinstances,
	# then caller MUST use container_instance in Class::Holon::New call.
	# i.e.
	#	package Molecule;
	# 	my $molecule = Class::Holon::New('Molecule');
	# 	push(@{$molecule}, 
	#			$molecule->Class::Holon::New('Atom::Hydrogen'));
	# In this example, this  ^^^^^^^^ is the container.
	# The $molecule instance will 'contain' the new hydrogen atom instance.
	# 
	# Note that if package we are in (Molecule) is the same
	# as the new Holon ( Class::Holon::New('Molecule') )
	# then it does not use a container, since
	##########################################################
	my ($caller_package) = caller(0);
	print "caller_package is $caller_package\n" if $DEBUG;

	my %caller_config;

	if(exists($master_config{$caller_package}))
		{
		%caller_config = %{$master_config{$caller_package}};

		##################################################
		# Error check:
		# this is bad:   
		# package Molecule; 
		# use Class::Holon ( ..., SubInstances => Enabled );
		#    ... Class::Holon::New('Atom');
		# 
		# that last line should be
		#    ... $molecule->Class::Holon::New('Atom');
		##################################################

		if
		(
			    ($caller_package ne $new_level)
			and (exists($caller_config{SubInstances}))
			and ($caller_config{SubInstances} eq 'Enabled')
			and (!($container_instance))
		)
			{
			confess "Error:\n".
			"SubInstances is Enabled for level".
			" '$caller_package'. \n" .
			"Must use containing instance when calling ".
			"Class::Holon::New inside package ".
			"'$caller_package'.\n".
			"i.e. \$molecule->Class::Holon::New('Atom') \n";
			}

		}

	##########################################################
	# Error check:
	# if we we have SOME kind of container_instance,
	# make sure container is blessed into the same package
	# that this was called from.
	# bad:   
	# package Molecule; $unrelated_object=Class::Holon::New('Atom');
	##########################################################
	if
	(
		($container_instance)
		and ( ref($container_instance) ne $caller_package )
	)
		{
		confess "Error:\n".
		"Class::Holon::New called with a container instance ".
		"blessed into a different package \n".
		ref($container_instance)." as ".
		"the package Class::Holon::New is being called from.\n".
		"$caller_package \n".
		"i.e. package Molecule; \n".
		"\$unrelated_object=Class::Holon::New('Atom'); \n";
		}

	##########################################################
	# Error check:
	# do not use container_instances when creating a holon
	# that is the same type as the container.
	# bad:   $molecule=Class::Holon::New('Molecule');  
	##########################################################
	if(ref($container_instance) eq $new_level)
		{
		confess "Error:\n".
		"Containing instance is same type as new Holon ".
		"(circular reference).\n".
		"In package '$new_level' do not use container instance ".
		"when \n".
		"creating new '$new_level' Holons.\n";
		}


	##########################################################
	# declare object, then handle how to initialize it.
	##########################################################
	my $obj;

	##########################################################
	# handle hash types
	##########################################################
	if($config{Type} eq 'Hash')
		{
		my %hash;
		%hash = %{$config{Data}} if(exists($config{Data}));

		my @keys = keys(%hash);
		foreach my $key (@keys)
			{
			if (ref($hash{$key}) eq 'CODE')
				{
				$hash{$key} = &{$hash{$key}}();
				}
			}

		$obj = \%hash;
		}
	##########################################################
	# handle array types
	##########################################################
	if($config{Type} eq 'Array')
		{
		my @array;
		@array = @{$config{Data}} if(exists($config{Data}));

		my $element;
		foreach $element (@array)
			{
			if(ref($element) eq 'CODE')
				{
				$element = &{$element}();
				}

			}

		$obj=\@array;
		}
	##########################################################
	# handle getset types
	##########################################################
	if($config{Type} eq 'GetSet')
		{
		my @array;

		my @att_keys = keys(%{$config{Data}});
		foreach my $att_key (@att_keys)
			{
			my $val = ${$config{Data}}{$att_key};
			push(@array, $val);
			}

		my $element;
		foreach $element (@array)
			{
			if(ref($element) eq 'CODE')
				{
				$element = &{$element}();
				}

			}

		$obj=\@array;
		}




	bless $obj, $new_level;

	
	##########################################################
	# if SubInstances are Enabled,
	# then every time we create a new holon subinstance,
	# store that holon in the SubInstances array for that level.
	##########################################################
	if
	( 
		    $container_instance
		and exists($caller_config{SubInstances}) 
		and ($caller_config{SubInstances} eq 'Enabled') 
	)
		{

		no strict;
		# weaken (
			push(@{${$caller_package.'::SubInstances'}
				{$container_instance}}, $obj );
		# );
		}

	##########################################################
	# if Instances are Enabled for this level,
	# then every time we create a new holon instance,
	# store that holon in the Instances array for that level
	##########################################################
	if
	( 
		    (exists($config{Instances}))
		and ($config{Instances} eq 'Enabled') 
	)
		{
		no strict;
		# weaken (
			push(@{$new_level.'::Instances'}, $obj );
		# );
		}



	return $obj;
}

 



1;
__END__

=head1 NAME

Class::Holon -  An experiment in redefining class declarations / object instantiation in perl.

=head1 SYNOPSIS

	package Atom;
	use Class::Holon 
	( 
		To => DescribeLevel, 
		Type => Hash,
		Data => { protons=>0, neutrons=>0, electrons=>0 },
	);
	

	package main;
	use Atom;
	my $atom = Class::Holon::New('Atom');

=head1 DESCRIPTION

This module is an experiment in redefining class declarations and 
object instantiation in perl. The intent is to eventually encapsulate
many of the common things that classes and objects find useful so that
people do not have to reinvent the wheel to use them. I would also like
for it to make certain capabilities available to programmers that are
not available in native perl.

=head1 VOCABULARY

The term C<Holon> was blatantly stolen from Authur Koestler (1905-1983).
I believe he coined the term in 1967, but I'm not certain. I was actually
introduced to the term via a book written by Ken Wilber, but I digress.

First, some definitions: 

=head1 HOLON DEFINITION

Holon

A holon is a node in a tree structure. Holon comes from the Greek 
holos meaning "whole" and on meaning "part" or particle. The key 
characteristics of a holon include that it asserts its individuality 
in order to maintain the set order in the tree structure, but it 
also submits to the demands of the whole tree structure (the system) 
in order to make the system viable. Holons are self-contained, 
autonomous pieces which follow a prescribed set of rules. The holon 
has a "self-assertiveness tendency" (wholeness) as well as an 
"integrative tendency" (part).This duality is similar to the 
particle/wave duality of light.  (Koestler) 

Once you have some Holons, you can put them in a structure called a holarchy.

=head1 HOLARCHY DEFINITION

Holarchy

A holarchy is a hierarchy of holons. Entire organs such as the kidneys, 
heart, and brain are capable of continuing their functions, as 
quasi-independent wholes, when isolated from the organism and suplied 
with the proper nutrients.

Characteristics of Holarchies: 

Bi-directionality: Each holon can receive signals as well as send 
	signals. The "flow" in a holarchy is both up and down. 

Level behaviour: The holon at one level is not necessarily the "sum" 
	of its subordinates. The characteristics of holons at one
	level are not representative of the characteristics of the 
	level above or below them. The further down the holarchy, 
	the more mechanized, stereotyped, and predictable the behavior. 
	Higher level holons have more flexibility and function a more
	abstract state. 

Flexibility: Holarchies are not rigid structures; they allow modification 
	and adaptability. A holon can be part of multiple holarchies. 

Open-ended: The top and the bottom of holarchies are not absolute. 
	A holarchy can be augmented or interwoven with another holarchy. 


=head1 HOLONS IN PERL

You can I<Describe> a holon level.

	use Class::Holon ( To => DescribeLevel, ... );

You can I<Specify> a specific type of holon level.

	use Class::Holon ( To => SpecifyLevel, ... );

You can I<Instantiate> new holons based on their description / specification.

	my $instance = Class::Holon::New( ... );

I<Describe> and I<Specify> defines what a holon looks like.
Once a holon is defined, you can I<Instantiate> them.

=head1 DESCRIBING A LEVEL

A perl package namespace is used to give a holon level its I<Name>. Each
package can call C<use Class::Holon (...)> I<once and only once> to describe or 
specify a level.

If you find you have defined a holon that has a C<Name> attribute, then 
you should rethink your entire approach. 

The I<perl package> that calls C<use Class::Holon> determines the I<holon name>.

So, say you want to define an "Atom" holon. First, get into package Atom.
Then call C<use Class::Holon ();> with the appropriate attributes.

	package Atom;
	use Class::Holon 
	( 
		To => DescribeLevel, 
		Type => Hash,	
		Data => { protons=>0, neutrons=>0, electrons=>0 },
	);
	1; # thats it!

Or say you want to define a "Movable" holon, which keeps track of x,y,z 
coordinates of something.

	package Movable;
	use Class::Holon  
	( 
		To => DescribeLevel, 
		Type => Hash,
		Data => { posx=>0, posy=>0, posz=>0 },	
	);


Or, say you want to define a "Dogtag" holon.

	package Dogtag;
	use Class::Holon 
	( 
		To => DescribeLevel, 
		Type => Hash,	
		Data => { Name=>'', Rank=>'', SerialNumber=>0 },
	);

Or, say you want to define a "Bucket" holon that stores an array of scalars.

	package Bucket;
	use Class::Holon
	(
		To => DescribeLevel,
		Type => Array,
		Data => [],
	);

Last, but not least, say you want to define a "Helicopter" holon.
And like a helicopter, it's fast and small, but somewhat difficult to control.

	package Helicopter;
	use Class::Holon
	(
		To => DescribeLevel,
		Type => GetSet,
		Data => { Speed=>0, Altitude=>0 },
	);

I'll go into more detail about the "GetSet" type later.


C<To> has two possible valid values, C<DescribeLevel> and C<SpecifyLevel>.

C<Type> has three possible valid values, C<Hash>, C<Array>, and C<GetSet>.

C<Data> will define the attributes, and possibly, their initial value.

C<Data> is where the attributes for the holon are defined. Note that 
C<Dogtag> has a I<Name> attribute. This is OK in this case, since the
I<Name> of the holon is C<Dogtag>. The C<Name> attribute in this case
refers the name of the person associated with each C<Dogtag> instance.

If your C<Data> has defined a C<Name> attribute, just make sure you're 
defining your holons properly.

=head1 VARIATIONS ON C<DATA>

The C<Data> entry has a number of different flavors.

If C<Type> is a C<Hash> or C<GetSet>, then C<Data> can indicate the
attribute names using an array reference.

	Type => Hash,
	Type => GetSet,
	Data => [ attribute1, attribute2, attribute3, ... ],

If C<Type> is a C<Hash> or C<GetSet>, then C<Data> can use a
reference a hash, where the I<keys> indicate the attribute names,
and the I<Data> indicates its initial value.

	Type => Hash,
	Type => GetSet,
	Data => {
		attribute1 => initial_value1,
		attribute2 => initial_value2,
		...
		},

Note, that if I<ANY> attribute has an initial value, then they I<ALL>
must have an initial value. If you care about some initial values,
but dont care about others, just use C<undef> for the ones you don't
care about.

If C<Type> is an C<Array>, then C<Data> can I<ONLY> be a reference
to an array. The contents of the array indicate the initial values
of an array instance, rather than the attribute names.

	Type => Array,
	Data => [ init_value_index_0, init_value_index_1, ... ],


Holons of type C<Array> and C<Hash> do not need to indicate C<Data>.
The instances are references to normal arrays/hashes, therefore,
they can autovivify as usual.

Holons of type C<GetSet> must define its C<Data> attributes so that
C<use Class::Holon> can create the necessary methods in the proper package.

Note, if the initial value is a subroutine reference, the subroutine
will be executed upon an object's instantiation.

	package Frankenstein;
	use Class::Holon ( To => DescribeLevel, Type => Hash,
		Data => { Yell => sub { print "It's ALIVE!!"; } },
	);

	package main;
	use Frankenstein;	# no output here.

	my $monster = Class::Holon::New('Frankenstein'); # It's ALIVE!!

	&{$monster->{Yell}}();	# It's ALIVE!!

=head1 CREATING AN INSTANCE OF A HOLON

Once you've described a holon level, you can create instances of that
level. The description of the level does NOT need to define a constructor.
You have already defined everything perl needs to know in the 
C<use Class::Holon(...)> call.

	package main;
	use Atom;
	my $atom_instance = Class::Holon::New('Atom');

Note that package C<main> did not have to say C<use Class::Holon>. This
is because when main calls C<use Atom>, package Atom will call
C<use Class::Holon>, and C<use Class::Holon> will pull the C<Class::Holon.pm> perl
package into the mix. You only have to C<use> whatever holons
you are using directly. Everything else is handled under the
hood by the Holon module.

Class::Holon::New takes one parameter, the name of the level to create.
This coincides with the name of the perl package that called 
C<use Class::Holon (...);> In this case, Class::Holon::New('Atom') will return 
an instance of whatever holon was described in C<package Atom;>. 

The instance is in the form of a reference to what ever I<Type> was
defined for that holon. In this case, it is a reference to a hash.

The instance is a reference, and whatever it is pointing to 
(the referent) will be blessed into the package of the holon level. 
In this case, it is blessed into the C<Atom> package.

The instance will be initialized to any values given in C<Data>.
In this case, $instance will refer to a hash containing the keys
C<Name>, C<Rank>, and C<SerialNumber>.

If an initial value is given to C<use Class::Holon> in the form of
a code reference, then that code reference will be executed
at instantiation.  See above for more info on 

	use Class::Holon ( Data => ... )

=head1 GETTING MORE SPECIFIC DESCRIPTIONS

Let's assume we've been tasked with writing some perl code that 
will allow us to model chemical experiments. (I'm not a chemist,
but I play on TV.)

The Atom holon seems to be a good start. However, since we're talking
about chemical experiments and not physics, its probably safe to assume
that our application will not need to split atoms. Therefore, we could 
describe specific atoms.

When you I<Specify> a holon level, you are taking a I<description> 
and making it more specific.

The I<names> of the I<attributes> remain the same. But the I<values>
can be different.

In perl, the keys of the C<Data> hash are the same, 
but the values can be different.

In the Atom example, it might look like this:

	package Atom::Hydrogen;
	use Class::Holon (
		To => SpecifyLevel, 
		Data => { protons=>1, neutrons=>0, electrons=>1 },	
	);
	
	package Atom::Oxygen;
	use Class::Holon (
		To => SpecifyLevel, 
		Data => { protons=>8, neutrons=>8, electrons=>8 },	
	);

Note, we are no longer defining C<Type>. 
Instead, we use the same C<Type> that was given in C<Atom>.

Also note that we are defining different I<Values> for C<Data>.
The I<Attributes> I<MUST> match the attributes used to define C<Atom>.

This may or may not have a use in your application. If a subroutine is
called on Atom, and a large case statement is needed to determine 
how to handle the Atom based on which atom it is, then it may be
advantageous to give the Atom a qualifying name so that the 
proper subroutine can be called more directly. (this would be the
approach for using multimethods, but we're getting ahead of ourselves.)

=head1 THE GETSET TYPE

The holon type C<GetSet> is a little different than the others.
The data in the holon is stored in an inaccessible array.
The only means to access the data is via method calls.
The names of the methods are the names of the C<Data> attributes,
but with a suffix to indicate what action to perform. These methods
are imported in the package when you call C<use Class::Holon>.


For instance:

	package Helicopter;
	use Class::Holon (
		To => SpecifyLevel,
		Type => GetSet,
		Data => { Speed=>0, Altitude=>0 },
	);

	package main;
	my $jetranger = Class::Holon::New('Helicopter');

	$jetranger->SpeedSet(110);
	my $altitude = $jetrange->AltitudeGet;

The type C<GetSet> hides the attribute implementation
from the user. The array data contained in each object is
not accessible except through the methods.

The method names are based off of the attribute name. The intention
is to have the methods act like hash keys to make them easy to use, 
but for the object to have the speed and size as close to an array 
as possible.

Given an attribute name in the C<Data> C<Description>, the following
methods are available to call on an object.

	attributeGet	return the value of the attribute
	attributeSet	store a new value in the attribute
	attributeInc	increment the value of the attribute by 1.
	attributeDec	decrement the value of the attribute by 1.
	attributeAdd	Add a value to the attribute
	attributeSub	Subtract a value from the attribute	
	attributeMul	Multiply the attribute by some value	
	attributeDiv	Divide the attribute by some value	
	attributeNeg	Negate the attribute (multiply by -1)	
	attributeMod	Take the modulus of the attribute and put in attribute	

This means that in the above example, after calling C<use Class::Holon>, 
package Helicopter would contain subroutines such as:

	SpeedGet
	SpeedSet
	AltitudeGet
	AltitudeSet
	

Note, C<Get> and C<Set> may change to C<Rd> and C<Wr> 
Get and Set are too similar for my comfort.


=head1 THE NEXT LEVEL UP

DEBUG: introduce MovableAtom module.

Documentation ran out of steam at this point. skipping to ending boiler plate.


=head1 BUGS

none known so far.


=head1 QUOTES

True creativity often starts where language ends   - Authur Koestler

=head1 DSLIP

DSLIP = ADPHP

=head1 AUTHOR

Greg London
http://www.greglondon.com

=head1 COPYRIGHT NOTICE

Copyright (c) 2001 Greg London. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
