package Dir::ListFilesRecursive; ## Static functions to find files in directories.


our $VERSION='0.04';


use strict;
use Carp;
use vars qw(@ISA @EXPORT %EXPORT_TAGS $VERSION);
use Exporter; 
use File::Spec::Functions;
 
 
@ISA = qw(Exporter);

%EXPORT_TAGS = ( all => [qw(
                      list_files_flat
                      list_files_recursive
                      list_files_no_path
                )] ); 

Exporter::export_ok_tags('all'); 


# This class provides static functions which can be imported to the namespace of 
# the current class. The functions lists the content of directories.
#
# With options you can filter the files for specific criteria, like no hidden files, etc.
#
# SYNOPSIS
# ========
# 
#  # imports all functions
#  use Dir::ListFilesRecursive ':all';
#
#  # imports only one function
#  use Dir::ListFilesRecursive qw( list_files_recursive );
#
#  use Data::Dumper;
#  print Dumper( list_files_recursive('/etc') );
#
#  use Data::Dumper;
#  print Dumper( list_files_recursive('/etc', only_folders => 1) );
#  # shows only subfolders of /etc
#
# 
# Options
# =======
#
# For some functions, you can set options like the only_folders in the SYNOPSIS's example.
# You can use the following options:
# As options you can set these flags:
#
#  only_folders    => 1,
#  only_files      => 1,
#  no_directories  => 1,
#  no_folders      => 1,
#  no_hidden_files => 1,
#  extension       => 'string',
#  no_path         => 1,
#
# You can also use various aliases:
#
# only_folders:
# only_folder, only_dir, only_dirs, only_directories, no_files
#
# no_directories:
# no_dir, no_dirs, no_folder, no_folders
#
# no_hidden_files:
# no_hidden
#
# extension:
# ext
#
# Not implemented so far: regular expression match, file age and other attributes.
# 
#
#
# LICENSE
# =======   
# You can redistribute it and/or modify it under the conditions of LGPL.
# 
# AUTHOR
# ======
# Andreas Hernitscheck  ahernit(AT)cpan.org






# List the files of a directory with full path.
#
#  print list_files_flat('/etc');
#  # may return files like:
#  # /etc/hosts
#  # /etc/passwd
#
# It does not return directory names. (that means 'flat'),
# only the files of given directory, no content of subfolders.
#
# You can set key value pairs to use further options.
# Please see chapter 'options'.
#
# It returns an array or arrayref, depending on context.
#
sub list_files_flat{ # array|arrayref ($path,%options)
    my $path  = shift or croak "needs path";;
    my %param = @_;
    my @files;
    
    # extend params
    my $param2 = _complete_params( \%param );
    $param2->{'path'} = $path;
    @files = grep { _does_filter_match_file( $_ , $param2 ) } _scan_dir( $path );

    if ( ! $param{'no_path'} ){
        _add_path_to_array( $path, \@files );
    }


    return wantarray ? @files : \@files;
}










# List the files of a directory and subdirctories 
# with full path.
#
#  print list_files_recursive('/etc');
#  # may return files like:
#  # /etc/hosts
#  # /etc/passwd
#  # /etc/apache/httpd.conf
#
# You can set key value pairs to use further options.
# Please see chapter 'options'.
#
# It returns an array or arrayref, depending on context.
#
sub list_files_recursive {  # array|arrayref ($path,%options)
    my $path = shift or croak "needs path";
    my %param = @_;
    my @files;

    # extend params
    my $param2 = _complete_params( \%param );
    # $paths for _does_filter_match_file() not needed because list is with paths
    @files = grep { _does_filter_match_file( $_ , $param2 ) } _list_files_recursive_nofilter( $path );

    if ( $param{'no_path'} ){
        _sub_path_from_array( $path, \@files );
    }

    return wantarray ? @files : \@files;
}


sub _list_files_recursive_nofilter {  # array|arrayref ($path)
    my $path = shift or croak "needs path";;
    my @files;
    my @filesm;

    @files = _scan_dir( $path );

    ## remove . and ..
    @files = grep { $_ ne '.' and $_ ne '..' } @files; 

    _add_path_to_array( $path, \@files );


    # step down a directory
    foreach my $d ( @files ){
        if ( -d $d ){
          push @filesm, _list_files_recursive_nofilter( $d ); # self call - recursive
        }
    }
    push @files, @filesm;

    return @files;
}








# List the files of a directory without the path.
#
#  print list_files_no_path('/etc');
#  # may return files like:
#  # hosts
#  # passwd
#
#  Furher subpaths will be returned like /etc/apache.
#
# You can set key value pairs to use further options.
# Please see chapter 'options'.
#
# It returns an array or arrayref, depending on context.
sub list_files_no_path{ # array|arrayref ($path,%options)
    my $path = shift or croak "needs path";;
    my %param = @_;
    my @files;
    my @nf;

    @files = list_files_recursive( $path, %param );
   
    foreach my $z (@files){
      _sub_path_from_file( $path, \$z );
    }
    
    
      
    return wantarray ? @files : \@files;
}



# scanns a dir simple and flat
sub _scan_dir {
    my $path = shift or croak "needs path";
    my @files;
    
    opendir( FDIR, $path );
    @files = readdir FDIR; ;
    closedir( FDIR );

    # remove . and ..
    if ($files[0] =~ m/^\.\.?$/ ){ shift @files };
    if ($files[0] =~ m/^\.\.?$/ ){ shift @files };

    
    return wantarray ? @files : \@files;
}




sub _complete_params {
    my $p1 = shift;
    my $p2 = {};  
    
    # copy params
    %{ $p2 } = %{ $p1 };

    if ($p1->{only_folder})       {$p2->{no_files}=1};
    if ($p1->{only_folders})      {$p2->{no_files}=1};
    if ($p1->{only_dir})          {$p2->{no_files}=1};
    if ($p1->{only_dirs})         {$p2->{no_files}=1};
    if ($p1->{only_directories})  {$p2->{no_files}=1};

    if ($p1->{only_files})        {$p2->{no_dir}=1};

    return $p2;
}



sub _does_filter_match_file{
    my $f     = shift;
    my $param = shift;
    my @nf;
    my $path  = $param->{path};  
    my $ok = 1;
    
    $param->{no_files} //= '';
    
    my $chkf_d;
    
    if ( $path ){
        $chkf_d = -d catfile($path,$f);
    }else{
        $chkf_d = -d $f;
    }
    
    
    if (($param->{no_files} ne '') && ( ! $chkf_d )){
        #$ok = 0;
        return 0;
    };

    if ( $chkf_d ){

        if ($param->{no_dir})        { return 0 };
        if ($param->{no_dirs})       { return 0 };
        if ($param->{no_directories}){ return 0 };
        if ($param->{no_folder})     { return 0 };
        if ($param->{no_folders})    { return 0 };   

        if ( !$ok ){
            return 0;
        }
        
        
    }

    
    
    if ( ( ($param->{no_hidden}) || ($param->{no_hidden_files}) ) 
            && ( index($f,'.') == 0 )
        ){
            return 0;
        };
    

    if ( exists $param->{ext} ){
      my $ext = lc($param->{ext}) || lc($param->{extension});
      if ( $f=~ m/\.$ext$/i ){ $ok=1 }else{ $ok=0 };
    }

    return $ok;
}









# helper method to add the path to the found files.
sub _add_path_to_array{
  my $path=shift;
  my $dir_ref=shift;

    foreach my $z (@$dir_ref){
      $z=catfile($path,$z);
    }
}


# helper method to remove path from found files
sub _sub_path_from_array{
  my $path=shift;
  my $dir_ref=shift;

  my $slash = catdir('','');
  
    foreach my $z (@$dir_ref){
      _sub_path_from_file( $path, \$z );
    }
}


sub _sub_path_from_file{
  my $path=shift or croak "needs path";
  my $file_ref=shift or croak "needs fileref";

  my $slash = catdir('','');
  
  $$file_ref =~ s/^\Q$path\E[\Q$slash\E]?//;
  
}





1;
#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Dir::ListFilesRecursive - Static functions to find files in directories.


=head1 SYNOPSIS


 # imports all functions
 use Dir::ListFilesRecursive ':all';

 # imports only one function
 use Dir::ListFilesRecursive qw( list_files_recursive );

 use Data::Dumper;
 print Dumper( list_files_recursive('/etc') );

 use Data::Dumper;
 print Dumper( list_files_recursive('/etc', only_folders => 1) );
 # shows only subfolders of /etc




=head1 DESCRIPTION

This class provides static functions which can be imported to the namespace of 
the current class. The functions lists the content of directories.

With options you can filter the files for specific criteria, like no hidden files, etc.



=head1 REQUIRES

L<Exporter> 


=head1 METHODS

=head2 list_files_flat

 my @array | \@arrayref = list_files_flat($path, %options);

List the files of a directory with full path.

 print list_files_flat('/etc');
 # may return files like:
 # /etc/hosts
 # /etc/passwd

It does not return directory names. (that means 'flat'),
only the files of given directory.

You can set key value pairs to use further options.
Please see chapter 'options'.

It returns an array or arrayref, depending on context.



=head2 list_files_no_path

 my @array | \@arrayref = list_files_no_path($path, %options);

List the files of a directory without the path.

 print list_files_no_path('/etc');
 # may return files like:
 # hosts
 # passwd

It does not return directory names.

You can set key value pairs to use further options.
Please see chapter 'options'.

It returns an array or arrayref, depending on context.


=head2 list_files_recursive

 my @array | \@arrayref = list_files_recursive($path, %options);

List the files of a directory and subdirctories
with full path.

 print list_files_recursive('/etc');
 # may return files like:
 # /etc/hosts
 # /etc/passwd
 # /etc/apache/httpd.conf

You can set key value pairs to use further options.
Please see chapter 'options'.

It returns an array or arrayref, depending on context.




=head1 Options


For some functions, you can set options like the only_folders in the SYNOPSIS's example.
You can use the following options:
As options you can set these flags:

 only_folders    => 1,
 only_files      => 1,
 no_directories  => 1,
 no_folders      => 1,
 no_hidden_files => 1,
 extension       => 'string',
 no_path         => 1,

You can also use various aliases:

only_folders:
only_folder, only_dir, only_dirs, only_directories, no_files

no_directories:
no_dir, no_dirs, no_folder, no_folders

no_hidden_files:
no_hidden

extension:
ext

Not implemented so far: regular expression match, file age and other attributes.





=head1 AUTHOR

Andreas Hernitscheck  ahernit(AT)cpan.org


=head1 LICENSE

You can redistribute it and/or modify it under the conditions of LGPL.



=cut
