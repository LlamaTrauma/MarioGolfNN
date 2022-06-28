package output;

use Win32::GuiTest qw(FindWindowLike GetWindowText SetForegroundWindow SendKeys SendRawKey KEYEVENTF_KEYUP KEYEVENTF_EXTENDEDKEY);

use lib './MarioGolfNN';
use input;
use Time::HiRes qw( usleep );

our @ISA = qw( Exporter );

our @EXPORT = qw( takeStroke loadState writeKey2 rotate findLie findLieVectors takeDrivingRangeStroke );

my $windows = FindWindowLike(0, "Project64");
my $window = $windows[0]; 
SetForegroundWindow($window);

sub pressKey {
    my $key = $_[0];
    my $length = $_[1];
    $length ||= 0;
    if($length == 0){
        SendKeys($key);
    } else {
        SendKeys($key, $length);
    }
}

sub writeKey2 {
    my $key = $_[0];
    SendRawKey($key, 0);
    usleep(100000);
    SendRawKey($key, KEYEVENTF_KEYUP);
}

sub writeKey {
    my $key = $_[0];
    SendRawKey($key, 0);
    waitTicks2(2);
    SendRawKey($key, KEYEVENTF_KEYUP);
}

sub loadState {
    my $state = "".$_[0];
    writeKey2(0x69);
    sleep(2);
    for $i (0..length($state)-1){
        $char = substr($state, $i, 1);
        if(ord($char) >= ord("0") && ord($char) <= ord("9")){
            writeKey2(0x30 + int($char));
        } else {
            writeKey2(0x41 + ord($char) - ord("a"));
        }
        usleep(200000);
    }
    # .
    writeKey2(0xBE);
    usleep(200000);
    # p
    writeKey2(0x50);
    usleep(200000);
    # j
    writeKey2(0x4A);
    usleep(200000);
    # .
    writeKey2(0xBE);
    usleep(200000);
    # z
    writeKey2(0x5A);
    usleep(200000);
    # i
    writeKey2(0x49);
    usleep(200000);
    # p
    writeKey2(0x50);
    usleep(200);

    writeKey2(0x0D);
}

sub rotate {
    my $rotation = $_[0];
    my $key = $_[1] || 0x200B7736;
    my $rollovers = int($rotation / 256);

    updateValue($key);
    my $press = ($addresses{$key}{value} + 1) % 256;
    my $release = ($addresses{$key}{value} + 1 + abs($rotation)) % 256;
    my $endlag = ($addresses{$key}{value} + 3 + abs($rotation)) % 256;
    
    while($addresses{$key}{value} != $press){
        updateValue($key);
    }
    if($rotation < 0){
        SendRawKey(0x64, 0);
    } elsif ($rotation > 0){
        SendRawKey(0x66, 0);
    }
    
    my $canRollover = 0;
    
    while($addresses{$key}{value} != $release || $rollovers != 0){
        updateValue($key);
        if($addresses{$key}{value} == $press){
            if($canRollover){
                $rollovers -= 1;
                $canRollover = 0;
            }
        } else {
            $canRollover = 1;
        }

    }

    if($rotation < 0){
        SendRawKey(0x64, KEYEVENTF_KEYUP);
    } elsif ($rotation > 0){
        SendRawKey(0x66, KEYEVENTF_KEYUP);
    }

}

sub findLie {
    updateValues();
    
    my $facingAngle = $addresses{0x201F4438}{value};
    my @xVect = (cos($facingAngle - 3.1415 / 2), 0, sin($facingAngle - 3.1415 / 2));
    # Make xVect unit vector
    my $xVectMag = sqrt($xVect[0] ** 2 + $xVect[2] ** 2);
    $xVect[0] = $xVect[0] / $xVectMag;
    $xVect[2] = $xVect[2] / $xVectMag;
    my @yVect = (cos($facingAngle), 0, sin($facingAngle));
    # Make yVect unit vector
    my $yVectMag = sqrt($yVect[0] ** 2 + $yVect[2] ** 2);
    $yVect[0] = $yVect[0] / $yVectMag;
    $yVect[2] = $yVect[2] / $yVectMag;
    my @zVect = (0, 1, 0);

    my @playerPos = ($addresses{0x200DEAC2}{value}, $addresses{0x200DEAC0}{value}, $addresses{0x200DEAC6}{value});
    my @ballPos = ($addresses{0x202225F4}{value}, $addresses{0x202225F8}{value}, $addresses{0x202225FC}{value});
    my @v1 = ($ballPos[0] - $playerPos[0], $ballPos[1] - $playerPos[1], $ballPos[2] - $playerPos[2]);
    rotate(68, 0x200C310C);
    updateValues();
    @playerPos = ($addresses{0x200DEAC2}{value}, $addresses{0x200DEAC0}{value}, $addresses{0x200DEAC6}{value});
    @ballPos = ($addresses{0x202225F4}{value}, $addresses{0x202225F8}{value}, $addresses{0x202225FC}{value});
    my @v2 = ($ballPos[0] - $playerPos[0], $ballPos[1] - $playerPos[1], $ballPos[2] - $playerPos[2]);
    rotate(-68, 0x200C310C);
    my @v3 = ($v1[2] * $v2[1] - $v1[1] * $v2[2], $v1[0] * $v2[2] - $v1[2] * $v2[0], $v1[1] * $v2[0] - $v1[0] * $v2[1]);
    if($v3[1] > 0){
        $v3[0] *= -1;
        $v3[1] *= -1;
        $v3[2] *= -1;
    }
    my $mag = sqrt($v3[0] * $v3[0] + $v3[1] * $v3[1] + $v3[2] * $v3[2]);
    $v3[0] /= $mag;
    $v3[1] /= $mag;
    $v3[2] /= $mag;

    my $adjustedX = $xVect[0] * $v3[0] + $xVect[2] * $v3[2];
    my $adjustedY = $yVect[0] * $v3[0] + $yVect[2] * $v3[2];
    my $adjustedZ = $zVect[1] * $v3[1];
    return ($adjustedX, $adjustedZ, $adjustedY);
}

sub findLieVectors {
    updateValues();
    
    my $facingAngle = $addresses{0x201F4438}{value};
    my @xVect = (cos($facingAngle - 3.1415 / 2), 0, sin($facingAngle - 3.1415 / 2));
    # Make xVect unit vector
    # Wait it already is isn't it
    my $xVectMag = sqrt($xVect[0] ** 2 + $xVect[2] ** 2);
    $xVect[0] = $xVect[0] / $xVectMag;
    $xVect[2] = $xVect[2] / $xVectMag;
    my @yVect = (cos($facingAngle), 0, sin($facingAngle));
    # Make yVect unit vector
    my $yVectMag = sqrt($yVect[0] ** 2 + $yVect[2] ** 2);
    $yVect[0] = $yVect[0] / $yVectMag;
    $yVect[2] = $yVect[2] / $yVectMag;
    my @zVect = (0, 1, 0);

    my @playerPos = ($addresses{0x200DEAC2}{value}, $addresses{0x200DEAC0}{value}, $addresses{0x200DEAC6}{value});
    my @ballPos = ($addresses{0x202225F4}{value}, $addresses{0x202225F8}{value}, $addresses{0x202225FC}{value});
    my @v1 = ($playerPos[0] - $ballPos[0], $playerPos[1] - $ballPos[1], $playerPos[2] - $ballPos[2]);
    my $mag = sqrt($v1[0] ** 2 + $v1[1] ** 2 + $v1[2] ** 2);
    $v1[0] /= $mag;
    $v1[1] /= $mag;
    $v1[2] /= $mag;
    rotate(68, 0x200C310C);
    updateValues();
    @playerPos = ($addresses{0x200DEAC2}{value}, $addresses{0x200DEAC0}{value}, $addresses{0x200DEAC6}{value});
    @ballPos = ($addresses{0x202225F4}{value}, $addresses{0x202225F8}{value}, $addresses{0x202225FC}{value});
    my @v2 = ($playerPos[0] - $ballPos[0], $playerPos[1] - $ballPos[1], $playerPos[2] - $ballPos[2]);
    my $mag2 = sqrt($v2[0] ** 2 + $v2[1] ** 2 + $v2[2] ** 2);
    $v2[0] /= $mag2;
    $v2[1] /= $mag2;
    $v2[2] /= $mag2;
    rotate(-68, 0x200C310C);
    my @v3 = ($v1[2] * $v2[1] - $v1[1] * $v2[2], $v1[0] * $v2[2] - $v1[2] * $v2[0], $v1[1] * $v2[0] - $v1[0] * $v2[1]);
    if($v3[1] < 0){
        $v3[0] *= -1;
        $v3[1] *= -1;
        $v3[2] *= -1;
    }
    my $mag = sqrt($v3[0] * $v3[0] + $v3[1] * $v3[1] + $v3[2] * $v3[2]);
    if($mag == 0){
        $mag = 1;
    }
    $v3[0] /= $mag;
    $v3[1] /= $mag;
    $v3[2] /= $mag;

    return ($v1[0], $v1[1], $v1[2], $v3[0], $v3[1], $v3[2], $v2[0], $v2[1], $v2[2]);
}

sub takeDrivingRangeStroke {
    my $rotation = $_[0];
    my $level = $_[1];
    my $contactX = $_[2];
    my $contactY = $_[3];
    
    my $windDir = $_[4];
    my $windPower = $_[5];
    my $club = $_[6];

    writeKey(0xDC);
    waitTicks2(5);
    writeKey(0x62);
    waitTicks2(1);
    writeKey(0x62);
    waitTicks2(1);
    writeKey(0x62);
    waitTicks2(2);
    if($windDir > 75){
        $windDir -= 150;
    }
    print("Rotating $windDir\n");
    rotate($windDir);
    print("Done\n");
    waitTicks2(1);
    writeKey(0x62);
    waitTicks2(1);
    for(my $i = 0; $i < $windPower; $i ++){
        writeKey(0x66);
        waitTicks2(1);
    }
    writeKey(0xDC);
    waitTicks2(2);
    for(my $i = 0; $i < $club; $i ++){
        writeKey(0x62);
        waitTicks2(1);
    }

    takeStroke($rotation, $level, $contactX, $contactY);
}

sub takeStroke {
    my $rotation = $_[0];
    my $level = $_[1];
    my $contactX = $_[2];
    my $contactY = $_[3];
    if ($level < 5){
        $level = 5;
    } elsif ($level > 31){
        $level = 31;
    }

    # updateValue(0x200C310C);
    # my $press = ($addresses{0x200C310C}{value} + 1) % 256;
    # my $release = ($addresses{0x200C310C}{value} + 1 + abs($rotation)) % 256;
    # my $endlag = ($addresses{0x200C310C}{value} + 3 + abs($rotation)) % 256;
    
    # while($addresses{0x200C310C}{value} != $press){
    #     updateValue(0x200C310C);
    # }
    # if($rotation < 0){
    #     SendRawKey(0x64, 0);
    # } elsif ($rotation > 0){
    #     SendRawKey(0x66, 0);
    # }
    
    # while($addresses{0x200C310C}{value} != $release){
    #     updateValue(0x200C310C);
    # }
    
    # if($rotation < 0){
    #     SendRawKey(0x64, KEYEVENTF_KEYUP);
    # } elsif ($rotation > 0){
    #     SendRawKey(0x66, KEYEVENTF_KEYUP);
    # }

    # while($addresses{0x200C310C}{value} != $endlag){
    #     updateValue(0x200C310C);
    # }

    rotate($rotation, 0x200C310C);

    updateValue(0x200C310C);
    my $firstPress = ($addresses{0x200C310C}{value} + 1) % 256;
    my $firstRelease = ($addresses{0x200C310C}{value} + 3) % 256;
    my $secondPress = ($addresses{0x200C310C}{value} + 1 + $level) % 256;
    my $secondRelease = ($addresses{0x200C310C}{value} + 3 + $level) % 256;
    my $thirdPress = ($addresses{0x200C310C}{value} + 1 + 61) % 256;
    my $thirdRelease = ($addresses{0x200C310C}{value} + 3 + 61) % 256;
    
    while($addresses{0x200C310C}{value} != $firstPress){
        updateValue(0x200C310C);
    }
    SendRawKey(0x58, 0);
    while($addresses{0x200C310C}{value} != $firstRelease){
        updateValue(0x200C310C);
    }
    SendRawKey(0x58, KEYEVENTF_KEYUP);
    
    while($addresses{0x200C310C}{value} != $secondPress){
        updateValue(0x200C310C);
    }
    SendRawKey(0x58, 0);
    while($addresses{0x200C310C}{value} != $secondRelease){
        updateValue(0x200C310C);
    }
    SendRawKey(0x58, KEYEVENTF_KEYUP);

    # Set contact x point
    if($contactX < 0){
        SendRawKey(0x25, 0);
    } elsif ($contactX > 0){
        SendRawKey(0x27, 0);
    }
    
    # Set contact y point
    if($contactY < 0){
        SendRawKey(0x68, 0);
    } elsif ($contactY > 0){
        SendRawKey(0x62, 0);
    }

    while($addresses{0x200C310C}{value} != $thirdPress){
        updateValue(0x200C310C);
    }
    SendRawKey(0x58, 0);
    while($addresses{0x200C310C}{value} != $thirdRelease){
        updateValue(0x200C310C);
    }
    SendRawKey(0x58, KEYEVENTF_KEYUP);

    # Release contact x point
    if($contactX < 0){
        SendRawKey(0x64, KEYEVENTF_KEYUP);
    } elsif ($contactX > 0){
        SendRawKey(0x66, KEYEVENTF_KEYUP);
    }
    
    # Release contact y pointx
    if($contactY < 0){
        SendRawKey(0x68, KEYEVENTF_KEYUP);
    } elsif ($contactY > 0){
        SendRawKey(0x62, KEYEVENTF_KEYUP);
    }
}

sub logInputs {
    my @lie = findLie();
    my $inputStr = "";
    updateValues();
    my @keys = (0x202225F4, 0x202225F8, 0x202225FC, 0x200DAC5A, 0x200DAC58, 0x200DAC5E, 0x200FBE58, 0x200FBE54, 0x201F4438, 0x20106243, 0x200BA9F8);
    my $inputStr = "";
    for (my $key = 0; $key < scalar @keys; $key ++){
        $inputStr = $inputStr.$addresses{$keys[$key]}{value}.", ";
    }
    $inputStr = $inputStr."$lie[0], $lie[2], ";
    my $rotation = 0;
    my $xPressed = 0;
    my $xCount = 0;
    my $power = 1;
    updateValue(0x200C310C);
    my $time = $addresses{0x200C310C}{value};
    while(1){
        while($addresses{0x200C310C}{value} == $time){
            updateValue(0x200C310C);
        }
        if($xCount > 0){
            $power += 1;
        }
        $time = $addresses{0x200C310C}{value};
        updateValue(0x200FBD98);
        if($addresses{0x200FBD98}{value} == 33024){
            $rotation -= 1;
        } elsif ($addresses{0x200FBD98}{value} == 32512){
            $rotation += 1;
        } elsif ($addresses{0x200FBD98}{value} == -2147483648){
            if($xPressed == 0){
                $xPressed = 1;
                $xCount += 1;
                if($xCount == 2){
                    print $inputStr."$rotation".", "."$power"."\n";
                    return;
                }
            } 
        } else {
            $xPressed = 0;
        }
    }
}

# logInputs();

# takeStroke(0, 30, 0, 0);

1;