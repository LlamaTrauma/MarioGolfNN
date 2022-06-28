use lib './MarioGolfNN';
use input;
use output;
use Math::Round qw( round );
use 5.010;

sub testDrive {
    state $currentState = "";
    my $power = round(5 + rand(27));
    my $rotation = round(rand(40) - 20);
    my $club = int(rand(13));
    my $shotType = 1;
    my $contactX = 0;
    my $contactY = 0;
    my $windDir = round(rand(150));
    my $windStrength = round(rand(21));
    $rotation = round(cos($windDir * 3.1415 / 75 + 3.1415 / 2) * $windStrength * 5/21);
    if($club >= 5){
        $rotation = 0;
    }
    $power = 9;
    $rotation = 0;
    $club = 10;
    $windDir = 57;
    $windStrength = 18;
    print("$power, $rotation, $club, $shotType, $contactX, $contactY, $windDir, $windStrength\n");
    # print("currentState: $currentState\n");
    if($powerLevels[$club][$shotType] * $power / 31 > 40){
        if($currentState ne "d"){
            loadState("d");
            $currentState = "d";
            sleep(1);
            writeKey2(0x67);
            sleep(1);
        } else {
            writeKey2(0x65);
            sleep(1);
        }
    } else {
        if($currentState ne "e"){
            loadState("e");
            $currentState = "e";
            sleep(1);
            writeKey2(0x67);
            sleep(1);
        } else {
            writeKey2(0x65);
            sleep(1);
        }
        $rotation = 0;
        # $windDir -= 38;
    }
    sleep(2);
    updateValues();
    my @initialPos = ($addresses{0x202225F4}{value}, $addresses{0x202225F8}{value}, $addresses{0x202225FC}{value});
    my $initialAngle = $addresses{0x201F4438}{value};

    takeDrivingRangeStroke($rotation, $power, $contactX, $contactY, $windDir, $windStrength, $club);
    waitTicks(50);

    updateValues();
    my @finalPos = ($addresses{0x201B553C}{value} + 15, $addresses{0x201B5540}{value} + 30, $addresses{0x201B5544}{value});
    my @deltaPos = ($finalPos[0] - $initialPos[0], $finalPos[1] - $initialPos[1], $finalPos[2] - $initialPos[2]);
    if($finalPos[1] > -299){
        print("Landed off course");
        print($addresses{0x201B5540}{value});
        print("\n");
        return;
    } else {
        my $angle = atan2(-$deltaPos[2], $deltaPos[0]);
        # print("Initial Angle: $initialAngle\n");
        # print("Angle: $angle\n");
        # print deltaPos
        # print("$deltaPos[0], $deltaPos[1], $deltaPos[2]\n");
        my $deltaAngle = $initialAngle - $angle;
        if($deltaAngle < -3.1415){
            $deltaAngle += 2 * 3.1415;
        } elsif ($deltaAngle > 3.1415){
            $deltaAngle -= 2 * 3.1415;
        }
        $deltaAngle += $rotation * 3.1415 * 2 / 271;
        my $unitsPerYard = 24 / 1.75;
        my $dist = sqrt($deltaPos[0] ** 2 + $deltaPos[2] ** 2);
        my $clubPower = $powerLevels[$club][$shotType];
        my $distanceRatio = $dist / ($clubPower * $unitsPerYard);
        my @xVect = (cos($angle - 3.1415 / 2), -sin($angle - 3.1415 / 2));
        # print("$xVect[0], $xVect[1]\n");
        my @yVect = (cos($angle), -sin($angle));
        # print("$yVect[0], $yVect[1]\n");
        my $windAngle = $windDir * 3.1415 / 75 - 3.1415 / 2;
        my @windVect = (-cos($windAngle) * $windStrength, -sin($windAngle) * $windStrength);
        my $revisedWindX = $xVect[0] * $windVect[0] + $xVect[1] * $windVect[1];
        my $revisedWindY = $yVect[0] * $windVect[0] + $yVect[1] * $windVect[1];
        # print("Wind: $revisedWindX, $revisedWindY\n");
        # print("Rotation: $deltaAngle\n");

        my $inData = "$distanceRatio, $club, $revisedWindX, $revisedWindY";
        my $outData = "$deltaAngle, $power";
        my $rawData = "$power, $rotation, $club, $shotType, $contactX, $contactY, $windDir, $windStrength, $initialPos[0], $initialPos[1], $initialPos[2], $initialAngle, $finalPos[0], $finalPos[1], $finalPos[2]";
        
        open my $fh, '>>', './data/drives.csv';
        print $fh ($inData.", ".$outData."\n");
        close $fh;

        open my $fh, '>>', './data/rawdrives.csv';
        print $fh ($rawData."\n");
        close $fh;
    }
}

sleep(3);
while(1){
    testDrive();
}

# testDrive();

# my $windDir = 150 -38;
# print("angle: ");
# print($windDir * 3.1415 / 75 - 3.1415 / 2);