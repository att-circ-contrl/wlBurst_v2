#!/usr/bin/perl

#
# Includes

use strict;
use warnings;



#
# Documentation

my ($help_screen);
$help_screen = << 'Endofblock';

Usage:  copy-code.pl (options) (input files)

This program copies code from the specified input files and produces LaTeX
documentation output.

The following options are recognized:

"--help" prints this information.
"--outfile=(name)" specifies the file to write to.
"--chapter=(string)" uses a chapter with the specified name as the top level.
"--section=(string)" uses a section with the specified name as the top level.
"--label=(string)" specifies the LaTeX crossreference label for the top level.
"--matlabdoc" copies the documentation comment blocks from matlab functions.
"--verbatim" copies entire source files.
"--nosort" suppresses sorting and copies files in the order they're provided.

Anything not beginning with "--" is assumed to be a filename.

Endofblock


#
# Functions

# Processes command-line arguments.
# No arguments.
# Returns ( $options_p, $flist_p ); an options hash and a filename list.

sub ProcessArgs
{
  my ($options_p, $flist_p);
  my ($aidx, $thisarg);
  my ($need_help);

  $options_p = { 'action' => 'help',
    'outfile' => '/dev/null', 'toplevel' => 'chapter',
    'title' => 'Undefined Title', 'label' => undef,
    'wantsort' => 1 };
  $flist_p = [];

  $need_help = 0;

  for ($aidx = 0; defined ($thisarg = $ARGV[$aidx]); $aidx++)
  {
    if ('--help' eq $thisarg)
    {
      $$options_p{'action'} = 'help';
    }
    elsif ('--matlabdoc' eq $thisarg)
    {
      $$options_p{'action'} = 'matlab';
    }
    elsif ('--verbatim' eq $thisarg)
    {
      $$options_p{'action'} = 'verbatim';
    }
    elsif ('--nosort' eq $thisarg)
    {
      $$options_p{'wantsort'} = 0;
    }
    elsif ($thisarg =~ m/^--outfile=(.*\S)/)
    {
      $$options_p{'outfile'} = $1;
    }
    elsif ($thisarg =~ m/^--chapter=(.*\S)/)
    {
      $$options_p{'title'} = $1;
      $$options_p{'toplevel'} = 'chapter';
    }
    elsif ($thisarg =~ m/^--section=(.*\S)/)
    {
      $$options_p{'title'} = $1;
      $$options_p{'toplevel'} = 'section';
    }
    elsif ($thisarg =~ m/^--label=(\S+)/)
    {
      $$options_p{'label'} = $1;
    }
    elsif ($thisarg =~ m/^--/)
    {
      print STDERR "###  Unrecognized option \"$thisarg\".\n";
      $need_help = 1;
    }
    else
    {
      # Assume this is a filename.
      push @$flist_p, $thisarg;
    }
  }

  if ($need_help)
  {
    $$options_p{'action'} = 'help';
  }

  return ($options_p, $flist_p);
}


# Processes a single input file.
# Arg 0 is the name of the file to process.
# Arg 1 is the processing operation to perform.
# Returns a string containing the processed file body.

sub ProcessFile
{
  my ($fname, $operation, $result);
  my ($thisline, @filedata);
  my ($foundstart, $foundstop);

  $fname = $_[0];
  $operation = $_[1];
  $result = '';

  if (!open(INFILE, "<$fname"))
  {
    print STDERR "###  Unable to read from \"$fname\".\n";
  }
  else
  {
    @filedata = <INFILE>;
    close(INFILE);

    if ('verbatim' eq $operation)
    {
      # Copy everything, inside a verbatim block.
      # We can actually just use the "verbatiminput" macro for this.
      $result = '\verbatiminput{' . $fname . '}'."\n";
    }
    elsif ('matlab' eq $operation)
    {
      # Copy the initial comment block only.
      $result = '\begin{verbatim}'."\n";

      $foundstart = 0;
      $foundstop = 0;
      foreach $thisline (@filedata)
      {
        if (!$foundstart)
        {
          if ($thisline =~ m/^%/)
          {
            $foundstart = 1;
            $result .= $thisline;
          }
        }
        elsif (!$foundstop)
        {
          if ($thisline =~ m/^%/)
          {
            $result .= $thisline;
          }
          else
          {
            $foundstop = 1;
          }
        }
      }

      $result .= '\end{verbatim}'."\n";
    }
  }

  return $result;
}


#
# Main Program

my ($options_p, $flist_p);

( $options_p, $flist_p ) = ProcessArgs();

if ( 'help' eq $$options_p{'action'} )
{
  print $help_screen;
}
elsif (!open(OUTFILE, '>'.$$options_p{'outfile'}))
{
  print STDERR '###  Unable to write to "' . $$options_p{'outfile'} . "\".\n";
}
else
{
  my ($topsection, $subsection);
  my ($toplabel);
  my ($fidx, $thisfile, $barename, %fname_lut, %barename_lut);

  $topsection = '\chapter';
  $subsection = '\section';
  if ('section' eq $$options_p{'toplevel'})
  {
    $topsection = '\section';
    $subsection = '\subsection';
  }

  print OUTFILE '% Automatically generated documentation.'."\n";
  print OUTFILE $topsection . '{' . $$options_p{'title'} . '}'."\n";
  $toplabel = $$options_p{'label'};
  if (defined $toplabel)
  {
    print OUTFILE '\label{' . $toplabel . '}'."\n";
  }


  %fname_lut = ();
  %barename_lut = ();
  for ($fidx = 0; defined ($thisfile = $$flist_p[$fidx]); $fidx++)
  {
    $barename = $thisfile;
    if ($thisfile =~ m/.*\/(.*\S)/)
    { $barename = $1; }
    $barename =~ s/[^a-zA-Z0-9.]/\\_/g;

    # FIXME - Blithely assume that there are no duplicate bare-filenames!
    if (defined $fname_lut{$barename})
    {
      print STDERR "### Duplicate filename found: \"$barename\".\n";
    }
    $fname_lut{$barename} = $thisfile;
    $barename_lut{$thisfile} = $barename;
  }


  if ($$options_p{'wantsort'})
  {
    foreach $barename (sort keys %fname_lut)
    {
      print OUTFILE "\n" . $subsection . '{' . $barename . '}'."\n\n";
      print OUTFILE ProcessFile($fname_lut{$barename}, $$options_p{'action'});
    }
  }
  else
  {
    foreach $thisfile (@$flist_p)
    {
      print OUTFILE "\n" . $subsection . '{' . $barename_lut{$thisfile}
        . '}'."\n\n";
      print OUTFILE ProcessFile($thisfile, $$options_p{'action'});
    }
  }

  print OUTFILE "\n".'% This is the end of the file.'."\n";

  close(OUTFILE);
}


#
# This is the end of the file.
