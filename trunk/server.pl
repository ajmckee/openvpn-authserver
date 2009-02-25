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
use Date::Format; 

my $config;
my %config;

$config = new Config::General("config.xml");
%config = $config->getall;

sub writeLog {
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

    use IO::Socket;

    my $sock = new IO::Socket::INET (
	PeerAddr => $_[1],
	PeerPort => $_[2],
	Proto    => 'tcp',
	) or writeLog("Unable to connect to $_[0] [$$]: $!");

    if($sock) {
	# Do something
    }
}

sub loopMgmt;
sub loopMgmt (\%) {
    
    my $key;
    my $value;

    my(%hashdata) = %{(shift)};
    
    while(($key, $value) = each(%hashdata)) {
	if (ref($value) eq 'HASH') {
	    next if my $pid = fork;
	    writeLog("fork - $!") and die unless defined $pid;

	    $| = 1;

	    connMgmt($config{'instances'}{$key}{'name'},
		     $config{'instances'}{$key}{'host'},
		     $config{'instances'}{$key}{'port'},
		);

	    exit(fork);
	}
    }
}

sub init {
    unlink($config{'general'}{'logfile'});
    writeLog("authserver: [$$]: Starting");
    loopMgmt(%{($config{'instances'})});
    writeLog("authserver: [$$]: Stopping");
}

init();
