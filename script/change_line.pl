#!/usr/bin/perl

#die ("Add Comment to this line after fixing internal variables.");

# ./script/util/change_line.pl  /web/gilt/app
# ./script/util/change_line.pl  /web/gilt/lib

$basedir = shift(@ARGV) || die("Specify base dir with the full path\n\n");
$basedir =~ s!/$!!;

my %changeHash = ('2.11.6' => '2.11.7');

my $find_only = shift(ARGV) || 0;

my @fileTypes = ('.rb', '.erb', '.js', '.html', '.scala', '.yml', 'routes', '.txt', '.json', '.sbt');

my ($map,$dirList) = readDir($basedir);
@dirs = @$dirList;

$cnt=0;
foreach $dir (sort(@dirs)) {
    chdir "$basedir" || die "Can't change into $basedir";
    if (-d $dir) {
        chdir "$dir";
        print "Now parsing $dir\n";
    } else {
        print "  Cannot change into $dir\n";
        next;
    }
    my $tmpHandle = $/;
    undef $/;
    opendir(DIR,".");
    while ($file = readdir(DIR)) {
        my $flag=0;
        next if ($file =~ /^\#/ || $file =~ /^\./ || $file =~ /\~$/);
        next if (-d $file);
        next unless isWritable($file);

        my $skip = 1;
        foreach (@fileTypes) {
            if ($file =~ m/$_$/) {
                $skip=0;
                last;
            }
        }
        next if $skip;
        $temp = $file . ".tmp";
        open (FILE, "$file") || next;
        my $fileContents = <FILE>;
        while (($old,$new) = each(%changeHash)) {
            if ($fileContents =~ /\Q$old\E/s) {
                $fileContents =~ s!\Q$old\E!$new!gs;
                if (! $flag) {
                    print "  Modified $file...\n";
                    push @{$modified{$dir}}, $file;
                    $flag=1;
                    $cnt++;
                }
            }
        }
        close(FILE);
        # Only rewrite the file if specified
        if ($find_only) {
            next;
        }
        if ($flag || $file =~ /\.cfm$/) {
            open (TEMP, ">$temp");
            print TEMP $fileContents;
            close(TEMP);
            unlink ("$file");
            if ($file =~ /\.cfm$/) {
                $file =~ s/\.cfm$/\.adp/;
            }
            rename ("$temp","$file") || die("Can't rename $temp to $file\n");
        } else {
            unlink($temp);
        }
        print "\n" if $flag;
    }
    $/ = $tmpHandle;
}
closedir(DIR);
print "\n". "-"x50 ."\n";
if (keys(%modified) > 0) {
    print "\nList of Modified Files:\n";
    while (($dir,$fileList) = each(%modified)) {
        print "  $dir\n";
        foreach (@$fileList) {
            print "    $_\n";
        }
    }
}

print "\n$cnt Files modified\n\n";



#-------------------------------------------------------------
# Function: readDir
# Arguments: Dirctory name (from current directory) at which to start
#               looking for files
#            Base Directory by which to reference all files (dir names
#               will not contain this portion of the path. Default is
#               current directory)
#            Integer: 1 to recurse, 0 to get files in 1 directory
#               (Default is 1)
# Return Value: reference to hash of <dir>->[file list]
#               reference to array of all dirs
# Description: Reads directory files (recursively if integer set
#              to 1) into a hash of <dirPath>->[list of file]
#              where <dirPath> is relative to Base Directory
#
# Ex: ($map,$list) = readDir('tcio_bridge','/cadm/designs/p880sys');
#     ($map,$list) = readDir('/cadm/designs/p880bin/tcio_bridge/');
#-------------------------------------------------------------
sub readDir {
    my ($dir,$rootDir,$recurse,$mapRef,$listRef) = @_;
    $recurse = 1 unless ($recurse eq "0");
    unless ($mapRef) {
        my (%readdir_hash,@readdir_array);
        $mapRef ||= \%readdir_hash;
        $listRef ||= \@readdir_array
    }
    my ($cwd) = ($rootDir ne "") ? "$rootDir/$dir" : $dir;
    my ($testFile);
    if (-l $cwd) {
        print "Skipping link: $dir\n";
        return ($mapRef,$listRef);
    }
    chdir($cwd);
    push (@$listRef, $dir);
    my ($file,@fileList);
    opendir(DIR,".");
    @fileList = readdir(DIR);
    closedir(DIR);
    foreach $file (@fileList) {
        next if ($file =~ /~$/ || $file eq "." || $file eq "..");
	if ($file eq ".git") {
	    print "Skipping .git dir\n";
	    next;
	}
        $testFile = $cwd.'/'.$file;
        if (-d $testFile) {
            if ($recurse) {
                readDir("$dir/$file",$rootDir,$recurse,$mapRef,$listRef);
                chdir("../");
            }
        } elsif ( (-e $testFile) || (-l $testFile) ) {
            push @{$mapRef->{$dir}}, $file;
        } else {
            print STDERR "Warning: Skipping file: $cwd/$file\n";
        }
    }
    return ($mapRef,$listRef);
}

sub isWritable {
    my $file = shift(@_);
    my $ls = `ls -l "$file"`;
    # Match the string... drop the first character
    $ls =~ m!^[^ ]([^ ]+)!;
    return ($ls =~ /w/i);
}
