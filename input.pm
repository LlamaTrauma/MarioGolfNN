package input;

our @ISA = qw( Exporter );

# these are exported by default.
our @EXPORT = qw( printValues updateValues updateValue %addresses getDistance waitForShotFinish getSurfacePenalty getFutureDistance getFutureSurfacePenalty waitTicks waitTicks2 @powerLevels @powerRanges );

use strict; use warnings; use Switch;

use Win32;
use Win32::Process;
use Win32::Process::Memory;

our %addresses = (
    0x202225F4 => {
        type => "float",
        desc => "X position of ball",
        value => 0
    },
    0x202225F8 => {
        type => "float",
        desc => "Y position of ball",
        value => 0
    },
    0x202225FC => {
        type => "float",
        desc => "Z position of ball",
        value => 0
    },
    0x20104F44 => {
        type => "float",
        # double check
        desc => "Wind vector X",
        value => 0
    },
    0x20104F4C => {
        type => "float",
        desc => "Wind vector Z",
        value => 0
    },
    0x200FBE70 => {
        type => "uint8",
        desc => "Surface Type",
        value => 0
    },
    0x200C310C => {
        type => "uint8",
        desc => "Timer",
        value => 10
    },
    0x200DAC5A => {
        type => "int16",
        desc => "X position of hole",
        value => 10
    },
    0x200DAC58 => {
        type => "int16",
        desc => "Y position of hole",
        value => 10
    },
    0x200DAC5E => {
        type => "int16",
        desc => "Z position of hole",
        value => 10
    },
    0x200FBE58 => {
        type => "uint8",
        desc => "Club",
        value => 10
    },
    0x200FBE54 => {
        type => "uint8",
        desc => "Shot type",
        value => 10
    },
    0x201F4438 => {
        type => "float",
        desc => "Facing angle",
        value => 10
    },
    0x20106243 => {
        type => "uint8",
        desc => "Game state",
        # Hitting = 5, Putting = 3, Shot in air = 128, can't hit = 0
        value => 10
    },
    0x201B5540 => {
        type => "float",
        desc => "Ball final Y position",
        value => 10
    },
    0x201B553C => {
        type => "float",
        desc => "Ball final X position (but -15?)",
        value => 10
    },
    0x201B5544 => {
        type => "float",
        desc => "Ball final Z position (but -30?)",
        value => 10
    },
    0x20250B63 => {
        type => "uint8",
        desc => "Ball final surface type",
        value => 10
    },
    0x200BA9F8 => {
        type => "uint8",
        # 1 yes, 0 no
        desc => "Raining?",
        value => 10
    },
    0x200DEAC2 => {
        type => "int16",
        desc => "Player X",
        value => 10
    },
    0x200DEAC0 => {
        type => "int16",
        desc => "Player Y",
        value => 10
    },
    0x200DEAC6 => {
        type => "int16",
        desc => "Player Z",
        value => 10
    },
    0x200FBD98 => {
        type => "int32",
        desc => "Keys",
        value => 10
    },
    0x200B7736 => {
        type => "uint8",
        desc => "Timer that increments when paused",
        value => 10
    },
    0x20223E5C => {
        type => "uint8",
        desc => "Game state (0 when can hit, 1 when can't)",
        value => 10
    }
);

our @powerLevels = (
    [275, 250, 60],
    [256, 233, 60],
    [237, 216, 60],
    [218, 199, 60],
    [205, 187, 60],
    [193, 176, 60],
    [181, 165, 60],
    [168, 153, 60],
    [156, 142, 60],
    [144, 131, 60],
    [130, 119, 60],
    [112, 102, 60],
    [88, 80, 60],
    [200 / 3, 100 / 3, 30 / 3]
);

our @powerRanges = (
    [100, 100],
    [98, 100],
    [80, 90],
    [70, 85],
    [100, 100],
    [100, 100],
    [80, 100],
    [98, 100],
    [80, 90],
    [98, 100],
    [90, 98],
    [80, 90],
    [50, 80],
    [80, 90],
    [50, 80],
    [98, 100],
    [50, 70],
    [40, 60],
    [40, 60],
    [94, 98],
    [90, 94],
    [70, 85],
    [100, 100],
    [98, 100],
    [100, 100],
    [98, 100],
    [80, 100],
    [100, 100]
);

my $mem = Win32::Process::Memory->new({
    pid => 1616,
    access => 'read/query'
});

sub getSurfacePenalty {
    updateValue(0x200FBE70);
    my $surface = $addresses{0x200FBE70}{value};
    if($surface < (scalar @powerRanges)){
        return ($powerRanges[$surface][0] + $powerRanges[$surface][1]) / 200;
    }
    return 1;
}

sub getFutureSurfacePenalty {
    updateValue(0x20250B63);
    my $surface = $addresses{0x20250B63}{value};
    if($surface < (scalar @powerRanges)){
        return ($powerRanges[$surface][0] + $powerRanges[$surface][1]) / 200;
    }
    return 1;
}

sub updateValues {
    foreach my $key (keys %addresses){
        switch ($addresses{$key}{type}){
            case "float" {$addresses{$key}{value} = $mem->get_float($key, 255)}
            case "uint8" {$addresses{$key}{value} = $mem->get_u8($key, 255)}
            case "int16" {$addresses{$key}{value} = $mem->get_i16($key, 255)}
            case "int32" {$addresses{$key}{value} = $mem->get_i32($key, 255)}
            else {$addresses{$key}{value} = 255}
        }
    }
}

sub updateValue {
    my $key = $_[0];
    switch ($addresses{$key}{type}){
        case "float" {$addresses{$key}{value} = $mem->get_float($key, 255)}
        case "uint8" {$addresses{$key}{value} = $mem->get_u8($key, 255)}
        case "int16" {$addresses{$key}{value} = $mem->get_i16($key, 255)}
        case "int32" {$addresses{$key}{value} = $mem->get_i32($key, 255)}
        else {$addresses{$key}{value} = 255}
    }
}

sub printValues {
    foreach my $key (keys %addresses){
        printf "$key\n    $addresses{$key}{desc}\n    $addresses{$key}{value}\n";
    }
}

# updateValues();
# print "$addresses{0x20106243}{value} \n";

sub getDistance {
    updateValues();
    my $dx = $addresses{0x200DAC5A}{value} - $addresses{0x202225F4}{value};
    my $dy = $addresses{0x200DAC58}{value} - $addresses{0x202225F8}{value};
    my $dz = $addresses{0x200DAC5E}{value} - $addresses{0x202225FC}{value};
    return sqrt($dx * $dx + $dy * $dy + $dz * $dz);
}

sub getFutureDistance {
    updateValues();
    my $dx = $addresses{0x200DAC5A}{value} - ($addresses{0x201B553C}{value} + 15);
    # Think the 30 shold be on y, not z if I use this again might want to check that
    my $dy = $addresses{0x200DAC58}{value} - $addresses{0x201B5540}{value};
    my $dz = $addresses{0x200DAC5E}{value} - ($addresses{0x201B5544}{value} + 30);
    return sqrt($dx * $dx + $dy * $dy + $dz * $dz);
}

sub waitTicks {
    my $ticks = $_[0];
    updateValue(0x200C310C);
    my $finishedTime = ($addresses{0x200C310C}{value} + $ticks) % 256;
    while($addresses{0x200C310C}{value} != $finishedTime){
        updateValue(0x200C310C);
    }
}

sub waitTicks2 {
    my $ticks = $_[0];
    updateValue(0x200B7736);
    my $finishedTime = ($addresses{0x200B7736}{value} + $ticks) % 256;
    while($addresses{0x200B7736}{value} != $finishedTime){
        # print "$addresses{0x200B7736}{value}\n";
        updateValue(0x200B7736);
    }
}

sub waitForShotFinish {
    my $abortTime = time() + 20;
    my $winTime = 256;
    updateValue(0x20106243);
    while($addresses{0x20106243}{value} != 3){
        updateValue(0x20106243);
        if($addresses{0x20106243}{value} == 0 && $winTime == 256){
            updateValue(0x200C310C);
            print("AdsfadsfdS");
            $winTime = ($addresses{0x200C310C}{value} + 90) % 256;
        }
        updateValue(0x200C310C);
        if($addresses{0x200C310C}{value} == $winTime){
            # Shot went in hole
            print("AdsfadsfdS");
            return 0;
        }

        if($addresses{0x20106243}{value} == 5){
            # Shot is on ground
            return 1;
        }

        if(time() > $abortTime){
            # Something went wrong
            return 2;
        }
    }
}

1;