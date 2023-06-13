return {
    initialize=function()
        GAME.newPlayer(1,'mino')
        GAME.setMain(1)
        playBgm('race','full')
    end,
    settings={mino={
        seqType='bag7_sprint',
        event={
            afterClear={
                mechLib.mino.sprint.event_afterClear[10],
                mechLib.mino.progress.sprint_10_afterClear,
            },
            drawInField=mechLib.mino.sprint.event_drawInField[10],
            drawOnPlayer=mechLib.mino.sprint.event_drawOnPlayer[10],
        },
    }},
}
