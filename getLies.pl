use lib './MarioGolfNN';
use input;
use output;
use Math::Round qw( round );

my @searchArea = (
# rotation
[-30, 30],
# power
[5, 31],
# contactX
[-1, 1],
# contactY
[-1, 1]
);

sub findBestStroke {
    my $state = $_[0];

    loadState($state);

    my @lie = findLie();
    
    my $outputStr = "".$lie[0].", ".$lie[1].", ".$lie[2]."\n";
    
    open my $fh, '>>', './data/lies1.csv';
    print $fh ($outputStr);
    close $fh;
}

sleep(3);
for(my $i = 0; $i < 64; $i ++){
    findBestStroke($i);
}

# my @lie = findLie();
# print "".$lie[0].", ".$lie[1].", ".$lie[2]."\n";