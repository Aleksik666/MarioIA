Filename = "SMB1-1.state"

ButtonNames = {
    "A",
    "B",
    "Down",
    "Left",
    "Right",
}

function getPositions()
    marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
    marioY = memory.readbyte(0x03B8) + 16

    screenX = memory.readbyte(0x03AD)
    screenY = memory.readbyte(0x03B8)
end

jump_weight = 0.9
base_left_weight = 0.15
left_weight = 0.15
right_weight = 0.9
down_weight = 0.1
run_weight = 1.0

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
    
    outputs["P1 B"] = true
    
    if controller["P1 Left"] and controller["P1 Right"] then
        controller["P1 Left"] = true
        controller["P1 Right"] = false
    end
    
    if left_weight > base_left_weight then
        left_weight = left_weight - 0.01
    end
    
    return outputs
end

function clearJoypad()
    controller = {}
    for b = 1, #ButtonNames do
        controller["P1 " .. ButtonNames[b]] = false
    end
    joypad.set(controller)
end

try = 1
frame_count = 0
best_time = math.huge
stuck_frames = 0

function doRun()
    savestate.load(Filename)
    
    getPositions()
    
    oldX = marioX
    stuck_frames = 0
    start_time = os.time()
    
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
        if mainMoves == nil then
            mainMoves = {}
        end
        
        getPositions()
        
        clearJoypad()
        
        controller = randomInput()
        
        joypad.set(controller)
        table.insert(subMoves, controller)

        if oldX == marioX then
            stuck_frames = stuck_frames + 1
        else
            stuck_frames = 0
        end
        
        if stuck_frames > 300 then
            left_weight = 0.6
            right_weight = 1.0
            stuck_frames = 0
        end
        
        oldX = marioX
        
        emu.frameadvance()
        frame_count = frame_count + 1

        if memory.readbyte(0x000E) == 0x06 then
            end_time = os.time()
            current_time = end_time - start_time
            
            if current_time < best_time then
                best_time = current_time
                inputBytes = ""
                for m = 1, #subMoves do
                    local controller = subMoves[m]
                    if controller["P1 Left"] then
                        inputBytes = inputBytes .. 1
                    else
                        inputBytes = inputBytes .. 0
                    end
                    
                    if controller["P1 Right"] then
                        inputBytes = inputBytes .. 1
                    else
                        inputBytes = inputBytes .. 0
                    end
                    
                    if controller["P1 A"] then
                        inputBytes = inputBytes .. 1
                    else
                        inputBytes = inputBytes .. 0
                    end
                    
                    if controller["P1 B"] then
                        inputBytes = inputBytes .. 1
                    else
                        inputBytes = inputBytes .. 0
                    end
                end
                
                file = io.open("best_moves.txt", "w")
                file:write(inputBytes)
                file:close()
            end
            break
        end
    end
    
    moveCount = #subMoves - 300
    
    if moveCount > 0 then
        for m = 1, moveCount do
            table.insert(mainMoves, subMoves[m])
        end
    end
    
    inputBytes = ""
    
    for m = 1, #mainMoves do
        local controller = mainMoves[m]
        if controller["P1 Left"] then
            inputBytes = inputBytes .. 1
        else
            inputBytes = inputBytes .. 0
        end
        
        if controller["P1 Right"] then
            inputBytes = inputBytes .. 1
        else
            inputBytes = inputBytes .. 0
        end
        
        if controller["P1 A"] then
            inputBytes = inputBytes .. 1
        else
            inputBytes = inputBytes .. 0
        end
        
        if controller["P1 B"] then
            inputBytes = inputBytes .. 1
        else
            inputBytes = inputBytes .. 0
        end
    end
    
    file = io.open(marioX .. "_" .. frame_count .. "_moves.txt", "w")
    file:write(inputBytes)
    
    try = try + 1
    
    doRun()
end

mainMoves = nil

doRun()
