#!/usr/bin/perl

use POSIX;
use strict;
use warnings;
use File::Find;
use File::stat;
use LWP::UserAgent;
use HTTP::Request;

# Initialize content as an empty string
my $content = '';

# Function to find files based on certain criteria
sub findfiles {
	# Prune directories based on their paths or names
	$File::Find::prune = 1 if /sendfin/;
	$File::Find::prune = 1 if /recv/;
	$File::Find::prune = 1 if $File::Find::name =~ m[\/org\/corp\/send];
	$File::Find::prune = 1 if $File::Find::name =~ m[\/bizunit01\/fulfill\/send];
	
	my $root = "/home/choyinoom/";

	my $now = time();
	my $curr_date = strftime "%D", localtime();
	
	if (-f and (/\.txt$/ or /\.dat$/) ) {
		my $file_name = $File::Find::name;
		my $mtime = stat($root.$file_name)->mtime;
		my $file_date = strftime "%D", localtime($mtime);

		if (($file_date eq $curr_date) and ($now - $mtime > 3600) and (&skiplist($file_name)) == 0) {
			$content .= sprintf("%s | %s", substr($file_name, length('this/is/nas')), POSIX::strftime('%H:%M:%S', localtime($mtime)));
			$content .= '\n';
		}
	}
}

# Function to check if a file should be skipped
sub skiplist {
	my $curr_hour = int(strftime "%H", localtime());
	my $weekday = int(strftime "%u", localtime());
	
	if(
		$_[0] =~ m[XYA023_FILE_8847] ||
        ($_[0] =~ m[8B2C9_RTC.7H2_MOB] and $curr_hour < 4) ||
        ($_[0] =~ m[3K8-3K847S18-01] and $curr_hour < 12) ||
        ($_[0] =~ m[FILE_NAME_6] and $curr_hour < 15) ||
        ($_[0] =~ m[FILE_NAME_7] and $curr_hour < 16) ||
        ($_[0] =~ m[FILE_NAME_9] and $weekday > 5) 
	) {
		return 1; # Skip
	}
	return 0; # Don't skip
}

# Find files in the specified directory 'this/is/nas'
find({ wanted => \&findfiles, }, 'this/is/nas');

if(length($content) > 0) {
	my $ua = LWP::UserAgent->new;
	my $url = "http://my-custom-alarm.com/call";
	my $request = HTTP::Request->new(POST => $url);
	$request->header('content-type' => 'application/json');
	my $data = '{"userName":"choyinoom", "notiTitle":"File checklist from 10.1.49.2", "notiContent":"';
	$data .= $content;
	$data .= '"}';

	# Send the request
	$request->content($data);
	my $resp = $ua->request($request);
	
	# Print the request data for debugging;
	print $data;
}

exit;