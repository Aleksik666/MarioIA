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

stuck_timer = 0
max_stuck_time = 120

function randomInput()
    local outputs = {}

    if math.random() < jump_weight then
        outputs["P1 A"] = math.random() < 0.5  -- Randomize jump height
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
    oldY = marioY
    stuck_timer = 0
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
        
        if memory.readbyte(0x000E) == 0x06 or memory.readbyte(0x000D) == 0x00 then  -- Detect death properly
            break
        end
        
        if oldX == marioX and oldY == marioY then
            stuck_timer = stuck_timer + 1
        else
            stuck_timer = 0
        end
        
        if stuck_timer > max_stuck_time then
            jump_weight = 0.5  -- Allow bigger jumps
            right_weight = 1.0
            left_weight = 0.0
            turbo_weight = 1.0
            stuck_timer = 0
        end
        
        oldX = marioX
        oldY = marioY
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
