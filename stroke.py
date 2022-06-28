import math
import sys
from os import system
import time
import torch
import torch.nn as nn
import torch.nn.functional as F

powerLevels = [
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
]

powerRanges = [
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
]

angles = [
    [0.9852806914143217, -0.1709443158637219, 0.081402055173201],
    [0.9824129716484985, -0.18672105702562414, 0.08045163430314017],
    [0.979244238916084, -0.20268379449196103, 0.07923948810184513],
    [0.9755562315198991, -0.2197499468548124, 0.07103028585205992],
    [0.9679812697097759, -0.25102243224670207, 0.046965487323577984],
    [0.9597884313112954, -0.2807243614669075, 0.027845784413095494],
    [0.9548011174108786, -0.2972453972577835, 0.024973486245018137],
    [0.9507842191973125, -0.3098537857205507, 0.0],
    # [0.9507842191973125, -0.3098537857205507, 0.012],
    [0.946121734008883, -0.32381115551510026, -0.012698476686864744],
    # [0.946121734008883, -0.32381115551510026, 0],
    [0.9390224515460379, -0.34385583533287445, -0.02040870965105304],
    # [0.9390224515460379, -0.34385583533287445, 0],
    [0.9336786078815, -0.35811207349720003, -0.02001868733835144],
    # [0.9336786078815, -0.35811207349720003, 0],
    [0.8780556921892173, -0.4785584618561399, -0.01828885841488157],
    # [0.8780556921892173, -0.4785584618561399, 0],
    [0.856232016829808, -0.5165914569130614, -0.016868292470634413]
    # [0.856232016829808, -0.5165914569130614, 0]
]

dataX = []
dataY = []

def parseLine(line):
    line = line.replace('\n', '')
    vals = line.split(', ')
    numVals = len(vals)
    
    ballPos = [float(x) for x in [vals[2], vals[3], vals[4]]]
    surfaceType = int(vals[7])
    windVect = [float(x) for x in [vals[5], vals[6]]]
    holePos = [int(x) for x in [vals[8], vals[10], vals[9]]]
    club = int(vals[11])
    shotType = int(vals[12])
    facingAngle = float(vals[13])
    raining = int(vals[15])
    lieX = [float(vals[16]), float(vals[17]), float(vals[18])]
    lieY = [float(vals[19]), float(vals[20]), float(vals[21])]
    lieZ = [float(vals[22]), float(vals[23]), float(vals[24])]
    
    # Pretty sure this is horribly wrong
    # verticalAspect = 0 * lieY[0] + angles[club][1] * lieY[1] + angles[club][0] * lieY[2]
    # zAspect = 0 * lieZ[0] + angles[club][1] * lieZ[1] + angles[club][0] * lieZ[2]
    # xAspect = 0 * lieX[0] + angles[club][1] * lieX[1] + angles[club][0] * lieX[2]
    # horizontalAspect = math.sqrt(zAspect ** 2 + xAspect ** 2)

    normalAngle = math.atan2(-angles[club][1], angles[club][0])
    slopeAngle = math.atan2(-lieZ[1], -lieZ[2])
    # print(normalAngle, slopeAngle)
    totalAngle = normalAngle + slopeAngle
    horizontalAspect = math.cos(totalAngle)
    verticalAspect = -math.sin(totalAngle)
    # print("\n")
    print(horizontalAspect, verticalAspect)

    xVect = [math.cos(facingAngle - math.pi / 2), -math.sin(facingAngle - math.pi / 2)]
    yVect = [math.cos(facingAngle), -math.sin(facingAngle)]
    # This is probably good enough
    # Find how much a vector orthogonal to the surface agrees with your relative x vector, and adjust from that
    angleAdjustment = xVect[0] * lieY[0] + xVect[1] * lieY[2]
    angleAdjustment *= -20
    print("Angle adjustment: " + str(angleAdjustment) + "\n")

    revisedWindX = xVect[0] * windVect[0] + xVect[1] * windVect[1]
    revisedWindY = yVect[0] * windVect[0] + yVect[1] * windVect[1]
    revisedWindX *= 9 / 24 / 21
    revisedWindY *= 9 / 24 / 21
    
    unitsPerYard = 24 / 1.75
    dist = math.sqrt((ballPos[0] - holePos[0]) ** 2 + (ballPos[2] - holePos[2]) ** 2)
    # Again, probably good enough
    dist -= (holePos[1] - ballPos[1])
    clubPower = powerLevels[club][shotType]
    surfacePenalty = (powerRanges[surfaceType][0] + powerRanges[surfaceType][1]) / 200
    distanceRatio =  dist / (clubPower * unitsPerYard * surfacePenalty)
    # return [revisedWindX, revisedWindY, distanceRatio, (ballPos[1] - holePos[1]) / 200, club / 12], [(rotation + 30) / 60, power / 31, (contactX + 1) / 2, (contactY + 1) / 2], raining
    
    # horizontalAspect = angles[club][0]
    # verticalAspect = angles[club][1]
    
    # print("Draw mod: " + str(elevationChangeMod) + "\n")

    # return [distanceRatio, dist, windX, windY, angles[club][0], angles[club][1], angles[club][2]], [(rotation + 7) / 14, power / 31], club
    return [distanceRatio, (dist / unitsPerYard) / 250, revisedWindX, revisedWindY, angles[club][0], angles[club][1], angles[club][2]], angleAdjustment
    # return [distanceRatio, revisedWindX, revisedWindY, horizontalAspect, verticalAspect, angles[club][2]], angleAdjustment

model = torch.load('./model/modelDrives.pt')

def runModel(x):
    input, angleAdjustment = parseLine(x)
    print(input)
    pred_y = model(torch.FloatTensor(input))
    rotation = round(pred_y[0].item() * 14 - 7 + angleAdjustment)
    power = round(pred_y[1].item() * 31)
    # contactX = round((pred_y2[0].item() * 2 - 1) * 0.8)
    # contactY = round((pred_y2[1].item() * 2 - 1))

    # rotation = 0
    # power = round(pred_y[0].item() * 31)
    contactX = 0
    contactY = 0

    print("\"%d,%d,%d,%d\""%(rotation, power, contactX, contactY) + "\n")
    f = open("./input/response.txt", "w+")
    f.write(("%d,%d,%d,%d\n"%(rotation, power, contactX, contactY)) + x)
    f.write(x)
    f.close()

    # clear file
    f = open("./input/stroke.txt", "w+")
    f.close()

    # system("perl stroke.pl \"%d,%d,%d,%d\""%(rotation, power, contactX, contactY))

while(1):
    f = open("./input/stroke.txt", "r+")
    line = f.readline()
    f.close()
    if line != "":
        runModel(line)
    time.sleep(0.2)