--- @alias Techmino.Player.Type 'mino'|'puyo'|'gem'
--- @alias Techmino.Mode.Setting Techmino.Mode.Setting.Mino|Techmino.Mode.Setting.Puyo|Techmino.Mode.Setting.Gem
--- @alias Techmino.EndReason
--- | 'AC'  Win
--- | 'WA'  Block out
--- | 'CE'  Lock out
--- | 'MLE' Top out
--- | 'TLE' Time out
--- | 'OLE' Finesse fault
--- | 'ILE' Ran out pieces
--- | 'PE'  Mission failed
--- | 'UKE' Other reason

--- @class Techmino.ParticleSystems
--- @field rectShade love.ParticleSystem
--- @field spinArrow table
--- @field star love.ParticleSystem
--- @field line love.ParticleSystem
--- @field hitSparkle love.ParticleSystem
--- @field cornerCheck love.ParticleSystem
--- @field tiltRect love.ParticleSystem
--- @field trail love.ParticleSystem
--- @field minoMapBack love.ParticleSystem

--- @class Techmino.Mino
--- @field name string
--- @field id number
--- @field shape boolean[][]

--- @class Techmino.Minos
--- @field Z  Techmino.Mino
--- @field S  Techmino.Mino
--- @field J  Techmino.Mino
--- @field L  Techmino.Mino
--- @field T  Techmino.Mino
--- @field O  Techmino.Mino
--- @field I  Techmino.Mino
--- @field Z5 Techmino.Mino
--- @field S5 Techmino.Mino
--- @field P  Techmino.Mino
--- @field Q  Techmino.Mino
--- @field F  Techmino.Mino
--- @field E  Techmino.Mino
--- @field T5 Techmino.Mino
--- @field U  Techmino.Mino
--- @field V  Techmino.Mino
--- @field W  Techmino.Mino
--- @field X  Techmino.Mino
--- @field J5 Techmino.Mino
--- @field L5 Techmino.Mino
--- @field R  Techmino.Mino
--- @field Y  Techmino.Mino
--- @field N  Techmino.Mino
--- @field H  Techmino.Mino
--- @field I5 Techmino.Mino
--- @field I3 Techmino.Mino
--- @field C  Techmino.Mino
--- @field I2 Techmino.Mino
--- @field O1 Techmino.Mino

--- @class Techmino.Cell
--- @field id number ascending piece number
--- @field color number 0~63
--- @field conn table<Techmino.Cell,true>
--- @field bias {expBack:number?, lineBack:number?, teleBack:number?, x:number, y:number}

--- @class Techmino.RectField
--- @field _width number
--- @field _matrix (Techmino.Cell|false|any)[][]

--- @class Techmino.Mode
--- @field initialize function Called when initializing the mode
--- @field settings table<Techmino.Player.Type, Techmino.Mode.Setting>
--- @field layout 'default' Layout mode
--- @field checkFinish function Return if the game should end when a player finishes
--- @field result function Called when the game ends
--- @field resultPage fun(time:number) Drawing the result page
--- @field name string Mode name, for debug use

--- @class Techmino.Mode.Setting.Mino
--- @class Techmino.Mode.Setting.Puyo
--- @class Techmino.Mode.Setting.Gem

--- @class Techmino.mino.clearRule
--- @field getDelay fun(P:Techmino.Player.mino, lines:number[]): number?
--- @field isFill fun(P:Techmino.Player.mino, y:number): boolean
--- @field getFill fun(P:Techmino.Player.mino): number[]?
--- @field clear fun(P:Techmino.Player.mino, lines:number[])

--- @class Techmino.Game
--- @field playing boolean
--- @field playerList table<number, Techmino.Player>|false
--- @field playerMap table<number, Techmino.Player>|false
--- @field camera Zenitha.Camera
--- @field hitWaves table
--- @field seed number|false
--- @field mode Techmino.Mode|false
--- @field mainID number|false
--- @field mainPlayer Techmino.Player|false

--- @class Techmino.Player
--- @field gameMode Techmino.Player.Type
--- @field id number limited to 1~1000
--- @field group number
--- @field isMain boolean
--- @field sound boolean
--- @field settings table
--- @field buffedKey table
--- @field modeData table
--- @field soundTimeHistory table
--- @field RND love.RandomGenerator
--- @field pos {x:number, y:number, k:number, a:number, dx:number, dy:number, dk:number, da:number, vx:number, vy:number, vk:number, va:number}
--- @field finished Techmino.EndReason|boolean
--- @field realTime number
--- @field time number
--- @field gameTime number
--- @field timing boolean
--- @field texts Zenitha.Text
--- @field particles Techmino.ParticleSystems
---
--- @field updateFrame function
--- @field scriptCmd function
--- @field decodeScript function
--- @field checkScriptSyntax function
---
--- @field hand table|false @Piece object
--- @field handX number
--- @field handY number
--- @field event table
--- @field soundEvent table
--- @field _actions table<string, {press:fun(P:Techmino.Player), release:fun(P:Techmino.Player)}>
---
--- @field receive function
--- @field render function
