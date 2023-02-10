local gc=love.graphics

return {
    initialize=function()
        GAME.newPlayer(1,'mino')
        GAME.setMain(1)
        playBgm('way','simp')
    end,
    settings={mino={
        spin_immobile=true,
        spin_corners=3,
        event={
            playerInit=function(P)
                P.modeData.tsd=0
            end,
            afterClear=function(P,movement)
                if P.hand.name=='T' and #movement.clear==2 and movement.action=='rotate' and (movement.corners or movement.immobile) then
                    P.modeData.tsd=P.modeData.tsd+1
                else
                    P:finish('PE')
                end
            end,
            drawOnPlayer=function(P)
                gc.setColor(COLOR.L)
                FONT.set(80)
                GC.mStr(P.modeData.tsd,-300,-55)
                FONT.set(30)
                GC.mStr("TSD",-300,30)
            end,
        },
    }},
}