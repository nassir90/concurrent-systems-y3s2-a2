#!/usr/bin/perl
use strict;
use Getopt::Long;

# build by default
my $build = 1;
# use gnuplot plottting backend by default
my $backend = "gnuplot";
# the number of times to benchmark
my $count = 10;
my $run = 1;

GetOptions
  (
   "debug" => \my $debug,
   "size=s" => \my $size,
   "gdb" => \my $gdb,
   "args=i{5}" => \my @args,
   "plot" => \my $plot,
   "build!" => \$build,
   "backend=s" => \$backend,
   "benchmark" => \my $benchmark,
   "count=i" => \$count,
   "plot-wait" => \my $plotwait,
   "run!" => \$run
  );

$debug = 1 if $gdb;

if ($build) {
  my @definitions =
    (
     "-DPRINT_PLOT_TEXT=" . ($plot ? 1 : 0),
     "-DCMAKE_BUILD_TYPE=" . ($debug ? "DEBUG" : "RELEASE")
    );
  print `cmake -B build @definitions`;
  die "Configure failed" if $?;
  print `cmake --build build`;
  die "Build failed" if $?;
} else {
  print "Skipping build (some changes will not take effect)\n";
}

exit 0 unless $run;

my %sizes =
  (
   massive => [128, 128, 7, 256, 256],
   large => [128, 128, 7, 64, 64],
   normal => [128, 128, 7, 32, 32],
   smallest => [16, 16, 3, 32, 32],
   atom => [16, 16, 1, 32, 32]
  );

@args = @{$sizes{$size}} if ($sizes{$size});

if ($gdb) {
  system "gdb ./build/concurrent -ex 'run @args'";
} else {
  if ($plot) {
    open FH, "./build/concurrent @args|";
    if ($backend eq "gnuplot") {
      my $pid = open GP, "|2>/dev/null gnuplot";
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
      }
      waitpid $pid, 0 if ($plotwait);
    } elsif ($backend eq "python") {
      my $pid = open PY, "|python3 plot.py";
      my $t = 0;
      while (<FH>) {
        next unless /writing to \(\*t\)\[(\d+)\]\[(\d+)\]\[(\d+)\]/;
        next unless $1 == 0;
        print PY "$2 $3 $t\n";
        $t++;
      }
      # waitpid $pid, 0 if ($plotwait);
    } else {
      print ("Unsupported backend plotting backend `$backend`");
      exit 1;
    }
  } elsif ($benchmark) {
    my @results;
    for (1..$count) {
      open FH, "./build/concurrent @args|";
      my ($original) = <FH> =~ /(\d+)/;
      my ($student) = <FH> =~ /(\d+)/;
      my ($speedup) = <FH> =~ /([.0-9]+)/;
      my ($delta) = <FH> =~ /([.0-9]+)/;
      push @results, [$original, $student, $speedup, $delta];
      print "Got: ${speedup}x speedup ($original vs $student) [δ=$delta]\n";
      close FH;
    }
    my @speedups = map { @$_[2] } @results;
    local $" = ",";
    my ($mean, $sd) = split /,/, `Rscript - <<EOF
speedups_ <- c(@speedups);
mean_ <- mean(speedups_)
sd_ <- sd(speedups_);
message_ <- sprintf("%f,%f", mean_, sd_);
cat(message_);
EOF`;
    print "speedup = N(μ=${mean}, σ=$sd)\n";
    
  } else {
    open FH, "./build/concurrent @args|";
    print $_ while <FH>;
  }
}
