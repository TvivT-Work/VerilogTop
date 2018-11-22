#!/usr/bin/perl -w
# use strict;
 
use utf8;
use POSIX;
use List::Util qw/max min/;

$os = $^O;
$user_name = ($os =~ /MSWin32/) ? $ENV{'USERNAME'} :
             ($os =~ /linux/  ) ? $ENV{'USER'}     : "Unknow" ;
  
#1. arguments checker
#=========================== Arguments Checker ===============================
$argv_total_num = $#ARGV + 1;

if( $argv_total_num == 0 ) {
    disp_usage();
    die "ERROR: NO Arguments !!! \n\n";
} elsif( $argv_total_num < 3 ) {
    disp_usage();
    die "ERROR: Arguments Error !!! \n\n";
}

#=========================== Get File List ===============================
@vfiles = ();
if($ARGV[1] =~ /\-d/) {
  $ARGV[2] =~ s/\\/\\\\/g;
  @vfiles = vdir_read($ARGV[2]);
}
elsif($ARGV[1] =~/\-l/) {
  open (filelist_handle,"<",$ARGV[2]);
  @file_list=<filelist_handle>;
  foreach my $vfile(@file_list){
    chomp($vfile);

    # Replace Space
    $vfile =~ s/\s//g;

    # Replace Comment 
    $vfile =~ s/\/\/[\s\S]*//g;

    # Skip empty lines
    if ($vfile =~ /^\s*$/) {
      next;
    }

    $vfile =~ s/\\/\\\\/g;
    push (@vfiles, $vfile);
  }
}
elsif($ARGV[1] =~/\-f/) {
  for my $argv_num (2..$#ARGV){
    push (@vfiles, $ARGV[$argv_num]);
  }
}
else {
    disp_usage();
    die "ERROR: Error Arguments !!! \n\n";
}
print(" Read Vfiles: @vfiles");
#=========================================================================
@net_array = ();

#=========================================================================
$top_name = $ARGV[0] ;

$module_line = "`timescale 1ns/10ps \n\n";
push(@module_lines, $module_line);
$module_line = "module $top_name( \n";
push(@module_lines, $module_line);
$declare_line = "\n\n//============================= DECLARE ===========================\n";
push(@declare_lines, $declare_line);
$instance_line = "\n\n//============================= INSTANCE ==========================\n";
push(@instance_lines, $instance_line);

#=========================================================================
foreach $vfile(@vfiles){
  open (file_handle,"<", $vfile);

  @line_list=<file_handle>;

  my $module_flag = 0;

  foreach my $current_line(@line_list){
 
    # Replace Comment 
    $current_line =~ s/\/\/[\s\S]*//g;

    # Replace ,()
    $current_line =~ s/[,()]//g;

    # Replace Head/Tail Space
    $current_line =~ s/^\s+|\s+$//g;

    # Replace [] Space

    # Skip empty lines
    if ($current_line =~ /^\s*$/) {
      next;
    }

    if( $current_line =~ /endmodule/ ) {
      $instance_line = $module_name."    u_".$module_name."(\n";
      push(@instance_lines, $instance_line);

      for my $port_num (0..$#module_ports) {
        $port_name = $module_ports[$port_num];

        $bit_len = $net_hash{$port_name};
        if ($bit_len == 0) {
          $bit_len_str = " ";
        }
        else {
          $bit_len_str = "[$bit_len:0] ";
        }

        $instance_line  = " " x 28;
        $instance_line .= ".";
        $instance_line .= $port_name;
        $instance_line .= " " x (28-length($port_name));
        $instance_line .= "( ";
        $instance_line .= $port_name;
        $instance_line .= $bit_len_str;
        $instance_line .= " " x (34-length($port_name)-length($bit_len_str));
        $instance_line .= " )";
        if($port_num == $#module_ports) {
          $instance_line .= " );\n\n\n";
        }
        else {
          $instance_line .= ",\n";
        }
        push(@instance_lines, $instance_line);
      }

    }

    if( $current_line =~ /module / ) {
      $module_flag  = 1 ;
      @module_ports = ();

      @line_words = split(/\s+/, $current_line);
      $module_name = $line_words[1];

      next;
    }

    if( $current_line =~ /;/ ) {
      $module_flag = 0;
    }

    if($module_flag) {
      $bit_len = 0 ;

      $current_line =~ s/\[[\s\S]+?\]//g;
      $bit_len_str = $&;
      $bit_len_str =~ s/[\s\[\]]//g;
      if($bit_len_str =~ /:/){
        $bit_len = $` ;
      }
      else{
        $bit_len = 0 ;
      }
      @line_words = split(/\s+/, $current_line);
      $port_name = $line_words[2];
      if( exists($net_hash{$port_name}) ) {
        $bit_len_org = $net_hash{$port_name};
        if($bit_len != $bit_len_org) {
          print "[ERROR] $port_name mismatch bits length!";
          chomp (my $wait_input=<STDIN>);
        }
      }
      else {
        $net_hash{$port_name} = $bit_len ;
        push(@net_array, $port_name);
      }
      push(@module_ports, $port_name);
    }

  }

}

#=========================================================================
$net_max_num  = keys %net_hash; 

$net_num = 0;
foreach my $net_name (@net_array) {
  $net_num = $net_num + 1; 

  $bit_len = $net_hash{$net_name};

  if ($bit_len == 0) {
    $bit_len_str = " ";
  }
  else {
    $bit_len_str = "[$bit_len:0] ";
  }

  $module_line = "    input  wire    ";
  $module_line .= $bit_len_str;
  $module_line .= " " x (10-length($bit_len_str));
  $module_line .= $net_name;
  $module_line .= " " x (28-length($net_name));
  if($net_num == $net_max_num) {
    $module_line .= "  \n\n);\n\n\n";
  }
  else {
    $module_line .= " ,\n";
  }
  push(@module_lines, $module_line);

  if($bit_len>0) {
    $declare_line  = "wire    ";
    $declare_line .= $bit_len_str;
    $declare_line .= " " x (10-length($bit_len_str));
    $declare_line .= $net_name;
    $declare_line .= " " x (28-length($net_name));
    if($net_num == $net_max_num) {
      $declare_line .= " ;\n\n\n";
    }
    else {
      $declare_line .= " ;\n";
    }
    push(@declare_lines, $declare_line);
  }

}

#=========================================================================
@vtop_lines = ();
push (@vtop_lines, @module_lines);
push (@vtop_lines, @declare_lines);
push (@vtop_lines, @instance_lines);
$line = "\n\n\nendmodule\n";
push (@vtop_lines, $line);

#=========================================================================
if($user_name eq "jianghe") {
  $vtop_file = "D:\\Desktop\\Perl_Result\\".$ARGV[0].".v";
}
else {
  $vtop_file = $ARGV[0].".v";
}

$vtop_file_exist = -e $vtop_file;

if ( $vtop_file_exist ) {
  print "\n $vtop_file Exist, OverWrite it ? <y/n> (Default No OverWrite): ";
  chomp (my $key_input=<STDIN>);

  if($key_input eq "y") {
    print"\n -------- $vtop_file OverWrite !!! -------- \n\n";
    $vtop_file_gen = 1; 
  }
  else {
    print"\n -------- $vtop_file No Change !!! -------- \n\n";
    $vtop_file_gen = 0;
  }
}
else {
  $vtop_file_gen = 1 ;
}

if($vtop_file_gen) {
  open (write_file,">", $vtop_file);
  print write_file @vtop_lines;
  close write_file;
  print "\n Success: ${top_name}.v Generated !!! \n\n";
}

#=========================================================================
sub disp_usage {
    print "\n";
    print "==================================================\n";
    print "  Usage: vtop   top_name  -d input_dir/     \n";
    print "         vtop   top_name  -f input_file1.v   input_file2.v ... \n";
    print "         vtop   top_name  -l input_filelist \n";
    print "==================================================\n";
    print "\n";
}


sub vdir_read {

  my $path = $_[0]; #或者使用 my($path) = @_; @_类似javascript中的arguments
  my $subpath;
  my $handle; 

  if ($path =~ /\\$/) {
  }
  else {
    $path .= "\\" ;
  }

  if (-d $path) {#当前路径是否为一个目录
    if (opendir($handle, $path)) {
      while ($subpath = readdir($handle)) {
        if (!($subpath =~ m/^\.$/) and !($subpath =~ m/^(\.\.)$/)) {
          my $dir_file = $path."/$subpath"; 
 
          if (-d $dir_file) {
            get_dir_vfiles($dir_file);
          } else {
            ++$filecount;
            if($dir_file =~ /\.v$|\.sv$/) {
              ++$vfilecount;
              push (@dir_files, $dir_file);
              # print $p."\n";
            }
          }
        }                
      }
      closedir($handle);            
    }
  } 
 
  return @dir_files;



  # $dir_path = $_[0];

  # if ($dir_path =~ /\\$/) {
  # }
  # else {
  #   $dir_path .= "\\" ;
  # }

  # opendir (DIR, $dir_path) || die"$!";
  # # chdir($dir_path);
  
  # @vfilenames=grep{/\.v$|\.sv$/}readdir DIR;
  
  # foreach $filename(@vfilenames){
  #   $vfile = $dir_path.$filename; 
  #   push (@vfiles, $vfile);
  # }
  
  # close DIR;

  # return @vfiles;

}
