import math
import sys
from os import system
import torch
import torch.nn as nn
import torch.nn.functional as F
import matplotlib.pyplot as plt

dataX = []
dataY = []

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

def parseLine(line, line2):
    line = line.replace('\n', '')
    vals = line.split(', ')
    numVals = len(vals)
    vals2 = line2.split(', ')
    vals2 = [float(x) for x in vals2]

    distanceRatio = float(vals[0])
    club = int(vals[1])
    windX = float(vals[2])
    windY = float(vals[3])
    rotation = float(vals[4])
    power = float(vals[5])

    initialPos = vals2[8:11]
    finalPos = vals2[12:15]
    deltaPos = [finalPos[i] - initialPos[i] for i in range(3)]
    dist = math.sqrt(deltaPos[0] * deltaPos[0] + deltaPos[1] * deltaPos[1] + deltaPos[2] * deltaPos[2])
    unitsPerYard = 24 / 1.75

    windX /= 21
    windY /= 21
    rotation *= 271 / 3.1415 / 2
    
    # return [distanceRatio, windX, windY, angles[club][0], angles[club][1], angles[club][2]], [(rotation + 7) / 14, power / 31], club
    return [distanceRatio, (dist / unitsPerYard) / 250, windX, windY, angles[club][0], angles[club][1], angles[club][2]], [(rotation + 7) / 14, power / 31], club
    

f = open('./data/drives.csv', "r")
lines = f.readlines()
lines = lines[350:]
f.close()

f = open('./data/rawdrives.csv', "r")
lines2 = f.readlines()
lines2 = lines2[350:]
f.close()

clubs = []

x = []
y = []

removedCount = [0] * 13
includedCount = [0] * 13
for i, line in enumerate(lines):
    inputs, expected, club = parseLine(line, lines2[i])
    # rotationSign = 1
    # if(expected[0] < 0.5):
    #     rotationSign = -1
    
    # windSign = 1
    # if(inputs[2] < 0):
    #     windSign = -1

    # Remove weird data (physics bugs?)
    # if(((expected[0] > 0.7 or expected[0] < 0.3) or abs(inputs[2]) > 0.3) and windSign != rotationSign):
    #     removedCount[club] += 1
    #     # print(abs(inputs[1] - (expected[0] * 2 - 1)))
    #     continue
    if(expected[0] > 1 or expected[0] < 0):
        removedCount[club] += 1
        # print(abs(inputs[1] - (expected[0] * 2 - 1)))
        continue
    includedCount[club] += 1
    x.append(inputs[2])
    y.append(expected[0])
    clubs.append(club)
    dataX.append(inputs)
    dataY.append(expected)
    print(inputs)
    # print(expected)

s = [0.04 for n in range(len(x))]
# plt.scatter(x, y, s=s)
# plt.show()

# minItem = min(includedCount)
# i = 0
# while(i < len(dataX)):
#     if(includedCount[clubs[i]] > minItem):
#         dataX.pop(i)
#         dataY.pop(i)
#         clubs.pop(i)
#         includedCount[clubs[i]] -= 1
#         i -= 1
#     i += 1

print(removedCount)
print(includedCount)
print(len(dataX))

n_input, n_hidden1, n_hidden2, n_hidden3, n_out, batch_size, learning_rate = 7, 6, 6, 4, 2, 64, 0.01

# model = nn.Sequential(nn.Linear(n_input, n_hidden1),nn.ReLU(),nn.Linear(n_hidden1, n_hidden2),nn.ReLU(),nn.Linear(n_hidden2, n_out),nn.ReLU())
model = nn.Sequential(nn.Linear(n_input, n_hidden1),nn.ReLU(),nn.Linear(n_hidden1, n_out),nn.ReLU())

loss_function = nn.MSELoss()
optimizer = torch.optim.SGD(model.parameters(), lr=learning_rate)

losses = []

dataX = torch.FloatTensor(dataX)
dataY = torch.FloatTensor(dataY)

i = 0

# for epoch in range(250000):
while 1:
    i += 1
    # if i % 10000 == 0:
        # print(model(torch.FloatTensor([0.6494559008855347, 0.7069703671642853, 0.8193986465439955, -0.1302001953125, -0.068587815670472, -0.000171319160105707])))
    pred_y = model(dataX)
    loss = loss_function(pred_y, dataY)
    losses.append(loss.item())
    if i % 10000 == 0:
        print(loss.item())
    
    if i % 50000 == 0:
        torch.save(model, './model/modelDrives.pt')

    model.zero_grad()
    loss.backward()

    optimizer.step()

plt.plot(losses)
plt.ylabel('loss')
plt.xlabel('epoch')
plt.title("Learning rate %f"%(learning_rate))
plt.show()

torch.save(model, './model/modelDrives.pt')
print("saved")