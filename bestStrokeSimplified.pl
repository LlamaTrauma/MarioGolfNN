use lib './MarioGolfNN';
use input;
use output;
use Math::Round qw( round );

my @searchArea = (
# rotation
[-20, 20],
# power
[5, 31],
# contactX
[-1, 1],
# contactY
[-1, 1]
);

sub testStroke {
    my $rotation = $_[0];
    my $level = $_[1];
    my $contactX = 0;
    my $contactY = 0;

    my $initialDist = getDistance();
    takeStroke($rotation, $level, $contactX, $contactY);

    waitTicks(50);
    my $finalDist = getFutureDistance();
    # my $code = waitForShotFinish();
    # if($code == 2){
    #     # Something went wrong
    #     print "waitForShotFinish returned 2\n";
    #     return 0;
    # }

    # updateValues();
    # my $finalDist = getDistance();
    # my $penalty = getFutureSurfacePenalty();
    # my $score = ($initialDist - $finalDist) * getFutureSurfacePenalty();
    # print "Penalty: $penalty\n";
    return ($initialDist - $finalDist) * getFutureSurfacePenalty();
}

sub findBestStroke {
    my $state = $_[0];

    loadState($state);
    sleep(2);
    writeKey2(0x67);
    sleep(2);

    my @keys = (0x202225F4, 0x202225F8, 0x202225FC, 0x20104F44, 0x20104F4C, 0x200FBE70, 0x200DAC5A, 0x200DAC58, 0x200DAC5E, 0x200FBE58, 0x200FBE54, 0x201F4438, 0x20106243, 0x200BA9F8);
    
    updateValues();
    my $dx = $addresses{$keys[6]}{value} - $addresses{$keys[0]}{value};
    my $dz = $addresses{$keys[8]}{value} - $addresses{$keys[2]}{value};
    print("$addresses{$keys[6]}{value}, $addresses{$keys[0]}{value}, $addresses{$keys[8]}{value}, $addresses{$keys[2]}{value}");
    my $facingAngle = $addresses{$keys[11]}{value};
    my $targetAngle = atan2(-$dz, $dx);
    if($targetAngle < 0){
        $targetAngle += 2 * 3.1415;
    }
    my $dist = abs($facingAngle - $targetAngle);
    my $rotationAmount = 0;
    print("Rotating to face hole\n");
    print("$facingAngle, $targetAngle\n");
    while($dist > 0.024){
        rotate(1);
        $rotationAmount += 1;
        updateValue($keys[11]);
        $dist = abs($addresses{$keys[11]}{value} - $targetAngle);
        # print("$addresses{$keys[11]}{value}, $targetAngle\n");
    }
    # $facingAngle = $addresses{$keys[11]}{value};
    # if(abs(($facingAngle - 0.023) - $targetAngle) < $dist){
    #     rotate(-1);
    # } elsif (abs(($facingAngle + 0.023) - $targetAngle) < $dist){
    #     rotate(1);
    # }
    print("Done\n");

    writeKey2(0x67);
    sleep(2);

    updateValues();
    my @lie = findLie();
    my $inputStr = "".$rotationAmount.", ".$lie[0].", ".$lie[1].", ";
    for (my $key = 0; $key < scalar @keys; $key ++){
        $inputStr = $inputStr.$addresses{$keys[$key]}{value}.", ";
    }
    
    my @searchTL = (
        -5, 10
    );
    my @searchRadius = (
        5, 8
    );
    my %strokeResults = ();
    my $bestValue = 0;
    my @bestStroke = (
        0, 0
    );
    my $numSearches = 0;
    my $numStrokes = 0;
    my %searchResults = ();

    my $dist = testStroke(0, 18);
    if($dist > $bestValue){
        $bestValue = $dist;
        @bestStroke = (0, 18);
        print "    New best found! Score: $dist, Stroke: ".join(", ", @bestStroke).", Final dist: ".getFutureDistance()."\n";
    }
    $numStrokes += 1;
    $searchResults{"0_18"} = $dist;

    while($numSearches < 8){
        print "Starting round $numSearches of $dataNum:\n";
        my @searchVals = (
            [],
            [],
            [],
            []
        );
        for(my $i = 0; $i < 2; $i++){
            my $lastPush = 99999999;
            for(my $j = 0; $j < 3; $j++){
                my $toPush = round($searchTL[$i] + $searchRadius[$i] * $j);
                if($toPush != $lastPush){
                    push(@{$searchVals[$i]}, $toPush);
                    $lastPush = $toPush;
                }
            }
        }
        my @searchIndices = (
            0, 0
        );
        while($searchIndices[0] < scalar(@{$searchVals[0]})){
            my $hashKey = "".$searchVals[0][$searchIndices[0]]."_".$searchVals[1][$searchIndices[1]];
            if(!(exists $searchResults{$hashKey})){
                writeKey2(0x65);
                sleep(1);
                my $dist = testStroke(
                    $searchVals[0][$searchIndices[0]],
                    $searchVals[1][$searchIndices[1]]);
                
                if($dist > $bestValue){
                    $bestValue = $dist;
                    @bestStroke = (
                        $searchVals[0][$searchIndices[0]],
                        $searchVals[1][$searchIndices[1]]);
                    print "    New best found! Score: $dist, Stroke: ".join(", ", @bestStroke).", Final dist: ".getFutureDistance()."\n";
                }
                $numStrokes += 1;
                $searchResults{$hashKey} = $dist;
            }
            my $rollover = (scalar @searchIndices) - 1;
            $searchIndices[$rollover] += 1;
            while($rollover > 0 && $searchIndices[$rollover] >= scalar(@{$searchVals[$rollover]})){
                $searchIndices[$rollover] = 0;
                $rollover -= 1;
                $searchIndices[$rollover] += 1;
            }
        }
        for(my $i = 0; $i < 2; $i ++){
            $searchRadius[$i] = $searchRadius[$i] * 0.65;
            if($bestStroke[$i] + $searchRadius[$i] > $searchArea[$i][1]){
                $searchTL[$i] = $searchArea[$i][1] - $searchRadius[$i] * 2;
            } elsif($bestStroke[$i] - $searchRadius[$i] < $searchArea[$i][0]){
                $searchTL[$i] = $searchArea[$i][0];
            } else {
                $searchTL[$i] = $bestStroke[$i] - $searchRadius[$i];
            }
        }
        print "    Round $numSearches over, $numStrokes total shots taken\n";
        $numSearches += 1;
    }

    my $outputStr = "".$bestStroke[0].", ".$bestStroke[1]."\n";
    
    open my $fh, '>>', './data/all4.csv';
    print $fh ($inputStr.$outputStr);
    close $fh;

    # open my $fh, '>', './data/'.$dataNum.'.txt';
    # print $fh ($inputStr.$outputStr);
    # close $fh;
}

sleep(3);
# for(my $i = 0; $i < 64; $i ++){
#     findBestStroke($i);
# }
for(my $i = 130; $i < 164; $i ++){
    findBestStroke($i);
}