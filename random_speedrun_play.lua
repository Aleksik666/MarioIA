Filename = "SMB1-1.state"

ButtonNames = {
    "A",
    "B",
    "Down",
    "Left",
    "Right",
}

best_time = math.huge

function getPositions()
    marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
    marioY = memory.readbyte(0x03B8) + 16
    screenX = memory.readbyte(0x03AD)
    screenY = memory.readbyte(0x03B8)
end

jump_weight = 0.8
right_weight = 0.95
left_weight = 0.05

down_weight = 0.05

turbo_weight = 0.8

function randomInput()
    local outputs = {}

    if math.random() < jump_weight then
        outputs["P1 A"] = true
    end

    if math.random() < right_weight then
        outputs["P1 Right"] = true
    end

    if math.random() < left_weight then
        outputs["P1 Left"] = true
    end

    if math.random() < turbo_weight then
        outputs["P1 B"] = true
    end

    return outputs
end

function clearJoypad()
    controller = {}
    for b = 1,#ButtonNames do
        controller["P1 " .. ButtonNames[b]] = false
    end
    joypad.set(controller)
end

try = 1

function doRun()
    savestate.load(Filename)
    getPositions()

    oldX = marioX
    stuck = 0
    frame_count = 0

    if mainMoves ~= nil then    
        for a = 1, #mainMoves do
            clearJoypad()
            joypad.set(mainMoves[a])
            emu.frameadvance()
            frame_count = frame_count + 1
        end
    end
    
    subMoves = {}
    
    while true do
        getPositions()
        clearJoypad()
        controller = randomInput()
        joypad.set(controller)
        table.insert(subMoves, controller)
        
        if memory.readbyte(0x000E) == 0x06 then
            break
        end
        
        if oldX == marioX then
            stuck = stuck + 1
        else
            stuck = 0
        end
        
        if stuck > 200 then
            right_weight = math.min(right_weight + 0.1, 1.0)
            stuck = 0
        end
        
        oldX = marioX
        emu.frameadvance()
        frame_count = frame_count + 1
    end
    
    if frame_count < best_time then
        best_time = frame_count
        mainMoves = subMoves
    end
    
    try = try + 1
    doRun()
end

mainMoves = nil
doRun()
