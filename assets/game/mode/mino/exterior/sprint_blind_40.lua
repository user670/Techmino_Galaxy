---@type Techmino.Mode
return {
    initialize=function()
        GAME.newPlayer(1,'mino')
        GAME.setMain(1)
        playBgm('race','base')
    end,
    settings={mino={
        pieceVisTime=120,
        pieceFadeTime=120,
        event={
            playerInit=mechLib.mino.misc.coverField_switch_auto,
            afterClear={
                mechLib.mino.sprint.event_afterClear[40],
                mechLib.mino.progress.sprint_blind_40_afterClear,
            },
            drawInField=mechLib.mino.sprint.event_drawInField[40],
            drawOnPlayer=mechLib.mino.sprint.event_drawOnPlayer[40],
            gameOver=mechLib.mino.progress.sprint_blind_40_gameOver,
        },
    }},
}
