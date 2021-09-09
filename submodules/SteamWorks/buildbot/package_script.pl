# Pastebin eziGmKtQ
#!/usr/bin/perl

use strict;
use Cwd;
use File::Basename;
use File::Copy;
use File::Path;
use Net::FTP;

my ($ftp_file, $ftp_host, $ftp_user, $ftp_pass, $ftp_path, $tag);

$ftp_file = shift;
$tag = shift;

open(FTP, $ftp_file) or die "Unable to read FTP config file $ftp_file: $!\n";
$ftp_host = <FTP>;
$ftp_user = <FTP>;
$ftp_pass = <FTP>;
$ftp_path = <FTP>;
close(FTP);

chomp $ftp_host;
chomp $ftp_user;
chomp $ftp_pass;
chomp $ftp_path;

my ($myself, $path) = fileparse($0);
chdir($path);

require 'helpers.pm';

my ($version, $ext);
$version .= '-git' . Build::GitRevNum('.');

# Append OS to package version
if ($^O eq "darwin")
{
    $ext = ".dylib";
    $version .= '-mac';
}
elsif ($^O =~ /MSWin/)
{
    $ext = ".dll";
    $version .= '-windows';
}
elsif ($^O eq "linux")
{
    $ext = ".so";
    $version .= '-linux';
}
else
{
    $version .= '-' . $^O;
}

#Switch to the output folder.
chdir(Build::PathFormat('../build/package'));

my ($dirlist, $filename, $cmd);
$dirlist = "addons";
$filename = 'SteamWorks' . $version;

if ($^O eq "linux")
{
    $filename .= '.tar.gz';
	$cmd = "tar zcvf $filename $dirlist";
}
else
{
    $filename .= '.zip';
	$cmd = "zip -r $filename $dirlist";
}

print "$cmd\n";
system($cmd);

$ftp_path .= "/SteamWorks";

my ($ftp);

$ftp = Net::FTP->new($ftp_host, Debug => 0, Passive => 1) 
    or die "Cannot connect to host $ftp_host: $@";

$ftp->login($ftp_user, $ftp_pass)
    or die "Cannot connect to host $ftp_host as $ftp_user: " . $ftp->message . "\n";

if ($ftp_path ne '')
{
	# YOU LEAVE ME NO CHOICE
	$ftp->mkdir($ftp_path, 1);
	
    $ftp->cwd($ftp_path)
        or die "Cannot change to folder $ftp_path: " . $ftp->message . "\n";
}

$ftp->binary();
$ftp->put($filename)
    or die "Cannot drop file $filename ($ftp_path): " . $ftp->message . "\n";

$ftp->close();

print "File sent to drop site as $filename -- build succeeded.\n";

exit(0);

