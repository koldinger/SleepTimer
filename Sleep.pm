# Sleep.pm by Eric Koldinger (kolding@yahoo.com)
# Copyright 2004 by Eric Koldinger
# Derived code is copyright it's original authors.
#
# Sleep will run a sleep timer for a specified period, and turn
# the player off when the time has been reached.  No configuration
# parameters are saved, and the timer will be shutdown if you turn
# the timer off, or turn the player off manually.
#
# All settings are accessed in the Player Plugin menu.
#
# Butchered from:
# PowerSave.pm by Jason Holtzapple (jasonholtzapple@yahoo.com)
# which in turn credits the following:
#
# 	Some code and concepts were copied from these plugins:
#
# 	Rescan.pm by Andrew Hedges (andrew@hedges.me.uk)
# 	Timer functions added by Kevin Deane-Freeman (kevindf@shaw.ca)
#
# 	QuickAccess.pm by Felix Mueller <felix.mueller(at)gwendesign.com>
#
# 	And from the AlarmClock module by Kevin Deane-Freeman (kevindf@shaw.ca)
# 	Lukas Hinsch and Dean Blackketter
#
# This code is derived from code with the following copyright message:
#
# SliMP3 Server Copyright (C) 2001 Sean Adams, Slim Devices Inc.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.
#

use strict;

package Plugins::Sleep;

use Slim::Utils::Strings qw (string);
use Slim::Utils::Misc;
use Time::HiRes;

use vars qw($VERSION);
$VERSION = '0.0.4';

my %sleepTimers   	= ();
my %sleepLengths  	= ();
my %sleepTimes  	= ();
my $timeDefault		= 0;

sub setMode {
	my $client = shift;
	$client->lines(\&lines);
}

sub getDisplayName() {
	return string('PLUGIN_SLEEP');
}

my %functions = (
	'up' => sub  {
		my $client = shift;

		$client->bumpUp();
	},
	'down' => sub  {
		my $client = shift;

		$client->bumpDown();
	},
	'left' => sub  {
		my $client = shift;
		Slim::Buttons::Common::popModeRight($client);
	},
	'right' => sub  {
		my $client = shift;

		# Make sure there's something in the sleepLengths field.
		$sleepLengths{$client} = 0 if (!defined $sleepLengths{$client});

		# List of options
		my @menuTimerChoices = (
			string('PLUGIN_SLEEP_INTERVAL_1'),
			string('PLUGIN_SLEEP_INTERVAL_2'),
			string('PLUGIN_SLEEP_INTERVAL_3'),
			string('PLUGIN_SLEEP_INTERVAL_4'),
			string('PLUGIN_SLEEP_INTERVAL_5'),
			string('PLUGIN_SLEEP_INTERVAL_6'),
		);

		# Convert the options into times.
		# Relies on the fact that the option strings are in the form
		# xx minutes
		# where xx is a number
		my @menuTimerIntervals =
			map { 60 * ($_ =~ /(\d+)/)[0] } @menuTimerChoices;

		my %params = (
			'listRef' 	=> [ 0, 			 @menuTimerIntervals ],
			'externRef' 	=> [ string('PLUGIN_SLEEP_OFF'), @menuTimerChoices ],
			'header' 	=> string('PLUGIN_SLEEP'),
			'valueRef' 	=> \ ($sleepLengths{$client}),
			'onChange' 	=> sub { setTimer($_[0], $_[1])},
		);
		Slim::Buttons::Common::pushModeLeft($client, 'INPUT.List', \%params);
	}
);

sub getFunctions() {
	return \%functions;
}

sub lines {
	my $client = shift;

	my ($line1, $line2);

	$line1 = string('PLUGIN_SLEEP');

	if (defined $sleepTimers{$client})
	{
		$line2 = string('PLUGIN_SLEEP_ON');
	} else {
		$line2 = string('PLUGIN_SLEEP_OFF');
	}

	return ($line1, $line2, undef, Slim::Hardware::VFD::symbol('rightarrow'));
}

sub doSleep {
	my $client = shift;
	my $now = time();
	$::d_plugins && msg($client->name() . ": Now $now (Expected $sleepTimes{$client}).  Turning off.\n");
	unsetTimer($client);
	if ($client->isPlayer()) {
	    $client->fade_volume(-15, \&Slim::Control::Command::turnitoff, [$client]);
	}
}

sub setTimer {
	my $client = shift;
	my $delay = shift;
	unsetTimer($client);
	$sleepLengths{$client} = $delay;
	my $now = time();
	my $later = $now + $delay;
	$sleepTimes{$client} = $later;
	if ($delay != 0) {
		$::d_plugins && msg($client->name . ": Setting timer for $delay seconds ($now, $later)\n");
		$sleepTimers{$client} =
			Slim::Utils::Timers::setTimer ($client, $later, \&doSleep);
		#my $timer = $sleepTimers{$client};
		#$::d_plugins && msg($client->name . ": Timer set.  " . $timer->{'when'} . "  " . $timer . "\n");
		#$::d_plugins && msg($client->name . ": Timers pending: " . Slim::Utils::Timers::pendingTimers($client, \&doSleep) . "\n");
	}
}

sub unsetTimer {
	my $client = shift;
	if (defined $sleepTimers{$client}) {
		$::d_plugins && msg($client->name() . ": Unsetting timer\n");
		Slim::Utils::Timers::killSpecific ($sleepTimers{$client});
	}
	$sleepTimers{$client} = undef;
	$sleepLengths{$client} = 0;
}

sub strings
{
    local $/ = undef;
    <DATA>;
}

sub callback {
    my $client = shift;
    my $args = shift;

    return if (!defined $client);
    my $command = @$args[0];
    if ($command eq "power") {
	if (!$client->power()) {
	    $::d_plugins && msg($client->name() . ": Power off\n");
	    unsetTimer($client);
	}
    }
}

Slim::Control::Command::setExecuteCallback(\&Plugins::Sleep::callback);

1;

__DATA__

PLUGIN_SLEEP
	EN	Sleep Timer
	
PLUGIN_SLEEP_DESC
	EN	Turns your player off after a set period of inactivity. Set the time to enable this function.

PLUGIN_SLEEP_OFF
	EN	Sleep Timer Off

PLUGIN_SLEEP_ON
	EN	Sleep Timer On

PLUGIN_SLEEP_INTERVAL_1
	EN	15 minutes

PLUGIN_SLEEP_INTERVAL_2
	EN	30 minutes

PLUGIN_SLEEP_INTERVAL_3
	EN	45 minutes

PLUGIN_SLEEP_INTERVAL_4
	EN	60 minutes

PLUGIN_SLEEP_INTERVAL_5
	EN	90 minutes

PLUGIN_SLEEP_INTERVAL_6
	EN	120 minutes
