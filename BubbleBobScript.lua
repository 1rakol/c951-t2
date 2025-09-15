sim = require'sim'
simUI = require'simUI'

function sysCall_init()
         
    -- This is executed exactly once, the first time this script is executed
    
    -- Setup sensors
    
    bubbleRobBase = sim.getObject('..')
    leftMotor = sim.getObject("../leftMotor")
    rightMotor = sim.getObject("../rightMotor")
    forwardSensor = sim.getObject("../forwardSensor")
    leftSensor = sim.getObject("../leftSensor")
    humanSensor = sim.getObject("../humanSensor")
      
    -- Setup rotation for human sensor
    
    rotationAxis = {0, 0, 1}
    axisPosition = {0, 0, 0}
    rotationAngle = math.rad(10)  

    -- Setup humans
 
    billTheHuman = sim.getObject("/Bill/Bill")
    jakeTheHuman = sim.getObject("/Jake/Jake")
    samTheHuman = sim.getObject("/Sam/Sam")
   
    humanCollection = sim.createCollection(0)
    sim.addItemToCollection(humanCollection, sim.handle_tree, billTheHuman, 0)
    sim.addItemToCollection(humanCollection, sim.handle_tree, jakeTheHuman, 0)
    sim.addItemToCollection(humanCollection, sim.handle_tree, samTheHuman, 0)
    sim.setObjectInt32Param(humanSensor, sim.proxintparam_entity_to_detect, humanCollection)
    
    -- Setup bubbleRob
    
    minMaxSpeed = {50 * math.pi / 180, 500 * math.pi / 180} -- Min and max speeds for each motor
    robotCollection = sim.createCollection(0)
    sim.addItemToCollection(robotCollection, sim.handle_tree, bubbleRobBase, 0)
    distanceSegment = sim.addDrawingObject(sim.drawing_lines, 4, 0, -1, 1, {0, 1, 0})
    robotTrace = sim.addDrawingObject(sim.drawing_linestrip + sim.drawing_cyclic, 2, 0, -1, 1200, {1, 1, 0}, nil, nil, {1, 1, 0})
    
    -- Create the custom UI:
    
    xml = '<ui title="'..sim.getObjectAlias(bubbleRobBase,1)..' speed" closeable="false" resizable="false" activate="false">'..[[
                <hslider minimum="0" maximum="100" on-change="speedChange_callback" id="1"/>
            <label text="" style="* {margin-left: 300px;}"/>
        </ui>
        ]]
    ui = simUI.create(xml)
    speed = (minMaxSpeed[1] + minMaxSpeed[2]) * 0.5
    simUI.setSliderValue(ui, 1, 100 * (speed - minMaxSpeed[1]) / (minMaxSpeed[2] - minMaxSpeed[1]))
 
    -- Global state variables
    
    foundWall = 0
    foundBill = 0
    foundJake = 0
    foundSam = 0
    
end

function sysCall_sensing()

    -- Distance indicator

    local result, distData = sim.checkDistance(robotCollection, sim.handle_all)
    
    if result > 0 then
        sim.addDrawingObjectItem(distanceSegment, nil)
        sim.addDrawingObjectItem(distanceSegment, distData)
    end
    
    -- Trailing path
    
    local p = sim.getObjectPosition(bubbleRobBase)
    sim.addDrawingObjectItem(robotTrace, p)
    
end 

function speedChange_callback(ui, id, newVal)

    speed = minMaxSpeed[1] + (minMaxSpeed[2] - minMaxSpeed[1]) * newVal / 100
    
end

function sysCall_actuation() 

    fwdResult = sim.readProximitySensor(forwardSensor) -- Read the proximity sensor
    lftResult = sim.readProximitySensor(leftSensor) -- Read the proximity sensor
    
    if (fwdResult == 1) then
    
        foundWall = 1
    
        -- Drift to the right
        sim.setJointTargetVelocity(rightMotor, -speed * 2)
        sim.setJointTargetVelocity(leftMotor, speed * 2)

    else
        if (lftResult == 1) then
        
            foundWall = 1
        
            -- Move forward
            sim.setJointTargetVelocity(rightMotor, speed)
            sim.setJointTargetVelocity(leftMotor, speed)
        
        else
        
            if (foundWall == 1) then
                -- Turn left
                sim.setJointTargetVelocity(rightMotor, speed * 2)
                sim.setJointTargetVelocity(leftMotor, speed / 4)
            end
       
        end

    end
    
    -- Sensor rotation
    
    local currentPose = sim.getObjectPose(humanSensor, sim.handle_parent)
    local newPose = sim.rotateAroundAxis(currentPose, rotationAxis, axisPosition, rotationAngle)
    sim.setObjectPose(humanSensor, sim.handle_parent, newPose)
    
    res, dist, point, obj, n = sim.readProximitySensor(humanSensor)

    if (foundBill == 0 and res == 1 and sim.getObjectName(obj) == "Bill") then
        print("Found Bill...")
        foundBill = 1
    end
    
    if (foundJake == 0 and res == 1 and sim.getObjectName(obj) == "Jake0") then
        print("Found Jake...")
        foundJake = 1
    end
    
    if (foundSam == 0 and res == 1 and sim.getObjectName(obj) == "Bill_body") then
        print("Found Sam...")
        foundSam = 1
    end
    
end

function sysCall_cleanup()

    simUI.destroy(ui)
    
end 
