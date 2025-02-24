local gc=love.graphics
local dropSpeed={1000,833,666,500,400,300,200,150,100,70,50,30,22,16,12,8,7,6,5,4}

---@type Techmino.Mode
return {
    initialize=function()
        GAME.newPlayer(1,'mino')
        GAME.setMain(1)
        playBgm('push',PROGRESS.get('main')==1 and 'simp' or 'base')
    end,
    settings={mino={
        skin='mino_interior',
        clearMovement='teleBack',
        particles=false,
        spawnDelay=130,
        clearDelay=300,
        deathDelay=0,
        soundEvent={countDown=mechLib.mino.misc.interior_soundEvent_countDown},
        event={
            playerInit=function(P)
                P.settings.asd=math.max(P.settings.asd,100)
                P.settings.asp=math.max(P.settings.asp,20)
                P.settings.adp=math.max(P.settings.adp,20)

                P.settings.dropDelay=dropSpeed[1]
                P.modeData.lineTarget=10
            end,
            afterClear=function(P)
                local md=P.modeData
                while md.stat.line>=md.lineTarget do
                    if md.lineTarget<200 then
                        if PROGRESS.get('main')>=2 and md.lineTarget<=150 and P.isMain then
                            BGM.set(bgmList['push'].add,'volume',(md.lineTarget/150)^2,2.6)
                        end
                        P.settings.dropDelay=dropSpeed[md.lineTarget/10+1]
                        md.lineTarget=md.lineTarget+10
                        P:playSound('reach')
                    else
                        P:finish('AC')
                        return
                    end
                end
            end,
            drawOnPlayer=function(P)
                gc.setColor(COLOR.L)
                FONT.set(70)
                GC.mStr(P.modeData.stat.line,-300,-90)
                gc.rectangle('fill',-375,-2,150,4)
                GC.mStr(P.modeData.lineTarget,-300,-5)
            end,
        },
    }},
    result=function()
        local P=GAME.mainPlayer
        if not P then return end
        PROGRESS.setInteriorScore('sprint',math.min(P.modeData.stat.line*4/3,40))
        PROGRESS.setInteriorScore('marathon',
            P.modeData.stat.line>=200 and 160 or
            P.modeData.stat.line>=130 and MATH.interpolate(130,120,200,160,P.modeData.stat.line) or
            P.modeData.stat.line>=80  and MATH.interpolate(80,90,130,120,P.modeData.stat.line) or
            P.modeData.stat.line>=40  and MATH.interpolate(40,40,80,90,P.modeData.stat.line) or
            MATH.interpolate(0,0,40,40,P.modeData.stat.line)
        )
    end,
    resultPage=function(time)
        local P=GAME.mainPlayer
        if not P then return end

        local line=math.min(P.modeData.stat.line,math.floor(math.max(time-.26,0)*162))

        -- XX/200
        FONT.set(100)
        GC.setColor(COLOR.L)
        GC.mStr(line.." / 200",800,350)

        -- Bar frame
        GC.setLineWidth(6)
        GC.rectangle('line',800-400-15,550-50-15,800+30,100+30)

        -- Filling bar
        GC.setColor(.2,.4,1,.8)
        GC.rectangle('fill',800-400,550-50,math.floor(line/10)*10/200*800,100)
    end,
}
