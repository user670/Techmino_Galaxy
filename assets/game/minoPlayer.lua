local gc=love.graphics

local max,min=math.max,math.min
local int,ceil=math.floor,math.ceil
local abs=math.abs
local ins,rem=table.insert,table.remove

local sign,expApproach=MATH.sign,MATH.expApproach
local inst=SFX.playSample

local MP={}

--------------------------------------------------------------
-- Actions
local actions={}
actions.moveLeft={
    press=function(P)
        P.moveDir=-1
        P.moveCharge=0
        if P.hand then
            if P:moveLeft() then
                P:playSound('move')
                if P.handY==P.ghostY then
                    P:playSound('touch')
                end
            end
        else
            P.keyBuffer.move='L'
        end
    end,
    release=function(P)
        if P.keyBuffer.move=='L' then P.keyBuffer.move=false end
    end
}
actions.moveRight={
    press=function(P)
        P.moveDir=1
        P.moveCharge=0
        if P.hand then
            if P:moveRight() then
                P:playSound('move')
                if P.handY==P.ghostY then
                    P:playSound('touch')
                end
            end
        else
            P.keyBuffer.move='R'
        end
    end,
    release=function(P)
        if P.keyBuffer.move=='R' then P.keyBuffer.move=false end
    end
}
actions.rotateCW={
    press=function(P)
        if P.hand then
            P:rotate('R')
        else
            P.keyBuffer.rotate='R'
        end
    end,
    release=function(P)
        if P.keyBuffer.rotate=='R' then P.keyBuffer.rotate=false end
    end
}
actions.rotateCCW={
    press=function(P)
        if P.hand then
            P:rotate('L')
        else
            P.keyBuffer.rotate='L'
        end
    end,
    release=function(P)
        if P.keyBuffer.rotate=='L' then P.keyBuffer.rotate=false end
    end
}
actions.rotate180={
    press=function(P)
        if P.hand then
            P:rotate('F')
        else
            P.keyBuffer.rotate='F'
        end
    end,
    release=function(P)
        if P.keyBuffer.rotate=='F' then P.keyBuffer.rotate=false end
    end
}
function actions.softDrop(P)
    P.downCharge=0
    if not P.hand then return end
    if P.handY>P.ghostY then
        P.handY=P.handY-1
        P:freshDelay('drop')
        if P.handY==P.ghostY then
            P:playSound('touch')
        end
    end
end
function actions.sonicDrop(P)
    if not P.hand then return end
    if P.handY>P.ghostY then
        P.handY=P.ghostY
        P:freshDelay('drop')
        if P.handY==P.ghostY then
            P:playSound('touch')
        end
    end
end
actions.hardDrop={
    press=function(P)
        if P.hand then
            P:minoDropped()
        else
            P.keyBuffer.hardDrop=true
        end
    end,
    release=function(P)
        P.keyBuffer.hardDrop=false
    end
}
actions.holdPiece={
    press=function(P)
        if P.hand then
            P:hold()
        else
            P.keyBuffer.hold=true
        end
    end,
    release=function(P)
        P.keyBuffer.hold=false
    end
}

actions.function1=NULL
actions.function2=NULL
actions.function3=NULL
actions.function4=NULL

actions.target1=NULL
actions.target2=NULL
actions.target3=NULL
actions.target4=NULL

function actions.sonicLeft(P)
    local moved
    while P.hand and not P:ifoverlap(P.hand.matrix,P.handX-1,P.handY) do
        moved=true
        P.handX=P.handX-1
        P:freshGhost()
    end
    if P.handY==P.ghostY then
        P:playSound('touch')
    end
    return moved
end
function actions.sonicRight(P)
    local moved
    while P.hand and not P:ifoverlap(P.hand.matrix,P.handX+1,P.handY) do
        moved=true
        P.handX=P.handX+1
        P:freshGhost()
    end
    if P.handY==P.ghostY then
        P:playSound('touch')
    end
    return moved
end
function actions.dropLeft(P)
    actions.sonicLeft(P)
    actions.hardDrop(P)
end
function actions.dropRight(P)
    actions.sonicRight(P)
    actions.hardDrop(P)
end
function actions.zangiLeft(P)
    actions.sonicLeft(P)
    actions.sonicDrop(P)
    actions.sonicRight(P)
    actions.hardDrop(P)
end
function actions.zangiRight(P)
    actions.sonicRight(P)
    actions.sonicDrop(P)
    actions.sonicLeft(P)
    actions.hardDrop(P)
end

local function _getActionObj(a)
    if type(a)=='string' then
        return actions[a]
    elseif type(a)=='function' then
        return setmetatable({
            press=a,
            release=NULL,
        },{__call=function(self,P)
            self.press(P)
        end})
    elseif type(a)=='table' then
        assert(type(a.press)=='function' and type(a.release)=='function',"wtf why action do not contain func press() & func release()")
        return setmetatable({
            press=a.press,
            release=a.release,
        },{__call=function(self,P)
            self.press(P)
            self.release(P)
        end})
    else
        error("Invalid action: should be function or table contain 'press' and 'release' fields")
    end
end
for k,v in next,actions do actions[k]=_getActionObj(v) end
local actionPacks={
    classic={
        'moveLeft',
        'moveRight',
        'rotateCW',
        'rotateCCW',
        'softDrop',
    },
    modern={
        'dropLeft',
        'dropRight',
        'zangiLeft',
        'zangiRight',
        'moveLeft',
        'moveRight',
        'rotateCW',
        'rotateCCW',
        'rotate180',
        'softDrop',
        'sonicDrop',
        'hardDrop',
        'holdPiece',
    },
}
--------------------------------------------------------------
-- Effects
function MP:shakeBoard(args)
    if args:sArg('-down') then
        self.pos.vy=self.pos.vy+.2*self.settings.shakeness
    elseif args:sArg('-right') then
        self.pos.dx=self.pos.dx+.1*self.settings.shakeness
    elseif args:sArg('-left') then
        self.pos.dx=self.pos.dx-.1*self.settings.shakeness
    elseif args:sArg('-cw') then
        self.pos.va=self.pos.va+.002*self.settings.shakeness
    elseif args:sArg('-ccw') then
        self.pos.va=self.pos.va-.002*self.settings.shakeness
    elseif args:sArg('-180') then
        self.pos.vy=self.pos.vy+.1*self.settings.shakeness
        self.pos.va=self.pos.va+((self.handX+#self.hand.matrix[1]/2-1)/self.settings.fieldW-.5)*.0026
    end
end
--------------------------------------------------------------
-- Game methods
local defaultSoundFunc={
    countDown=function(num)
        if num==0 then-- 6, 3+6+6
            inst('bass',.8,'A3')
            inst('lead',.9,'A4','E5','A5')
        elseif num==1 then-- 5, 3+7
            inst('bass',.9,'G3')
            inst('lead',.9,'B4','E5')
        elseif num==2 then-- 4, 6+2
            inst('bass','F3')
            inst('lead',.8,'A4','D5')
        elseif num==3 then-- 6+6
            inst('bass',.9,'A3','E4')
            inst('lead',.8,'A4')
        elseif num==4 then-- 5+7, 5
            inst('bass',.9,'G3','B3')
            inst('lead',.6,'G4')
        elseif num==5 then-- 4+6, 4
            inst('bass',.8,'F3','A3')
            inst('lead',.3,'F4')
        elseif num<=10 then
            inst('bass',2.2-num/5,'A2','E3')
        end
    end,
    move=function()
        -- TODO
    end,
    touch=function()
        SFX.play('touch')
    end,
    rotate=function(locked)
        if locked then
            SFX.play('rotate_locked')
        else
            SFX.play('rotate')
        end
    end,
    drop=function()
        SFX.play('drop')
    end,
    lock=function()
        SFX.play('lock')
    end,
    combo=function(clearHis)
        local cmb=clearHis.combo
        if cmb<=5 then
            if     cmb==1 then  inst('bass','A2')
            elseif cmb==2 then  inst('bass','C3')
            elseif cmb==3 then  inst('bass','D3')
            elseif cmb==4 then  inst('bass','E3')
            elseif cmb==5 then  inst('bass','G3')
            end
        elseif cmb<=10 then
            if     cmb==6 then  inst('bass',.90,'A3') inst('lead',.20,'A2')
            elseif cmb==7 then  inst('bass',.75,'C4') inst('lead',.40,'C3')
            elseif cmb==8 then  inst('bass',.60,'D4') inst('lead',.60,'D3')
            elseif cmb==9 then  inst('bass',.40,'E4') inst('lead',.75,'E3')
            elseif cmb==10 then inst('bass',.20,'G4') inst('lead',.90,'G3')
            end
        elseif cmb<=15 then
            if     cmb==11 then inst('bass',.20,'A4') inst('lead','A3')
            elseif cmb==12 then inst('bass',.40,'A4') inst('lead','C4')
            elseif cmb==13 then inst('bass',.60,'A4') inst('lead','D4')
            elseif cmb==14 then inst('bass',.75,'A4') inst('lead','E4')
            elseif cmb==15 then inst('bass',.90,'A4') inst('lead','G4')
            end
        elseif cmb<=20 then
            if     cmb==16 then inst('bass',.90,'A4') inst('bass',.90,'E5') inst('lead','A4')
            elseif cmb==17 then inst('bass',.85,'A4') inst('bass',.85,'E5') inst('lead','C5')
            elseif cmb==18 then inst('bass',.80,'A4') inst('bass',.80,'E5') inst('lead','D5')
            elseif cmb==19 then inst('bass',.75,'A4') inst('bass',.75,'E5') inst('lead','E5')
            elseif cmb==20 then inst('bass',.70,'A4') inst('bass',.70,'E5') inst('lead','G5')
            end
        else
            inst('bass',.626,'A4')
            local phase=(cmb-20)%12
            if     phase==1  then inst('lead',1-(12/12)^2,46+0 ) inst('lead',1-(1/12)^2, 58+0 )
            elseif phase==2  then inst('lead',1-(11/12)^2,46+1 ) inst('lead',1-(2/12)^2, 58+1 )
            elseif phase==3  then inst('lead',1-(10/12)^2,46+2 ) inst('lead',1-(3/12)^2, 58+2 )
            elseif phase==4  then inst('lead',1-(9/12)^2, 46+3 ) inst('lead',1-(4/12)^2, 58+3 )
            elseif phase==5  then inst('lead',1-(8/12)^2, 46+4 ) inst('lead',1-(5/12)^2, 58+4 )
            elseif phase==6  then inst('lead',1-(7/12)^2, 46+5 ) inst('lead',1-(6/12)^2, 58+5 )
            elseif phase==7  then inst('lead',1-(6/12)^2, 46+6 ) inst('lead',1-(7/12)^2, 58+6 )
            elseif phase==8  then inst('lead',1-(5/12)^2, 46+7 ) inst('lead',1-(8/12)^2, 58+7 )
            elseif phase==9  then inst('lead',1-(4/12)^2, 46+8 ) inst('lead',1-(9/12)^2, 58+8 )
            elseif phase==10 then inst('lead',1-(3/12)^2, 46+9 ) inst('lead',1-(10/12)^2,58+9 )
            elseif phase==11 then inst('lead',1-(2/12)^2, 46+10) inst('lead',1-(11/12)^2,58+10)
            elseif phase==0  then inst('lead',1-(1/12)^2, 46+11) inst('lead',1-(12/12)^2,58+11)
            end
        end
    end,
    clear=function(clearHis)
        local l=clearHis.line
        SFX.play(
            l==1 and 'clear_1' or
            l==2 and 'clear_2' or
            l==3 and 'clear_3' or
            l==4 and 'clear_4' or
            'clear_5'
        )
        if l>=3 then
            BGM.set('all','highgain',1/l,0)
            BGM.set('all','highgain',1,min((l)^1.5/5,2.6))
        end
    end,
    win=function()
        SFX.play('beep1')
    end,
    lose=function()
        SFX.play('beep2')
    end,
}
function MP:playSound(event,...)
    if not self.sound then return end
    if self.settings[event] then
        self.settings[event](...)
    elseif defaultSoundFunc[event] then
        defaultSoundFunc[event](...)
    end
end

function MP:triggerEvent(name,...)
    local L=self.event[name]
    if L then
        for i=1,#L do L[i](self,...) end
    end
end
function MP:restoreMinoState(mino)-- Restore a mino object's state (only inside, like shape, name, direction)
    if not mino._origin then return end
    for k,v in next,mino._origin do
        mino[k]=v
    end
    return mino
end
function MP:resetPos()-- Move hand piece to the normal spawn position
    self.handX=int(self.field:getWidth()/2-#self.hand.matrix[1]/2+1)
    self.handY=self.settings.spawnH+1
    self.minY=self.handY
    if self.keyBuffer.move then-- IMS
        if self.keyBuffer.move=='L' then
            self:moveLeft()
        elseif self.keyBuffer.move=='R' then
            self:moveRight()
        end
        self.keyBuffer.move=false
    end
    if self.keyBuffer.rotate then-- IRS
        local r=self.keyBuffer.rotate
        self.keyBuffer.rotate=false
        self:rotate(r)
    end
end
function MP:checkHand()-- Reset hand position and check death
    if self:ifoverlap(self.hand.matrix,self.handX,self.handY) then
        -- Struggle IMS
        if self.moveDir==-1 then
            self:moveLeft()
        elseif self.moveDir==1 then
            self:moveRight()
        end

        if self:ifoverlap(self.hand.matrix,self.handX,self.handY) then
            self:lock()
            self:gameover('WA')
            return
        end
    end
    self:freshGhost()
    self:freshDelay('spawn')
end
function MP:freshGhost()
    if self.hand then
        self.ghostY=min(self.field:getHeight()+1,self.handY)

        -- Move ghost to bottom
        while not self:ifoverlap(self.hand.matrix,self.handX,self.ghostY-1) do
            self.ghostY=self.ghostY-1
        end

        if (self.settings.dropDelay==0 or self.downCharge and self.settings.sdarr==0) and self.ghostY<self.handY then-- if (temp) 20G on
            self.handY=self.ghostY
            self:shakeBoard('-down')
            self:freshDelay('drop')
        else
            self:freshDelay('move')
        end
    end
end
function MP:freshDelay(reason)-- reason can be 'move' or 'drop' or 'spawn'
    if self.handY<self.minY then self.minY=self.handY end
    if self.settings.freshCondition=='any' then
        if reason=='move' then
            if self.lockTimer<self.settings.lockDelay then
                self.lockTimer=self.settings.lockDelay
                -- TODO: self.freshTime-=1
            end
        elseif reason=='drop' or reason=='spawn' then
            self.dropTimer=self.settings.dropDelay
            self.lockTimer=self.settings.lockDelay
        end
    elseif self.settings.freshCondition=='fall' then
        if reason=='drop' then
            self.dropTimer=self.settings.dropDelay
            if self.lockTimer<self.settings.lockDelay then
                self.lockTimer=self.settings.lockDelay
                -- TODO: self.freshTime-=1
            end
        elseif reason=='spawn' then
            self.dropTimer=self.settings.dropDelay
            self.lockTimer=self.settings.lockDelay
        end
    elseif self.settings.freshCondition=='never' then
        if reason=='spawn' then
            self.dropTimer=self.settings.dropDelay
            self.lockTimer=self.settings.lockDelay
        end
    else
        error("wtf why settings.freshCondition is "..tostring(self.settings.freshCondition))
    end
end
function MP:popNext()
    if self.nextQueue[1] then-- Most cases there is pieces in next queue
        self.hand=rem(self.nextQueue,1)
        self.genNext()
        self.holdChance=min(self.holdChance+1,self.settings.holdCount)
    elseif self.holdQueue[1] then-- If no nexts, force using hold
        ins(self.nextQueue,rem(self.holdQueue,1))
        self:popNext()
    else-- If no piece to use, both Next and Hold queue are empty, game over
        self:gameover('ILE')
        return
    end

    if self.keyBuffer.hold then-- IHS
        self.keyBuffer.hold=false
        self:hold()
    else
        self:resetPos()
    end

    self:checkHand()

    if self.keyBuffer.hardDrop then-- IHdS
        self.keyBuffer.hardDrop=false
        self:minoDropped()
    end

    self:triggerEvent('afterSpawn')
end
function MP:getMino(shapeID)
    local shape=TABLE.shift(Minos[shapeID].shape)
    for y=1,#shape do for x=1,#shape[1] do
        if shape[y][x] then
            shape[y][x]={color=defaultMinoColor[shapeID]}-- Should be player's color setting
        end
    end end
    self.minoCount=self.minoCount+1
    local mino={
        id=self.minoCount,
        shape=shapeID,
        direction=0,
        name=Minos[shapeID].name,
        matrix=shape,
    }
    mino._origin=TABLE.copy(mino,0)
    ins(self.nextQueue,mino)
end

function MP:ifoverlap(CB,cx,cy)
    local F=self.field

    -- Must in wall
    if cx<=0 or cx+#CB[1]-1>F:getWidth() or cy<=0 then return true end

    -- Must in air
    if cy>F:getHeight() then return false end

    -- Check field
    for y=1,#CB do for x=1,#CB[1] do
        if CB[y][x] and F:getCell(cx+x-1,cy+y-1) then
            return true
        end
    end end

    -- No collision
    return false
end
function MP:moveLeft()
    if not self:ifoverlap(self.hand.matrix,self.handX-1,self.handY) then
        self.handX=self.handX-1
        self:freshGhost()
        return true
    end
end
function MP:moveRight()
    if not self:ifoverlap(self.hand.matrix,self.handX+1,self.handY) then
        self.handX=self.handX+1
        self:freshGhost()
        return true
    end
end
function MP:rotate(dir)
    if not self.hand then return end
    local minoData=RotationSys[self.settings.rotSys][self.hand.shape]
    if dir~='R' and dir~='L' and dir~='F' then error("wtf why dir isn't R/L/F ("..tostring(dir)..")") end

    if minoData.rotate then-- Custom rotate function
        minoData.rotate(self,dir)
    else-- Normal rotate procedure
        local preState=minoData[self.hand.direction]
        if preState then
            -- Rotate matrix
            local kick=preState[dir]
            if not kick then return end-- This RS doesn't define this rotation

            local cb=self.hand.matrix
            local icb=TABLE.rotate(cb,dir)
            local baseX,baseY

            local afterState=minoData[kick.target]
            if kick.base then
                baseX=kick.base[1]
                baseY=kick.base[2]
            elseif preState.center and afterState.center then
                baseX=preState.center[1]-afterState.center[1]
                baseY=preState.center[2]-afterState.center[2]
            else
                error('cannot get baseX/Y')
            end

            for n=1,#kick.test do
                local ix,iy=self.handX+baseX+kick.test[n][1],self.handY+baseY+kick.test[n][2]
                if not self:ifoverlap(icb,ix,iy) then
                    self.hand.matrix=icb
                    self.handX,self.handY=ix,iy
                    self.hand.direction=kick.target
                    self:freshGhost()
                    if self:ifoverlap(icb,ix,iy+1)and self:ifoverlap(icb,ix-1,iy)and self:ifoverlap(icb,ix+1,iy) then
                        self:shakeBoard(dir=='L' and '-ccw' or dir=='R' and '-cw' or '-180')
                        self:playSound('rotate',true)
                    else
                        self:playSound('rotate')
                    end
                    if self.handY==self.ghostY then
                        self:playSound('touch')
                    end
                    return
                end
            end
            self:freshDelay('move')
            self:playSound('rotate_failed')
        else
            error("wtf why no state in minoData")
        end
    end
end
function MP:hold()
    if self.holdChance<=0 then return end
    local mode=self.settings.holdMode
    if mode=='hold' then
        self:hold_hold()
    elseif mode=='swap' then
        self:hold_swap()
    elseif mode=='float' then
        self:hold_float()
    else
        error("wtf why hold mode is "..tostring(mode))
    end
    self.holdChance=self.holdChance-1
end
function MP:hold_hold()
    if not self.settings.holdKeepState then
        self.hand=self:restoreMinoState(self.hand)
    end
    if self.holdQueue[1] then
        self.hand,self.holdQueue[1]=self.holdQueue[1],self.hand
        self:resetPos()
        self:checkHand()
    else
        self.holdQueue[1]=self.hand
        self.hand=false
        self:popNext()
    end
end
function MP:hold_swap()
    if self.nextQueue[1] then
        if not self.settings.holdKeepState then
            self.hand=self:restoreMinoState(self.hand)
        end
        self.hand,self.nextQueue[1]=self.nextQueue[1],self.hand
        self:resetPos()
        self:checkHand()
    end
end
function MP:hold_float()
    -- TODO
end
function MP:minoDropped()-- Drop & lock mino, and trigger a lot of things
    if self.handY>self.ghostY then
        self:playSound('drop')
        self.handY=self.ghostY
        self:shakeBoard('-down')
    end
    self:triggerEvent('afterDrop')
    self:lock()
    self:playSound('lock')
    self:triggerEvent('afterLock')
    self:checkField(self.hand)
    if self.finished then return end
    self:discardMino()
    if self.clearTimer==0 and self.spawnTimer==0 then
        self:popNext()
    end
end
function MP:lock()-- Put mino into field
    local CB=self.hand.matrix
    local F=self.field
    for y=1,#CB do for x=1,#CB[1] do
        if CB[y][x] then
            F:setCell(CB[y][x],self.handX+x-1,self.handY+y-1)
        end
    end end
    ins(self.dropHistory,{
        id=self.hand.id,
        x=self.handX,
        y=self.handY,
    })
end
function MP:checkField(mino)-- Check line clear, top out checking, etc.
    local lineClear={}
    local F=self.field
    for y=F:getHeight(),1,-1 do
        local hasHole
        for x=1,F:getWidth() do
            if not F:getCell(x,y) then
                hasHole=true
                break
            end
        end
        if not hasHole then
            F:removeLine(y)
            ins(lineClear,y)
        end
    end
    if #lineClear>0 then
        self.combo=self.combo+1
        self.clearTimer=self.settings.clearDelay
        local h={
            mino=mino,
            combo=self.combo,
            line=#lineClear,
            lines=lineClear,
        }
        ins(self.clearHistory,h)
        self:playSound('combo',h)
        self:playSound('clear',h)
        self:triggerEvent('afterClear',h)
    else
        self.combo=0
        if self.handY>self.settings.deathH then
            self:gameover('MLE')
        end
    end
end
function MP:discardMino()
    self.hand=false
    self.spawnTimer=self.settings.spawnDelay
end
function MP:gameover(reason)
    if self.finished then return end
    self.timing=false
    self.finished=true
    self.hand=false
    self.spawnTimer=1e99
    MES.new(reason=='AC' and 'check' or 'error',reason,6.26)
    if reason=='AC' then-- Win
        self:playSound('win')
    elseif reason=='WA' then-- Block out
        -- TODO
    elseif reason=='CE' then-- Lock out
        -- TODO
    elseif reason=='MLE' then-- Top out
        -- TODO
    elseif reason=='TLE' then-- Time out
        -- TODO
    elseif reason=='OLE' then-- Finesse fault
        -- TODO
    elseif reason=='ILE' then-- Ran out pieces
        -- TODO
    elseif reason=='PE' then-- Mission failed
        -- TODO
    elseif reason=='RE' then-- Other reason
        -- TODO
    end
    self:triggerEvent('gameOver',reason)
end
--------------------------------------------------------------
-- Press & Release
function MP:press(act)
    self:triggerEvent('beforePress',act)

    if not self.actions[act] or self.keyState[act] then return end
    self.keyState[act]=true
    ins(self.actionHistory,{0,self.time,act})
    self.actions[act].press(self)

    self:triggerEvent('afterPress',act)
end
function MP:release(act)
    self:triggerEvent('beforeRelease',act)
    if not self.actions[act] or not self.keyState[act] then return end
    self.keyState[act]=false
    ins(self.actionHistory,{1,self.time,act})
    self.actions[act].release(self)
    self:triggerEvent('afterRelease',act)
end
--------------------------------------------------------------
-- Update & Render
function MP:update(dt)
    local df=int((self.realTime+dt)*1000)-int(self.realTime*1000)
    self.realTime=self.realTime+dt
    local SET=self.settings

    for _=1,df do
        -- Step game time
        if self.timing then self.gameTime=self.gameTime+1--[[df]] end

        -- Calculate board animation
        local O=self.pos
        --                          sticky            force          soft
        O.vx=expApproach(O.vx,0,.02)-sign(O.dx)*.0001*abs(O.dx)^1.2
        O.vy=expApproach(O.vy,0,.02)-sign(O.dy)*.0001*abs(O.dy)^1.1
        O.va=expApproach(O.va,0,.02)-sign(O.da)*.0001*abs(O.da)^1.0
        O.dx=O.dx+O.vx
        O.dy=O.dy+O.vy
        O.da=O.da+O.va

        -- Step main time & Starting counter
        if self.time<SET.readyDelay then
            self.time=self.time+1--[[df]]
            local d=SET.readyDelay-self.time
            if int((d+1--[[df]])/1000)~=int(d/1000) then
                self:playSound('countDown',ceil(d/1000))
            end
            if d==0 then
                self:playSound('countDown',0)
                self:triggerEvent('gameStart')
                self.timing=true
            end
        else
            self.time=self.time+1--[[df]]
        end

        -- Auto shift
        if self.moveDir and (self.moveDir==-1 and self.keyState.moveLeft or self.moveDir==1 and self.keyState.moveRight) then-- Magic IF-statemant. I don't know why it works perfectly
            if self.hand and not self:ifoverlap(self.hand.matrix,self.handX+self.moveDir,self.handY) then
                local c0=self.moveCharge
                local c1=c0+1--[[df]]
                self.moveCharge=c1
                local dist=0
                if c0>=SET.das then
                    c0=c0-SET.das
                    c1=c1-SET.das
                    if SET.arr==0 then
                        dist=1e99
                    else
                        dist=int(c1/SET.arr)-int(c0/SET.arr)
                    end
                elseif c1>=SET.das then
                    if SET.arr==0 then
                        dist=1e99
                    else
                        dist=1
                    end
                end
                if dist>0 then
                    local ox=self.handX
                    while dist>0 and not self:ifoverlap(self.hand.matrix,self.handX+self.moveDir,self.handY) do
                        self.handX=self.handX+self.moveDir
                        self:freshGhost()
                        dist=dist-1
                    end
                    if self.handX~=ox then
                        self:playSound('move')
                        if self.handY==self.ghostY then
                            self:playSound('touch')
                        end
                    end
                end
            else
                self.moveCharge=SET.das
                if self.hand then
                    self:shakeBoard(self.moveDir>0 and '-right' or '-left')
                end
            end
        else
            self.moveDir=self.keyState.moveLeft and -1 or self.keyState.moveRight and 1 or false
            self.moveCharge=0
        end

        -- Auto drop
        if self.downCharge then
            if self.keyState.softDrop then
                local c0=self.downCharge
                local c1=c0+1--[[df]]
                self.downCharge=c1

                if self.hand then
                    local dist=SET.sdarr==0 and 1e99 or int(c1/SET.sdarr)-int(c0/SET.sdarr)
                    local oy=self.handY
                    while dist>0 and not self:ifoverlap(self.hand.matrix,self.handX,self.handY-1) do
                        self.handY=self.handY-1
                        self:freshDelay('drop')
                        dist=dist-1
                    end
                    if oy~=self.handY and self.handY==self.ghostY then
                        self:shakeBoard('-down')
                        self:playSound('touch')
                    end
                else
                    self.downCharge=SET.sdarr
                end
            else
                self.downCharge=false
            end
        end

        repeat-- Update hand
            -- Wait clearing animation
            if self.clearTimer>0 then
                self.clearTimer=self.clearTimer-1--[[df]]
                break
            end

            -- Try spawn mino if don't have one
            if self.spawnTimer>0 then
                self.spawnTimer=self.spawnTimer-1--[[df]]
                if self.spawnTimer==0 then
                    self:popNext()
                end
                break
            elseif not self.hand then
                self:popNext()
            end

            -- Try lock/drop mino
            if self.handY==self.ghostY then
                self.lockTimer=self.lockTimer-1--[[df]]
                if self.lockTimer==0 then
                    self:minoDropped()
                end
                break
            else
                if self.dropDelay~=0 then
                    self.dropTimer=self.dropTimer-1--[[df]]
                    if self.dropTimer==0 then
                        self.dropTimer=SET.dropDelay
                        self.handY=self.handY-1
                        if self.handY==self.ghostY then
                            self:playSound('touch')
                        end
                    end
                elseif self.handY~=self.ghostY then-- If switch to 20G during game, mino won't dropped to bottom instantly so we force fresh it
                    self:freshDelay('drop')
                end
            end
        until true

        self:triggerEvent('always',1--[[df]])
    end
end
function MP:render()
    gc.push('transform')

    -- applyPlayerTransform
    gc.setCanvas({Zenitha.getBigCanvas('player'),stencil=true})
    gc.clear(1,1,1,0)
    gc.translate(self.pos.x+self.pos.dx,self.pos.y+self.pos.dy)
    gc.scale(self.pos.k*self.pos.dk)
    gc.rotate(self.pos.a+self.pos.da)

    -- applyFieldTransform
    gc.push('transform')
    gc.translate(-200,400)
    GC.stc_setComp('equal',1)
    GC.stc_rect(0,0,400,-840)
    gc.scale(10/self.settings.fieldW)


    self:triggerEvent('drawBelowField')


    -- Grid
    gc.setColor(1,1,1,.26)
    local rad,len=1,6-- Line width/length
    local gridHeight=min(max(self.settings.spawnH,self.settings.deathH),2*self.settings.fieldW)
    for x=1,self.settings.fieldW do
        x=(x-1)*40
        for y=1,gridHeight do
            y=-y*40
            gc.rectangle('fill',x,y,len,rad)
            gc.rectangle('fill',x,y+rad,rad,len-rad)
            gc.rectangle('fill',x+40,y,-len,rad)
            gc.rectangle('fill',x+40,y+rad,-rad,len-rad)
            gc.rectangle('fill',x,y+40,len,-rad)
            gc.rectangle('fill',x,y+40-rad,rad,rad-len)
            gc.rectangle('fill',x+40,y+40,-len,-rad)
            gc.rectangle('fill',x+40,y+40-rad,-rad,rad-len)
        end
    end

    -- Cells
    local F=self.field
    for y=1,F:getHeight() do for x=1,F:getWidth() do
        local C=F:getCell(x,y)
        if C then
            gc.setColor(ColorTable[C.color])
            gc.rectangle('fill',(x-1)*40,-y*40,40,40)
        end
    end end


    self:triggerEvent('drawBelowBlock')


    if self.hand then
        local CB=self.hand.matrix

        -- Ghost
        gc.setColor(1,1,1,.26)
        for y=1,#CB do for x=1,#CB[1] do
            if CB[y][x] then
                gc.rectangle('fill',(self.handX+x-2)*40,-(self.ghostY+y-1)*40,40,40)
            end
        end end

        -- Mino
        gc.push('transform')
        if self.handY>self.ghostY then
            gc.translate(0,40*(max(1-self.dropTimer/self.settings.dropDelay*2.6,0))^2.6)
        end
        gc.setColor(1,1,1)
        for y=1,#CB do for x=1,#CB[1] do
            if CB[y][x] then
                gc.setColor(ColorTable[CB[y][x].color])
                gc.rectangle('fill',(self.handX+x-2)*40,-(self.handY+y-1)*40,40,40)
            end
        end end
        local RS=RotationSys[self.settings.rotSys]
        local minoData=RS[self.hand.shape]
        local state=minoData[self.hand.direction]
        local centerPos=state and state.center or type(minoData.center)=='function' and minoData.center(self)
        if centerPos then
            gc.setColor(1,1,1)
            GC.draw(RS.centerTex,(self.handX+centerPos[1]-1)*40,-(self.handY+centerPos[2]-1)*40)
        end
        gc.pop()
    end


    self:triggerEvent('drawBelowMarks')


    -- Height lines
    local width=self.settings.fieldW*40
    gc.setColor(0,.4,1,.8)gc.rectangle('fill',0,-self.settings.spawnH*40-2,width,4)-- Spawning height
    gc.setColor(1,0,0,.6)gc.rectangle('fill',0,-self.settings.deathH*40-2,width,4)-- Death height
    gc.setColor(0,0,0,.5)gc.rectangle('fill',0,-1260*40-40,width,40)-- Void height


    self:triggerEvent('drawInField')


    -- popFieldTransform
    GC.stc_stop()
    gc.pop()

    -- Field border
    gc.setLineWidth(2)
    gc.setColor(1,1,1)
    gc.line(-201,-401,-201, 401,201, 401,201,-401)
    gc.setColor(1,1,1,.626)
    gc.line(-201,-401,201,-401)

    -- Delay indicator
    gc.setColor(1,1,1)
    gc.setLineWidth(2)
    gc.rectangle('line',-201,401,402,12)
    local color,value
    if not self.hand then
        color,value=COLOR.lR,self.spawnTimer/self.settings.spawnDelay
    elseif self.handY~=self.ghostY then
        color,value=COLOR.lG,self.dropTimer/self.settings.dropDelay
    else
        color,value=COLOR.L,self.lockTimer/self.settings.lockDelay
    end
    gc.setColor(color)
    gc.rectangle('fill',-199,403,398*math.min(value,1),8)

    -- Next (Almost same as drawing hold(s), don't forget to change both)
    gc.push('transform')
    gc.translate(300,-400+50)
    gc.setColor(1,1,1)
    for n=1,#self.nextQueue do
        local NB=self.nextQueue[n].matrix
        local k=min(2.3/#NB,3/#NB[1],.86)
        gc.scale(k)
        for y=1,#NB do for x=1,#NB[1] do
            if NB[y][x] then
                gc.setColor(ColorTable[NB[y][x].color])
                gc.rectangle('fill',(x-#NB[1]/2-1)*40,(y-#NB/2)*-40,40,40)
            end
        end end
        gc.scale(1/k)
        gc.translate(0,100)
    end
    gc.pop()

    -- Hold (Almost same as drawing next(s), don't forget to change both)
    gc.push('transform')
    gc.translate(-300,-400+50)
    gc.setColor(1,1,1)
    for n=1,#self.holdQueue do
        local NB=self.holdQueue[n].matrix
        local k=min(2.3/#NB,3/#NB[1],.86)
        gc.scale(k)
        for y=1,#NB do for x=1,#NB[1] do
            if NB[y][x] then
                gc.setColor(ColorTable[NB[y][x].color])
                gc.rectangle('fill',(x-#NB[1]/2-1)*40,(y-#NB/2)*-40,40,40)
            end
        end end
        gc.scale(1/k)
        gc.translate(0,100)
    end
    gc.pop()

    -- Info
    gc.setColor(COLOR.dL)
    FONT.set(30)
    gc.printf(("%.3f"):format(self.gameTime/1000),-210-260,380,260,'right')


    self:triggerEvent('drawOnPlayer')


    -- Starting counter
    if self.time<self.settings.readyDelay then
        gc.push('transform')
        local r,g,b
        local num=int((self.settings.readyDelay-self.time)/1000)+1
        local d=1-self.time%1000/1000-- d from 999 to 0
        if num==1 then
            r,g,b=1,.7,.7
            if d>.75 then gc.scale(1,1+(d/.25-3)^2) end
        elseif num==2 then
            r,g,b=.98,.85,.75
            if d>.75 then gc.scale(1+(d/.25-3)^2,1) end
        elseif num==3 then
            r,g,b=.7,.8,.98
            if d>.75 then gc.rotate((d-.75)^3*40) end
        elseif num==4 then
            r,g,b=.95,.93,.5
        elseif num==5 then
            r,g,b=.7,.95,.7
        else
            r,g,b=max(1.26-num/10,0),max(1.26-num/10,0),max(1.26-num/10,0)
        end

        FONT.set(100)

        gc.push('transform')
            gc.scale((1.5-d*.6)^1.5)
            gc.setColor(r,g,b,d)
            GC.mStr(num,0,-70)
            gc.setColor(1,1,1,1.5*d-0.5)
            GC.mStr(num,0,-70)
        gc.pop()

        gc.scale(min(d/.333,1)^.4)
        gc.setColor(r,g,b)
        GC.mStr(num,0,-70)
        gc.setColor(1,1,1,1.5*d-0.5)
        GC.mStr(num,0,-70)
        gc.pop()
    end

    -- Upside fade out
    gc.setBlendMode('multiply','premultiplied')
    gc.setColorMask(false,false,false,true)
    for i=0,39 do
        gc.setColor(0,0,0,(1-i/40)^2)
        gc.rectangle('fill',-200,-402-i,400,-1)
    end
    gc.setBlendMode('alpha')
    gc.setColorMask()
    gc.setCanvas()

    gc.pop()
end
--------------------------------------------------------------
-- Other methods
function MP:setPosition(x,y,k,angle)
    self.pos.x=x or self.pos.x
    self.pos.y=y or self.pos.y
    self.pos.k=k or self.pos.k
    self.pos.a=angle or self.pos.a
end
function MP:movePosition(dx,dy,k,da)
    self.pos.x=self.pos.x+(dx or 0)
    self.pos.y=self.pos.y+(dy or 0)
    self.pos.k=self.pos.k*(k or 1)
    self.pos.a=self.pos.a+(da or 0)
end
--------------------------------------------------------------
-- Builder
local baseEnv={-- Generate from template in future
    fieldW=10,-- [WARNING] This is not the real field width, just for generate field object. If really want change it, you need change both 'self.field._width' and 'self.field._matrix'
    spawnH=20,-- [WARNING] This can be changed anytime. Field object actually do not contain height information
    deathH=21,
    barrierL=18,
    barrierH=21,

    nextCount=6,

    holdCount=1,
    holdMode='hold',
    holdKeepState=false,

    readyDelay=3000,
    dropDelay=1000,
    lockDelay=1000,
    spawnDelay=0,
    clearDelay=0,

    das=75,
    arr=0,
    sdarr=0,

    actionPack='modern',
    seqType='bag7',
    rotSys='TRS',

    freshCondition='any',

    shakeness=.6,
}
local seqGenerators={
    bag7=function(p)
        local l={}
        while true do
            while #p.nextQueue<p.settings.nextCount do
                if not l[1] then for i=1,7 do l[i]=i end end
                p:getMino(rem(l,math.random(#l)))
            end
            coroutine.yield()
        end
    end,
}
local modeDataMeta={
    __index=function(self,k)rawset(self,k,0)return 0 end,
    __newindex=function(self,k,v)rawset(self,k,v)end,
    __metatable=true,
}
function MP.new(mode)
    local P=setmetatable({},{__index=MP})

    P.settings=TABLE.copy(baseEnv)
    P.event={
        -- Press & Release
        beforePress={},
        afterPress={},
        beforeRelease={},
        afterRelease={},

        -- Start & End
        playerInit={},
        gameStart={},
        gameOver={},

        -- Drop
        afterSpawn={},
        afterDrop={},
        afterLock={},
        afterClear={},

        -- Update
        always={},

        -- Graphics
        drawBelowField={},
        drawBelowBlock={},
        drawBelowMarks={},
        drawInField={},
        drawOnPlayer={},
    }
    P.modeData=setmetatable({},modeDataMeta)
    P.sound=false

    -- Load data & events from mode settings
    for k,v in next,mode.settings do
        if k~='event' then
            if type(v)=='table' then
                P.settings[k]=TABLE.copy(v)
            elseif v~=nil then
                P.settings[k]=v
            end
        else
            for name,E in next,v do
                assert(P.event[name],"Wrong event key: '"..tostring(name).."'")
                if type(E)=='table' then
                    for i=1,#E do
                        ins(P.event[name],E[i])
                    end
                elseif type(E)=='function' then
                    ins(P.event[name],E)
                end
            end
        end
    end

    P.pos={
        x=0,y=0,k=1,a=0,

        dx=0,dy=0,dk=1,da=0,
        vx=0,vy=0,vk=1,va=0,
    }

    P.realTime=0-- Real time, [float] s
    P.time=0-- Inside timer for player, [int] ms
    P.gameTime=0-- Game time of player, [int] ms
    P.timing=false-- Is gameTime running?

    P.field=require'assets.game.minoField'.new(P.settings.fieldW,P.settings.spawnH)
    P.fieldBeneath=0

    P.minoCount=0
    P.combo=0

    P.garbageBuffer={}

    P.nextQueue={}
    P.genNext=coroutine.wrap(seqGenerators[P.settings.seqType])
    P:genNext()

    P.holdQueue={}
    P.holdChance=0

    P.energy=0
    P.energyShow=0

    P.dropTimer=0
    P.lockTimer=0
    P.spawnTimer=P.settings.readyDelay
    P.clearTimer=0

    P.hand=false
    P.handX=false
    P.handY=false
    P.ghostY=false
    P.minY=false

    P.moveDir=false
    P.moveCharge=0
    P.downCharge=false

    P.actionHistory={}
    P.keyBuffer={
        move=false,
        rotate=false,
        hold=false,
        hardDrop=false,
    }
    P.dropHistory={}
    P.clearHistory={}

    -- Generate available actions
    do
        P.actions={}
        local pack=P.settings.actionPack
        if type(pack)=='string' then
            pack=actionPacks[pack]
            assert(pack,STRING.repD("Invalid actionPack '$1'",pack))
            for i=1,#pack do
                P.actions[pack[i]]=_getActionObj(pack[i])
            end
        elseif type(pack)=='table' then
            for k,v in next,pack do
                if type(k)=='number' then
                    P.actions[v]=_getActionObj(v)
                elseif type(k)=='string' then
                    assert(actions[k],STRING.repD("newMinoPlayer: no action called '$1'",k))
                    P.actions[k]=_getActionObj(v)
                else
                    error(STRING.repD("newMinoPlayer: wrong actionPack table format (type $1)",type(k)))
                end
            end
        else
            error("newMinoPlayer: actionPack must be string or table")
        end

        P.keyState={}
        for k in next,P.actions do
            P.keyState[k]=false
        end
    end

    return P
end
--------------------------------------------------------------

return MP
