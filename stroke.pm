package stroke;

use lib './MarioGolfNN';

use Win32::GuiTest qw(FindWindowLike GetWindowText SetForegroundWindow SendKeys SendRawKey KEYEVENTF_KEYUP KEYEVENTF_EXTENDEDKEY);
use input;
use output;
use Time::HiRes qw( usleep );

our @ISA = qw( Exporter );

our @EXPORT = qw( stroke );

sub sendInputs {
    my $line = $_[0] || "";
    my @inputs = split(", ", $line);
    updateValues();
    my $club = $addresses{0x200FBE58}{value};
    if($club <= 12){
        my @keys = (0x202225F4, 0x202225F8, 0x202225FC, 0x20104F44, 0x20104F4C, 0x200FBE70, 0x200DAC5A, 0x200DAC5E, 0x200DAC58, 0x200FBE58, 0x200FBE54, 0x201F4438, 0x20106243, 0x200BA9F8);
        my $inputStr = "0, 0, ";
        for (my $key = 0; $key < scalar @keys; $key ++){
            $inputStr = $inputStr.$addresses{$keys[$key]}{value}.", ";
        }
        # my @lie = findLie();
        my $numInputs = scalar @inputs;
        print("Num inputs: ".$numInputs."\n");
        if($numInputs == 0){
            SendRawKey(0x63, 0);
            usleep(50000);
            SendRawKey(0x63, KEYEVENTF_KEYUP);
            my @lie = findLieVectors();
            SendRawKey(0x63, 0);
            usleep(50000);
            SendRawKey(0x63, KEYEVENTF_KEYUP);
            $inputStr = $inputStr."$lie[0], $lie[1], $lie[2], $lie[3], $lie[4], $lie[5], $lie[6], $lie[7], $lie[8]";
        } else {
            for(my $i = 9; $i > 0; $i--){
                $inputStr = $inputStr.$inputs[$numInputs - $i].", ";
            }
        }
        $inputStr = substr $inputStr, 0, -2;
        print("Normal stroke\n");
        open my $fh, '>>', './input/stroke.txt';
        print $fh ($inputStr);
        close $fh;
    } else {
        # putting
        # Network doesn't adjust for rain
        updateValue(0x200BA9F8);
        my $raining = $addresses{0x200BA9F8}{value};
        my $rainingMultiplier = 1 + $raining * 0.3;
    
        # find power based on distance
        my $dist = getDistance();
        updateValue(0x200FBE54);
        my $shotType = $addresses{0x200FBE54}{value};
        my $unitsPerYard = 24 / 1.75;
        updateValue(0x200DAC58);
        updateValue(0x202225F8);
        my $elevationChange = $addresses{0x200DAC58}{value} - $addresses{0x202225F8}{value};
        if($elevationChange > 0){
            $dist -= $elevationChange * 1.5;
        } else {
            $dist -= $elevationChange * 4;
        }
        my $power = int($dist / ($powerLevels[13][$shotType] * $unitsPerYard) * 31 * $rainingMultiplier + 3);
        if($power > 31){
            SendRawKey(0x43, 0);
            usleep(50000);
            waitTicks(2);
            SendRawKey(0x43, KEYEVENTF_KEYUP);
            usleep(50000);
            updateValue(0x200FBE54);
            $shotType = $addresses{0x200FBE54}{value};
            $power = int($dist / ($powerLevels[13][$shotType % 3] * $unitsPerYard) * 31 * $rainingMultiplier + 3);
        }

        # find rotation based on slope of ground
        updateValue(0x201F4438);
        my $facingAngle = $addresses{0x201F4438}{value};
        SendRawKey(0x63, 0);
        usleep(50000);
        SendRawKey(0x63, KEYEVENTF_KEYUP);
        my @lie = findLieVectors();
        SendRawKey(0x63, 0);
        usleep(50000);
        SendRawKey(0x63, KEYEVENTF_KEYUP);
        my @lieY = ($lie[3], $lie[4], $lie[5]);
        my @xVect = (cos($facingAngle -3.1415 / 2), 0, -sin(facingAngle - 3.1415 / 2));
        my @yVect = (cos($facingAngle), 0, -sin($facingAngle));
        
        my $rotation = $xVect[0] * $lieY[0] + $xVect[2] * $lieY[2];
        $rotation *= $dist / $unitsPerYard * 3 * 0.2;
        $rotation = int($rotation);
        print("Rotation: ".$rotation.", Power: ".$power."\n");

        takeStroke($rotation, $power, 0, 0);

        open my $fh, '>>', './input/response.txt';
        print $fh ("ok");
        close $fh;
    }
}

sub stroke {
    # Network doesn't adjust for rain
    updateValue(0x200BA9F8);
    my $raining = $addresses{0x200BA9F8}{value};
    my $rainingMultiplier = 1 + $raining * 0.05;

    my $numClubChanges = 0;
    truncate './input/response.txt', 0;
    # Either putt or send data to python script with network
    sendInputs();

    # While not done
    while (1) {
        my $firstLine = "";
        my $secondLine = "";
        # Wait for a response
        while($firstLine eq ""){
            usleep(200000);
            open my $fh, '<', './input/response.txt';
            $firstLine = <$fh>;
            $secondLine = <$fh>;
            close $fh;
        }
        # Truncate file for the next message
        truncate './input/response.txt', 0;
        if($firstLine ne "ok"){
            updateValue(0x200FBE58);
            my @args = split(",", $firstLine);
            # Github Copilot just predicted that I'd want to set the maximum number of club changes to 2. That's crazy.
            # If returned power is above power gauge max, change club
            if(int(int($args[1]) * $rainingMultiplier) > 31 && $addresses{0x200FBE58}{value} >= 2 && $numClubChanges < 2){
                SendRawKey(0x68, 0);
                waitTicks(2);
                SendRawKey(0x68, KEYEVENTF_KEYUP);
                sendInputs($secondLine);
                $numClubChanges++;
            # else, just take the stroke
            } else {
                takeStroke(int($args[0]), int(int($args[1]) * $rainingMultiplier), int($args[2]), int($args[3]));
                last;
            }
        # And if the status is "ok" just end
        } else {
            last;
        }
    }
}

1;