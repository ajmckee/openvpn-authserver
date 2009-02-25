#!/usr/bin/perl

#
#  OpenVPN Authserver -- An open framework to provide various authentication
#                        methods to OpenVPN in a standardized way
#
#  Copyright (C) 2009 sedOSS <jpetersson@sedoss.com>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License version 2
#  as published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#

use strict;
use warnings;

use Config::General;

my $config;
my %config;

$config = new Config::General("config.xml");
%config = $config->getall;

sub writeLog {

    use Date::Format;

    my $datestring = time2str("%a %b %d %H:%M:%S %Z %Y", time);

    open FILE, ">>".$config{'general'}{'logfile'} or die $!;
    print FILE $datestring." authserv: [$$]: ".$_[0]."\n";
    close FILE;
}

sub getOpts {
    
    use Getopt::Long;

    my $help;
    my $verbose;

    Getopt::Long::GetOptions(
	'help|h'    => \$help,
	'verbose|v' => \$verbose,
	);


    if (defined($help)) {

	print "
  Syntax: $0 [-h]
          
  This server is written to...
	        
  Options:
      -h|--help            : Show this help text
      -v|--verbose         : Run in verbose mode

";
    }
}

sub connMgmt {

    my(%hash) = %{(shift)};

    use IO::Socket;

    my $sock = new IO::Socket::INET (
	PeerAddr => $hash{'host'},
	PeerPort => $hash{'port'},
	Proto    => 'tcp',
	) or writeLog("Unable to connect to $hash{'name'} [$$]: $!");

    if($sock) {
	# Do something
    }
}

sub instanceInit (\%)  {
    my $key;
    my(%hash) = %{(shift)};

    for my $key ( keys %hash ) {
	if (!defined($hash{$key}{'host'}) ||
	    !defined($hash{$key}{'name'}) ||
	    !defined($hash{$key}{'port'})
	    ) {
	    writeLog("WARNING: Your instance configuration is incomplete");
	    termDaemon();
	}

	next if my $pid = fork;
	writeLog("fork failed to initiate - $!") and die unless defined $pid;

	$! = 1;

	connMgmt($hash{$key});
	exit(fork);
    }

}

sub termDaemon {
    writeLog("authserver: [$$]: Stopping");
    exit 0;
}

sub init {
    unlink($config{'general'}{'logfile'});
    writeLog("authserver: [$$]: Starting");
    instanceInit(%{$config{'instances'}});
}

init();
