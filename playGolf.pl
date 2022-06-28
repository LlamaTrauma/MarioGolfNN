use lib './MarioGolfNN';

use input;
use output;
use stroke;
use Win32::GuiTest qw(FindWindowLike GetWindowText SetForegroundWindow SendKeys SendRawKey KEYEVENTF_KEYUP KEYEVENTF_EXTENDEDKEY);
use Time::HiRes qw( usleep );

while(1){
    updateValue(0x20223E5C);
    my $gameState = $addresses{0x20223E5C}{value};
    print("Game state: ".$gameState."\n");
    if($gameState == 0){
        waitTicks(45);
        stroke();
    } else {
        # print("Starting press\n");
        # SendRawKey(0x58, 0);
        # # I'm just throwing a 2 randomly in some of these to use the timer that works in the scenario
        # waitTicks2(2);
        # SendRawKey(0x58, KEYEVENTF_KEYUP);
        usleep(100000);
        # print("Ending press\n");
    }
}