---@type Techmino.Mode
return {
    initialize=function()
        GAME.newPlayer(1,'mino')
        GAME.setMain(1)
        playBgm('race','base')
    end,
    settings={mino={
        dropDelay=20,
        lockDelay=2600,
        asd=126,
        asp=26,
        freshCount=1e99,
        event={
            playerInit=mechLib.mino.misc.wind_switch_auto,
            afterClear={
                mechLib.mino.sprint.event_afterClear[40],
                mechLib.mino.progress.sprint_wind_40_afterClear,
            },
            drawInField=mechLib.mino.sprint.event_drawInField[40],
            drawOnPlayer=mechLib.mino.sprint.event_drawOnPlayer[40],
            gameOver=mechLib.mino.progress.sprint_wind_40_gameOver,
        },
    }},
}
