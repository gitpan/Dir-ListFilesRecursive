#!/usr/bin/perl


use lib '../lib','lib';

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use Dir::ListFilesRecursive ':all';
use File::Touch;
use Hash::Work qw(:all);
# use Data::Dumper;

use Test::More tests => 8;

my $tmp = "/tmp/listfiles-test-$$";
#$tmp = "/tmp/listfiles/";
my $s = "$tmp/a/b/c";
my $b = "$tmp/a/b/c";


 
if ( -e $b ){ rmtree($b) };

mkpath($s) or die "Was not able to create path $s";

foreach my $f (80..90){

  touch("$s/file-$f.txt");

  mkpath("$s/folder-$f");

  foreach my $t (10..20){
    touch("$s/folder-$f/file-$f-$t.txt");
  }

}

# use Data::Dumper;
# 
#  print Dumper( list_files_flat($b) );
# # 
#  print Dumper( list_files_no_path($b) );
# # 
#  print Dumper( list_files_recursive($b) );

my $h_flat = array_to_hash( list_files_flat($b) );
my $h_nopath = array_to_hash( list_files_no_path($b) );
my $h_recu = array_to_hash( list_files_recursive($b) );

ok( exists( $h_flat->{"$tmp/a/b/c/file-87.txt"} ), 'list_files_flat positive' );
ok( ! exists( $h_flat->{"$tmp/a/b/c/folder-89/file-89-17.txt"} ), 'list_files_flat negative' );


ok( exists( $h_nopath->{"folder-88"} ), 'list_files_no_path positive' );
ok( exists( $h_nopath->{"file-89.txt"} ), 'list_files_no_path positive' );
ok( ! exists( $h_nopath->{"$tmp/folder-80/file-80-12.txt"} ), 'list_files_no_path negative' );

ok( exists( $h_recu->{"$tmp/a/b/c/folder-89/file-89-17.txt"} ), 'list_files_recursive positive' );
ok( exists( $h_recu->{"$tmp/a/b/c/folder-90"} ), 'list_files_recursive positive' );
ok( ! exists( $h_recu->{'file-89.txt'} ), 'list_files_recursive negative' );

