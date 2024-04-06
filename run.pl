use strict;
use Getopt::Long;

# build by default
my $build = 1;
# use gnuplot plottting backend by default
my $backend = "gnuplot";

GetOptions(
           "debug" => \my $debug,
           "size=s" => \my $size,
           "gdb" => \my $gdb,
           "args=i{5}" => \my @args,
           "plot" => \my $plot,
           "build!" => \$build,
           "backend=s" => \$backend,
           "benchmark" => \my $benchmark
          );

$debug = 1 if $gdb;

if ($build) {
  my @definitions;
  push @definitions, "-DPRINT_PLOT_TEXT=" . ($plot ? 1 : 0);
  push @definitions, "-DCMAKE_BUILD_TYPE=" . ($debug ? "DEBUG" : "RELEASE");
  
  print `cmake -B build @definitions`;
  die "Configure failed" if $?;
  print `cmake --build build`;
  die "Build failed" if $?;
} else {
  print "Skipping build (some changes will not take effect)\n";
}

my %sizes = (
          massive => [128, 128, 7, 256, 256],
          large => [128, 128, 7, 64, 64],
          normal => [128, 128, 7, 32, 32],
          smallest => [16, 16, 3, 32, 32]
         );

@args = @{$sizes{$size}} if ($sizes{$size});

if ($gdb) {
  system "gdb ./build/concurrent -ex 'run @args'";
} else {
  if ($plot) {
    open FH, "./build/concurrent @args|";
    if ($backend eq "gnuplot") {
      open GP, "|gnuplot";
      print GP <<EOF;
set style data line
set autoscale
set terminal x11 noraise
set xlabel "x"
set ylabel "y"
set zlabel "time"
EOF
      my @data;
      while (<FH>) {
        next unless /writing to \(\*t\)\[(\d+)\]\[(\d+)\]\[(\d+)\]/;
        next unless $1 == 0;
        push @data, [$1, $2, $3];
        print GP "splot \"-\"\n";
        print GP "# X Y Z\n";
        for (0..$#data) {
          my $datum = $data[$_];
          print GP "@$datum[1] @$datum[2] $_\n";
        }
        print GP "e\n";
        sleep (0.5);
      }
    } elsif ($backend eq "python") {
      open PY, "|python3 plot.py";
      my $t = 0;
      while (<FH>) {
        next unless /writing to \(\*t\)\[(\d+)\]\[(\d+)\]\[(\d+)\]/;
        next unless $1 == 0;
        print PY "$2 $3 $t\n";
        $t++;
      }
    } else {
      print ("Unsupported backend plotting backend `$backend`");
      exit 1;
    }
  } elsif ($benchmark) {
    for (0..10) {
      open FH, "./build/concurrent @args|";
      my ($original) = <FH> =~ /(\d+)/;
      my ($student) = <FH> =~ /(\d+)/;
      my $speedup = $original / $student;
      print "Got: ${speedup}x faster ($original vs $student)\n";
      close FH;
    }
    
  } else {
    open FH, "./build/concurrent @args|";
    print $_ while <FH>;
  }
}
