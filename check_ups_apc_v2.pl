#!/usr/bin/perl

#    Copyright (C) 2004 Altinity Limited
#    E: info@altinity.com    W: http://www.altinity.com/
#    Modified by Andreas Winter <info@aw-edv-systeme.de>
#    
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#    
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the
#    GNU General Public License for more details.
#    
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA    02111-1307    USA
#
############
#
#	Script edit by Blueeye 2010.03.17 (dj-blueeye@gmx.de)
#	* adding perfdata for Battery Capacity
#	* adding Frequency-Monitoring (with perfdata)
#	* added Voltage-Monitoring (Input/Output and Perfdata)
#
############
#
#	Script edit by Andreas Winter (info@aw-edv-systeme.de)
#	* adding Battery Replacement check
#
############
#
#	Script modified by M. Fuchs
#	* added custom warning temperature
#
############


use Net::SNMP;
use Getopt::Std;

$script    = "check_ups_apc_v2.pl";
$script_version = "2.0";

$metric = 1;

$ipaddress = "192.168.1.1"; 	# default IP address, if none supplied
$version = "1";			# SNMP version
$timeout = 2;				# SNMP query timeout
# $warning = 100;			
# $critical = 150;
$status = 0;
$returnstring = "";
$perfdata = "";

$community = "public"; 		# Default community string

$oid_sysDescr = ".1.3.6.1.2.1.1.1.0";
$oid_upstype = ".1.3.6.1.4.1.318.1.1.1.1.1.1.0";
$oid_battery_capacity = ".1.3.6.1.4.1.318.1.1.1.2.2.1.0";
$oid_output_status = ".1.3.6.1.4.1.318.1.1.1.4.1.1.0";
$oid_output_current = ".1.3.6.1.4.1.318.1.1.1.4.2.4.0";
$oid_output_load = ".1.3.6.1.4.1.318.1.1.1.4.2.3.0";
$oid_temperature = ".1.3.6.1.4.1.318.1.1.1.2.2.2.0";

$oid_input_freq = ".1.3.6.1.4.1.318.1.1.1.3.2.4.0";		# added by Blueeye
$oid_output_freq = ".1.3.6.1.4.1.318.1.1.1.4.2.2.0";	# added by Blueeye
$oid_input_volt = ".1.3.6.1.4.1.318.1.1.1.3.2.1.0";		# added by Blueeye
$oid_output_volt = ".1.3.6.1.4.1.318.1.1.1.4.2.1.0";	# added by Blueeye
$oid_battery_replace = "1.3.6.1.4.1.318.1.1.1.2.2.4.0";	# added by AW
$oid_serial = "1.3.6.1.4.1.318.1.1.1.1.2.3.0"; # added by AW

$upstype = "";
$battery_capacity = 0;
$output_status = 0;
$output_current =0;
$output_load = 0;
$temperature = 0;
$warn_temperature = 35;	# M. Fuchs

$input_freq = 0;		# added by Blueeye
$output_freq = 0;		# added by Blueeye
$input_volt = 0;		# added by Blueeye
$output_volt = 0;		# added by Blueeye
$battery_replace = 1;		# added by AW
$ups_serial = "";		# added by AW


# Do we have enough information?
if (@ARGV < 1) {
     print "Too few arguments\n";
     usage();
}

getopts("h:H:C:T:w:c");
if ($opt_h){
    usage();
    exit(0);
}
if ($opt_H){
    $hostname = $opt_H;
}
else {
    print "No hostname specified\n";
    usage();
}
if ($opt_C){
    $community = $opt_C;
}
else {
}

if ($opt_T){
    $warn_temperature = $opt_T;
}
else {
}


# Create the SNMP session
my ($s, $e) = Net::SNMP->session(
     -community  =>  $community,
     -hostname   =>  $hostname,
     -version    =>  $version,
     -timeout    =>  $timeout,
);

main();

# Close the session
$s->close();

if ($status == 0){
    print "Status is OK - $returnstring|$perfdata\n";
    # print "$returnstring\n";
}
elsif ($status == 1){
    print "Status is a WARNING level - $returnstring|$perfdata\n";
}
elsif ($status == 2){
    print "Status is CRITICAL - $returnstring|$perfdata\n";
}
else{
    print "Problem with plugin. No response from SNMP agent.\n";
}
 
exit $status;


####################################################################
# This is where we gather data via SNMP and return results         #
####################################################################

sub main {

        #######################################################
 
    if (!defined($s->get_request($oid_upstype))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $upstype = $s->var_bind_list()->{$_};
    }
    
    #######################################################
 
    if (!defined($s->get_request($oid_battery_capacity))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $battery_capacity = $s->var_bind_list()->{$_};
    }

    #######################################################
 
    if (!defined($s->get_request($oid_output_status))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $output_status = $s->var_bind_list()->{$_};
    }
    #######################################################
 
    if (!defined($s->get_request($oid_output_current))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $output_current = $s->var_bind_list()->{$_};
    }
    #######################################################
    #++++++++++++++++++++++++++++++++++++++++++++++++++++

    if (!defined($s->get_request($oid_battery_replace))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $battery_replace = $s->var_bind_list()->{$_};
    }
    #++++++++++++++++++++++++++++
    if (!defined($s->get_request($oid_serial))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $ups_serial = $s->var_bind_list()->{$_};
    }

    #++++++++++++++++++++++++++++++++++++++++++++++++++++


    if (!defined($s->get_request($oid_output_load))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $output_load = $s->var_bind_list()->{$_};
    }
    #######################################################
  
    if (!defined($s->get_request($oid_temperature))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $temperature = $s->var_bind_list()->{$_};
    }
    #######################################################
	  
    if (!defined($s->get_request($oid_input_freq))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $input_freq = $s->var_bind_list()->{$_};
    }

    #######################################################
    
	if (!defined($s->get_request($oid_output_freq))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $output_freq = $s->var_bind_list()->{$_};
    }
    
    #######################################################
	
	if (!defined($s->get_request($oid_input_volt))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $input_volt = $s->var_bind_list()->{$_};
    }

    #######################################################
	
    if (!defined($s->get_request($oid_output_volt))) {
        if (!defined($s->get_request($oid_sysDescr))) {
            $returnstring = "SNMP agent not responding";
            $status = 1;
            return 1;
        }
        else {
            $returnstring = "SNMP OID does not exist";
            $status = 1;
            return 1;
        }
    }
     foreach ($s->var_bind_names()) {
         $output_volt = $s->var_bind_list()->{$_};
    }

    #######################################################
	
    $returnstring = "";
    $status = 0;
    $perfdata = "";

    if (defined($oid_upstype)) {
        $returnstring = "$upstype - ";
    }

    if ($battery_capacity < 25) {
        $returnstring = $returnstring . "BATTERY CAPACITY $battery_capacity% - ";
		$perfdata = $perfdata . "'capacity'=$battery_capacity%;50;25 ";
        $status = 2;
    }
    elsif ($battery_capacity < 50) {
        $returnstring = $returnstring . "BATTERY CAPACITY $battery_capacity% - ";
		$perfdata = $perfdata . "'capacity'=$battery_capacity%;50;25 ";
        $status = 1 if ( $status != 2 );
    }
    elsif ($battery_capacity <= 100) {
        $returnstring = $returnstring . "BATTERY CAPACITY $battery_capacity% - ";
		$perfdata = $perfdata . "'capacity'=$battery_capacity%;50;25 ";
    }
    else {
        $returnstring = $returnstring . "BATTERY CAPACITY UNKNOWN! - ";
        $status = 3 if ( ( $status != 2 ) && ( $status != 1 ) );
    }

    if ($output_status eq "2"){
        $returnstring = $returnstring . "STATUS NORMAL - ";
    }
    elsif ($output_status eq "3"){
        $returnstring = $returnstring . "UPS RUNNING ON BATTERY! - ";
        $status = 1 if ( $status != 2 );
    }
    elsif ($output_status eq "9"){
        $returnstring = $returnstring . "UPS RUNNING ON BYPASS! - ";
        $status = 1 if ( $status != 2 );
    }
    elsif ($output_status eq "10"){
        $returnstring = $returnstring . "HARDWARE FAILURE UPS RUNNING ON BYPASS! - ";
        $status = 1 if ( $status != 2 );
    }
    elsif ($output_status eq "6"){
        $returnstring = $returnstring . "UPS RUNNING ON BYPASS! - ";
        $status = 1 if ( $status != 2 );
    }
    else {
        $returnstring = $returnstring . "UNKNOWN OUTPUT STATUS! - ";
        $status = 3 if ( ( $status != 2 ) && ( $status != 1 ) );
    }


    if ($output_load > 90) {
        $returnstring = $returnstring . "OUTPUT LOAD $output_load% - ";
        $perfdata = $perfdata . "'load'=$output_load%;80;90 ";
        $status = 2;
    }
    elsif ($output_load > 80) {
        $returnstring = $returnstring . "OUTPUT LOAD $output_load% - ";
        $perfdata = $perfdata . "'load'=$output_load%;80;90 ";
        $status = 1 if ( $status != 2 );
    }
    elsif ($output_load >= 0) {
        $returnstring = $returnstring . "OUTPUT LOAD $output_load% - ";
        $perfdata = $perfdata . "'load'=$output_load%;80;90 ";
    }
    else {
        $returnstring = $returnstring . "OUTPUT LOAD UNKNOWN! - ";
        $perfdata = $perfdata . "'load'=NAN ";
        $status = 3 if ( ( $status != 2 ) && ( $status != 1 ) );
    }

    if ($temperature > 38) {
        $returnstring = $returnstring . "!!!CRITICAL TEMPERATURE!!! $temperature C - ";
        $perfdata = $perfdata . "'temp'=$temperature;$warn_temperature;38;0;70 ";
        $status = 2;
    }
    elsif ($temperature > $warn_temperature) {
        $returnstring = $returnstring . "!!!WARNING TEMPERATURE!!! $temperature C - ";
        $perfdata = $perfdata . "'temp'=$temperature;$warn_temperature;38;0;70 ";
        $status = 1 if ( $status != 2 );
    }
    elsif ($temperature >= 0) {
        $returnstring = $returnstring . "TEMPERATURE $temperature C - ";
        $perfdata = $perfdata . "'temp'=$temperature;$warn_temperature;38;0;70 ";
    }
    else {
        $returnstring = $returnstring . "TEMPERATURE UNKNOWN! - ";
        $perfdata = $perfdata . "'temp'=NAN ";
        $status = 3 if ( ( $status != 2 ) && ( $status != 1 ) );
    }

	
    if ( ($input_freq > 53 ) ||  (($input_freq < 47 ) && ($input_freq >= 0)) ) {
        $returnstring = $returnstring . "!!!CRITICAL FREQUENCE-IN!!! $input_freq Hz - ";
        $perfdata = $perfdata . "'infreq'=$input_freq;;;45;55 ";
        $status = 2;
    }
    elsif  ( ($input_freq < 53 ) &&  ($input_freq > 47 ) ) {
        $returnstring = $returnstring . "FREQUENCE-IN $input_freq Hz - ";
        $perfdata = $perfdata . "'infreq'=$input_freq;;;45;55 ";
    }
    else {
        $returnstring = $returnstring . "FREQUENCE-IN UNKNOWN! - ";
        $perfdata = $perfdata . "'infreq'=NAN ";
        $status = 3 if ( ( $status != 2 ) && ( $status != 1 ) );
    }
	
    if ( ($output_freq > 53 ) ||  ( ($output_freq < 47 ) && ($output_freq >= 0) ) ) {
        $returnstring = $returnstring . "!!!CRITICAL FREQUENCE-OUT!!! $output_freq Hz - ";
        $perfdata = $perfdata . "'outfreq'=$output_freq;;;45;55 ";
        $status = 2;
    }
    elsif  ( ($output_freq < 53 ) &&  ($output_freq > 47 ) ) {
        $returnstring = $returnstring . "FREQUENCE-OUT $output_freq Hz - ";
        $perfdata = $perfdata . "'outfreq'=$output_freq;;;45;55 ";
    }
    else {
        $returnstring = $returnstring . "FREQUENCE-OUT UNKNOWN! - ";
        $perfdata = $perfdata . "'outfreq'=NAN ";
        $status = 3 if ( ( $status != 2 ) && ( $status != 1 ) );
    }

    if ( ($input_volt > 240 ) ||  ( ($input_volt < 210 ) && ($input_volt >= 0) ) ) {
        $returnstring = $returnstring . "!!!CRITICAL VOLTAGE-IN!!! $input_volt V - ";
        $perfdata = $perfdata . "'involt'=$input_volt ";
        $status = 2;
    }
    elsif  ( ($input_volt < 240 ) &&  ($input_volt > 210 ) ) {
        $returnstring = $returnstring . "VOLT-IN $input_volt V - ";
        $perfdata = $perfdata . "'involt'=$input_volt ";
    }
    else {
        $returnstring = $returnstring . "VOLT-IN UNKNOWN! - ";
        $perfdata = $perfdata . "'involt'=NAN ";
        $status = 3 if ( ( $status != 2 ) && ( $status != 1 ) );
    }
	
    if ( ($output_volt > 240 ) ||  ( ($output_volt < 210 ) && ($output_volt >= 0) ) ) {
        $returnstring = $returnstring . "!!!CRITICAL VOLT-OUT!!! $output_volt V";
        $perfdata = $perfdata . "'outvolt'=$output_volt ";
        $status = 2;
    }
    elsif  ( ($output_volt < 240 ) &&  ($output_volt > 210 ) ) {
        $returnstring = $returnstring . "VOLT-OUT $output_volt V";
        $perfdata = $perfdata . "'outvolt'=$output_volt ";
    }
    else {
        $returnstring = $returnstring . "VOLT-OUT UNKNOWN!";
        $perfdata = $perfdata . "'outvolt'=NAN ";
        $status = 3 if ( ( $status != 2 ) && ( $status != 1 ) );
    }
	
######## Added by AW / modified by M. Fuchs #############
	if ($battery_replace == 2  ) {
		$returnstring = $returnstring . "!!!BATTERY NEEDS REPLACING!!! - ";
		$status = 2;
	}
	elsif ($battery_replace == 1  ) {
		$returnstring = $returnstring . "BATTERY OK!";
		$status = 0 if ( ( $status != 2 ) && ( $status != 1 ) );
	}
	else {
		$status = 3;
	}

	$returnstring = $returnstring . " UPS Serialnumber: $ups_serial - ";

####################
	
}

####################################################################
# help and usage information                                       #
####################################################################

sub usage {
    print << "USAGE";
-----------------------------------------------------------------	 
$script v$script_version

Monitors APC SmartUPS via SNMP.

Usage: $script -H <hostname> -C <community> [...]

Options: -H 	Hostname or IP address
         -C 	Community (default is public)
         -T 	Warning Temperature
	 
-----------------------------------------------------------------	 
Copyright 2004 Altinity Limited
Modified 03.2010 by Blueeye	 
	 
This program is free software; you can redistribute it or modify
it under the terms of the GNU General Public License
-----------------------------------------------------------------

USAGE
     exit 1;
}
