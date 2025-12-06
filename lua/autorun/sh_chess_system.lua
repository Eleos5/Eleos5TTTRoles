AddCSLuaFile()

ChessSystem = ChessSystem or {}
ChessSystem.ActiveGames = ChessSystem.ActiveGames or {}
ChessSystem.TimerDuration = ChessSystem.TimerDuration or 600 -- Default 10 minutes

local HOOK_NAME = "ChessMatchEnded"

-- Net Messages
if SERVER then
    util.AddNetworkString("Chess_OpenGame")
    util.AddNetworkString("Chess_UpdateBoard")
    util.AddNetworkString("Chess_SendMove")
    util.AddNetworkString("Chess_EndGame")
    util.AddNetworkString("Chess_UpdateTimer")
    util.AddNetworkString("Chess_Resign")
end

-- Helpers
local TYPE_PAWN = 1
local TYPE_ROOK = 2
local TYPE_KNIGHT = 3
local TYPE_BISHOP = 4
local TYPE_QUEEN = 5
local TYPE_KING = 6

local TEAM_WHITE = 1
local TEAM_BLACK = 2

-- Unicode pieces for the GUI
local PIECE_SYMBOLS = {
    [TEAM_WHITE] = { [TYPE_PAWN]="♙", [TYPE_ROOK]="♖", [TYPE_KNIGHT]="♘", [TYPE_BISHOP]="♗", [TYPE_QUEEN]="♕", [TYPE_KING]="♔" },
    [TEAM_BLACK] = { [TYPE_PAWN]="♟", [TYPE_ROOK]="♜", [TYPE_KNIGHT]="♞", [TYPE_BISHOP]="♝", [TYPE_QUEEN]="♛", [TYPE_KING]="♚" }
}

-- Piece colors for rendering
local PIECE_COLORS = {
    [TEAM_WHITE] = Color(255, 255, 255),
    [TEAM_BLACK] = Color(80, 80, 80) -- Dark gray instead of pure black
}

-- Board Setup
local function CreateBoard()
    local board = {}
    for r=1, 8 do board[r] = {} for c=1, 8 do board[r][c] = nil end end

    local setup = {TYPE_ROOK, TYPE_KNIGHT, TYPE_BISHOP, TYPE_QUEEN, TYPE_KING, TYPE_BISHOP, TYPE_KNIGHT, TYPE_ROOK}
    
    for c=1, 8 do
        board[1][c] = {type = setup[c], team = TEAM_BLACK}
        board[2][c] = {type = TYPE_PAWN, team = TEAM_BLACK}
        board[7][c] = {type = TYPE_PAWN, team = TEAM_WHITE}
        board[8][c] = {type = setup[c], team = TEAM_WHITE}
    end
    return board
end

-- ==========================================
-- SHARED MOVE VALIDATION
-- ==========================================

-- Copy board for simulation
local function CopyBoard(board)
    local newBoard = {}
    for r=1, 8 do
        newBoard[r] = {}
        for c=1, 8 do
            if board[r][c] then
                newBoard[r][c] = {type = board[r][c].type, team = board[r][c].team}
            end
        end
    end
    return newBoard
end

local function FindKing(board, team)
    for r=1, 8 do
        for c=1, 8 do
            local piece = board[r][c]
            if piece and piece.type == TYPE_KING and piece.team == team then
                return r, c
            end
        end
    end
    return nil, nil
end

function IsKingInCheck(board, team)
    local kr, kc = FindKing(board, team)
    if not kr then return false end
    
    local enemyTeam = (team == TEAM_WHITE) and TEAM_BLACK or TEAM_WHITE
    
    for r=1, 8 do
        for c=1, 8 do
            local piece = board[r][c]
            if piece and piece.team == enemyTeam then
                -- Use basic move validation without gameState to avoid infinite recursion
                if IsValidMoveBasic(board, {r, c}, {kr, kc}, enemyTeam) then
                    return true
                end
            end
        end
    end
    return false
end

-- Basic move validation without check testing (for check detection)
function IsValidMoveBasic(board, startPos, endPos, team)
    local r1, c1 = startPos[1], startPos[2]
    local r2, c2 = endPos[1], endPos[2]
    
    if not board[r1] or not board[r1][c1] then return false end
    if not board[r2] then return false end

    local piece = board[r1][c1]
    
    if piece.team ~= team then return false end
    if r1 == r2 and c1 == c2 then return false end

    local target = board[r2][c2]
    if target and target.team == team then return false end 

    local dr = r2 - r1
    local dc = c2 - c1
    local absDr = math.abs(dr)
    local absDc = math.abs(dc)

    if piece.type == TYPE_PAWN then
        local dir = (team == TEAM_WHITE) and -1 or 1
        if c1 == c2 and not target and r2 == r1 + dir then return true end
        if c1 == c2 and not target and absDr == 2 and r2 == r1 + (dir*2) then
            if (team == TEAM_WHITE and r1 == 7) or (team == TEAM_BLACK and r1 == 2) then
                if not board[r1+dir][c1] then return true end
            end
        end
        if absDc == 1 and r2 == r1 + dir and target then return true end
        return false
    end

    if piece.type == TYPE_ROOK then
        if dr ~= 0 and dc ~= 0 then return false end
        local stepR = (dr == 0) and 0 or (dr > 0 and 1 or -1)
        local stepC = (dc == 0) and 0 or (dc > 0 and 1 or -1)
        local checkR, checkC = r1 + stepR, c1 + stepC
        while (checkR ~= r2 or checkC ~= c2) do
            if board[checkR] and board[checkR][checkC] then return false end
            checkR = checkR + stepR
            checkC = checkC + stepC
        end
        return true
    end

    if piece.type == TYPE_BISHOP then
        if absDr ~= absDc then return false end
        local stepR = (dr > 0 and 1 or -1)
        local stepC = (dc > 0 and 1 or -1)
        local checkR, checkC = r1 + stepR, c1 + stepC
        while (checkR ~= r2 or checkC ~= c2) do
            if board[checkR] and board[checkR][checkC] then return false end
            checkR = checkR + stepR
            checkC = checkC + stepC
        end
        return true
    end

    if piece.type == TYPE_QUEEN then
        local isStraight = (dr == 0 or dc == 0)
        local isDiag = (absDr == absDc)
        if not isStraight and not isDiag then return false end
        
        local stepR = (dr == 0) and 0 or (dr > 0 and 1 or -1)
        local stepC = (dc == 0) and 0 or (dc > 0 and 1 or -1)
        local checkR, checkC = r1 + stepR, c1 + stepC
        while (checkR ~= r2 or checkC ~= c2) do
            if board[checkR] and board[checkR][checkC] then return false end
            checkR = checkR + stepR
            checkC = checkC + stepC
        end
        return true
    end

    if piece.type == TYPE_KNIGHT then
        if (absDr == 2 and absDc == 1) or (absDr == 1 and absDc == 2) then return true end
        return false
    end

    if piece.type == TYPE_KING then
        if absDr <= 1 and absDc <= 1 then return true end
        return false
    end

    return false
end

local function IsValidMove(board, startPos, endPos, team, gameState)
    local r1, c1 = startPos[1], startPos[2]
    local r2, c2 = endPos[1], endPos[2]
    
    if not board[r1] or not board[r1][c1] then return false end
    if not board[r2] then return false end

    local piece = board[r1][c1]
    
    if piece.team ~= team then return false end
    if r1 == r2 and c1 == c2 then return false end

    local target = board[r2][c2]
    if target and target.team == team then return false end 

    local dr = r2 - r1
    local dc = c2 - c1
    local absDr = math.abs(dr)
    local absDc = math.abs(dc)
    
    local isBasicValid = false
    local specialMove = nil

    if piece.type == TYPE_PAWN then
        local dir = (team == TEAM_WHITE) and -1 or 1
        if c1 == c2 and not target and r2 == r1 + dir then isBasicValid = true end
        if c1 == c2 and not target and absDr == 2 and r2 == r1 + (dir*2) then
            if (team == TEAM_WHITE and r1 == 7) or (team == TEAM_BLACK and r1 == 2) then
                if not board[r1+dir][c1] then isBasicValid = true end
            end
        end
        if absDc == 1 and r2 == r1 + dir and target then isBasicValid = true end
        
        -- En Passant
        if gameState and gameState.lastMove and absDc == 1 and r2 == r1 + dir and not target then
            local lastMove = gameState.lastMove
            if lastMove.piece == TYPE_PAWN and lastMove.team ~= team then
                if math.abs(lastMove.fromR - lastMove.toR) == 2 then
                    if lastMove.toR == r1 and lastMove.toC == c2 then
                        isBasicValid = true
                        specialMove = "enpassant"
                    end
                end
            end
        end
    elseif piece.type == TYPE_KING then
        if absDr <= 1 and absDc <= 1 then 
            isBasicValid = true 
        end
        
        -- Castling
        if gameState and dr == 0 and absDc == 2 then
            if gameState.hasMoved[team] and gameState.hasMoved[team].king then return false end
            
            local rookCol = (dc > 0) and 8 or 1
            local rook = board[r1][rookCol]
            
            if not rook or rook.type ~= TYPE_ROOK or rook.team ~= team then return false end
            if gameState.hasMoved[team] and gameState.hasMoved[team][rookCol] then return false end
            
            local step = (dc > 0) and 1 or -1
            for checkC = c1 + step, rookCol - step, step do
                if board[r1][checkC] then return false end
            end
            
            if IsKingInCheck(board, team) then return false end
            
            local testBoard = CopyBoard(board)
            testBoard[r1][c1 + step] = testBoard[r1][c1]
            testBoard[r1][c1] = nil
            if IsKingInCheck(testBoard, team) then return false end
            
            isBasicValid = true
            specialMove = "castle"
        end
    else
        isBasicValid = IsValidMoveBasic(board, startPos, endPos, team)
    end
    
    if not isBasicValid then return false end
    
    -- Test if move would leave king in check
    local testBoard = CopyBoard(board)
    
    -- Simulate en passant capture
    if specialMove == "enpassant" then
        local captureRow = (team == TEAM_WHITE) and r2 + 1 or r2 - 1
        testBoard[captureRow][c2] = nil
    end
    
    -- Simulate castling
    if specialMove == "castle" then
        local rookFromCol = (c2 > c1) and 8 or 1
        local rookToCol = (c2 > c1) and c2 - 1 or c2 + 1
        testBoard[r2][rookToCol] = testBoard[r1][rookFromCol]
        testBoard[r1][rookFromCol] = nil
    end
    
    testBoard[r2][c2] = testBoard[r1][c1]
    testBoard[r1][c1] = nil
    
    if IsKingInCheck(testBoard, team) then
        return false
    end
    
    return true, specialMove
end

local function GetAllValidMoves(board, r, c, team, gameState)
    local moves = {}
    if not board[r] or not board[r][c] then return moves end
    
    for tr=1, 8 do
        for tc=1, 8 do
            local valid, special = IsValidMove(board, {r, c}, {tr, tc}, team, gameState)
            if valid then
                table.insert(moves, {r=tr, c=tc, special=special})
            end
        end
    end
    return moves
end

local function HasAnyValidMoves(board, team, gameState)
    for r=1, 8 do
        for c=1, 8 do
            local piece = board[r][c]
            if piece and piece.team == team then
                local moves = GetAllValidMoves(board, r, c, team, gameState)
                if #moves > 0 then return true end
            end
        end
    end
    return false
end

local function IsCheckmate(board, team, gameState)
    if not IsKingInCheck(board, team) then return false end
    return not HasAnyValidMoves(board, team, gameState)
end

-- ==========================================
-- SERVER SIDE LOGIC
-- ==========================================
if SERVER then

    function ChessSystem.StartGame(plyWhite, plyBlack, timerDuration)
        if not IsValid(plyWhite) then return nil end
        
        timerDuration = timerDuration or ChessSystem.TimerDuration
        
        local gameID = plyWhite:SteamID() .. "_" .. (IsValid(plyBlack) and plyBlack:SteamID() or "SOLO") .. "_" .. CurTime()
        
        local game = {
            Board = CreateBoard(),
            White = plyWhite,
            Black = plyBlack or plyWhite,
            Turn = TEAM_WHITE,
            ID = gameID,
            WhiteTime = timerDuration,
            BlackTime = timerDuration,
            LastMoveTime = CurTime(),
            IsSolo = (not IsValid(plyBlack) or plyWhite == plyBlack),
            lastMove = nil,
            hasMoved = {
                [TEAM_WHITE] = {},
                [TEAM_BLACK] = {}
            },
            Entity = nil -- Will hold the 3D board entity
        }

        ChessSystem.ActiveGames[gameID] = game
        
        -- Create 3D board entity
        local boardEnt = ents.Create("prop_physics")
        if IsValid(boardEnt) then
            boardEnt:SetModel("models/hunter/plates/plate2x2.mdl")
            boardEnt:SetMaterial("models/debug/debugwhite")
            boardEnt:SetColor(Color(139, 69, 19))
            
            local whitePos = plyWhite:GetPos() + plyWhite:GetForward() * 100 + Vector(0, 0, 50)
            local blackPos = IsValid(plyBlack) and (plyBlack:GetPos() + plyBlack:GetForward() * 100 + Vector(0, 0, 50)) or whitePos
            local midPos = (whitePos + blackPos) / 2
            
            -- Calculate angle to face between players
            local toBlack = (blackPos - whitePos):GetNormalized()
            local boardAngle = toBlack:Angle()
            boardAngle:RotateAroundAxis(boardAngle:Right(), 90) -- Make it vertical/facing forward
            
            boardEnt:SetPos(midPos)
            boardEnt:SetAngles(boardAngle)
            boardEnt:Spawn()
            boardEnt:GetPhysicsObject():EnableMotion(false) -- Prevent falling
            boardEnt:SetCollisionGroup(COLLISION_GROUP_WORLD)
            boardEnt.ChessGameID = gameID
            boardEnt.ChessGame = game
            
            game.Entity = boardEnt
            game.BoardAngle = boardAngle
        end
        
        net.Start("Chess_OpenGame")
            net.WriteEntity(game.White)
            net.WriteEntity(game.Black)
            net.WriteTable(game.Board)
            net.WriteInt(game.Turn, 3)
            net.WriteBool(game.IsSolo)
            net.WriteInt(timerDuration, 16)
            net.WriteEntity(boardEnt)
        net.Send({game.White, game.Black})
        
        print("[Chess] Started game: " .. plyWhite:Nick() .. (game.IsSolo and " (Solo)" or " vs " .. plyBlack:Nick()))
        
        -- Timer update loop
        timer.Create("ChessTimer_" .. gameID, 0.1, 0, function()
            if not ChessSystem.ActiveGames[gameID] then 
                timer.Remove("ChessTimer_" .. gameID)
                return 
            end
            
            local g = ChessSystem.ActiveGames[gameID]
            local elapsed = CurTime() - g.LastMoveTime
            
            if g.Turn == TEAM_WHITE then
                g.WhiteTime = math.max(0, g.WhiteTime - elapsed)
            else
                g.BlackTime = math.max(0, g.BlackTime - elapsed)
            end
            g.LastMoveTime = CurTime()
            
            net.Start("Chess_UpdateTimer")
                net.WriteInt(math.floor(g.WhiteTime), 16)
                net.WriteInt(math.floor(g.BlackTime), 16)
                net.WriteString(gameID)
            net.Send({g.White, g.Black})
            
            if g.WhiteTime <= 0 then
                ChessSystem.EndGame(gameID, TEAM_BLACK, "timeout")
            elseif g.BlackTime <= 0 then
                ChessSystem.EndGame(gameID, TEAM_WHITE, "timeout")
            end
        end)
        
        return game
    end

    function ChessSystem.EndGame(gameID, winnerTeam, reason)
        local game = ChessSystem.ActiveGames[gameID]
        if not game then return end

        timer.Remove("ChessTimer_" .. gameID)

        local winner = (winnerTeam == TEAM_WHITE) and game.White or game.Black
        local loser = (winnerTeam == TEAM_WHITE) and game.Black or game.White
        if game.White == game.Black then loser = game.White end

        -- Remove 3D board
        if IsValid(game.Entity) then
            game.Entity:Remove()
        end

        net.Start("Chess_EndGame")
            net.WriteInt(winnerTeam, 3)
            net.WriteString(reason or "checkmate")
            net.WriteString(gameID)
        net.Send({game.White, game.Black})

        ChessSystem.ActiveGames[gameID] = nil
        hook.Call(HOOK_NAME, nil, winner, loser, reason)
    end

    net.Receive("Chess_SendMove", function(len, ply)
        local r1 = net.ReadUInt(4)
        local c1 = net.ReadUInt(4)
        local r2 = net.ReadUInt(4)
        local c2 = net.ReadUInt(4)

        local game = nil
        for k, v in pairs(ChessSystem.ActiveGames) do
            if v.White == ply or v.Black == ply then game = v break end
        end

        if not game then return end
        
        if game.IsSolo then
            -- Allow any move in solo mode
        else
            if game.Turn == TEAM_WHITE and game.White ~= ply then return end
            if game.Turn == TEAM_BLACK and game.Black ~= ply then return end
        end

        local valid, special = IsValidMove(game.Board, {r1, c1}, {r2, c2}, game.Turn, game)
        if valid then
            local piece = game.Board[r1][c1]
            
            -- Handle En Passant
            if special == "enpassant" then
                local captureRow = (game.Turn == TEAM_WHITE) and r2 + 1 or r2 - 1
                game.Board[captureRow][c2] = nil
            end
            
            -- Handle Castling
            if special == "castle" then
                local rookFromCol = (c2 > c1) and 8 or 1
                local rookToCol = (c2 > c1) and c2 - 1 or c2 + 1
                game.Board[r2][rookToCol] = game.Board[r1][rookFromCol]
                game.Board[r1][rookFromCol] = nil
            end
            
            game.Board[r2][c2] = game.Board[r1][c1]
            game.Board[r1][c1] = nil
            
            -- Track moves for castling
            if piece.type == TYPE_KING then
                game.hasMoved[game.Turn].king = true
            elseif piece.type == TYPE_ROOK then
                game.hasMoved[game.Turn][c1] = true
            end
            
            -- Store last move for en passant
            game.lastMove = {
                piece = piece.type,
                team = piece.team,
                fromR = r1,
                fromC = c1,
                toR = r2,
                toC = c2
            }
            
            -- Auto Queen Promotion
            if game.Board[r2][c2].type == TYPE_PAWN then
                if (game.Turn == TEAM_WHITE and r2 == 1) or (game.Turn == TEAM_BLACK and r2 == 8) then
                    game.Board[r2][c2].type = TYPE_QUEEN
                end
            end

            game.Turn = (game.Turn == TEAM_WHITE) and TEAM_BLACK or TEAM_WHITE
            game.LastMoveTime = CurTime()
            
            net.Start("Chess_UpdateBoard")
                net.WriteTable(game.Board)
                net.WriteInt(game.Turn, 3)
                net.WriteTable(game.lastMove)
                net.WriteString(game.ID)
            net.Send({game.White, game.Black})

            -- Check for checkmate
            if IsCheckmate(game.Board, game.Turn, game) then
                local winnerTeam = (game.Turn == TEAM_WHITE) and TEAM_BLACK or TEAM_WHITE 
                ChessSystem.EndGame(game.ID, winnerTeam, "checkmate")
            end
        end
    end)
    
    net.Receive("Chess_Resign", function(len, ply)
        local game = nil
        for k, v in pairs(ChessSystem.ActiveGames) do
            if v.White == ply or v.Black == ply then game = v break end
        end
        
        if not game then return end
        
        local winnerTeam = (game.White == ply) and TEAM_BLACK or TEAM_WHITE
        ChessSystem.EndGame(game.ID, winnerTeam, "resignation")
    end)
    
    hook.Add("PlayerDisconnected", "Chess_Cleanup", function(ply)
        for k, v in pairs(ChessSystem.ActiveGames) do
            if v.White == ply or v.Black == ply then
                timer.Remove("ChessTimer_" .. k)
                local winner = (v.White == ply) and v.Black or v.White
                ChessSystem.EndGame(k, (v.White == ply) and TEAM_BLACK or TEAM_WHITE, "disconnect")
            end
        end
    end)

    concommand.Add("chess_test_solo", function(ply, cmd, args)
        local duration = tonumber(args[1]) or ChessSystem.TimerDuration
        ChessSystem.StartGame(ply, ply, duration)
    end)

    concommand.Add("chess_challenge_eye", function(ply, cmd, args)
        local tr = ply:GetEyeTrace()
        local duration = tonumber(args[1]) or ChessSystem.TimerDuration
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            ChessSystem.StartGame(ply, tr.Entity, duration)
        else
            ply:ChatPrint("Look at a player to challenge them.")
        end
    end)
    
    concommand.Add("chess_set_timer", function(ply, cmd, args)
        local duration = tonumber(args[1])
        if duration and duration > 0 then
            ChessSystem.TimerDuration = duration
            ply:ChatPrint("Chess timer set to " .. duration .. " seconds")
        else
            ply:ChatPrint("Usage: chess_set_timer <seconds>")
        end
    end)
end

-- ==========================================
-- CLIENT SIDE UI
-- ==========================================
if CLIENT then
    local Frame = nil
    local BoardPanel = nil
    local CurrentBoard = {}
    local CurrentTurn = TEAM_WHITE
    local SelectedSquare = nil
    local ValidMoves = {}
    local MyTurn = false
    local MyTeam = 0
    local IsSoloMode = false
    local WhiteTime = 0
    local BlackTime = 0
    local LastMoveData = nil
    local GameState = nil
    local BoardEntity = nil
    local BoardEntityAngle = nil

    local PIECE_SYMBOLS = {
        [TEAM_WHITE] = { [TYPE_PAWN]="♙", [TYPE_ROOK]="♖", [TYPE_KNIGHT]="♘", [TYPE_BISHOP]="♗", [TYPE_QUEEN]="♕", [TYPE_KING]="♔" },
        [TEAM_BLACK] = { [TYPE_PAWN]="♟", [TYPE_ROOK]="♜", [TYPE_KNIGHT]="♞", [TYPE_BISHOP]="♝", [TYPE_QUEEN]="♛", [TYPE_KING]="♚" }
    }

    local function FormatTime(seconds)
        local mins = math.floor(seconds / 60)
        local secs = seconds % 60
        return string.format("%d:%02d", mins, secs)
    end
    
    local function GetDisplayCoords(r, c)
        if MyTeam == TEAM_BLACK then
            return 9 - r, 9 - c
        end
        return r, c
    end

    local function DrawBoard(boardData, turnTeam)
        CurrentBoard = boardData
        CurrentTurn = turnTeam
        if not IsValid(BoardPanel) then return end
        
        BoardPanel:Clear()
        local squareSize = 64
        
        for r=1, 8 do
            for c=1, 8 do
                local displayR, displayC = GetDisplayCoords(r, c)
                
                local btn = BoardPanel:Add("DButton")
                btn:SetSize(squareSize, squareSize)
                btn:SetPos((displayC-1)*squareSize, (displayR-1)*squareSize)
                btn:SetText("")
                
                local isDark = (r + c) % 2 == 1
                local color = isDark and Color(118,150,86) or Color(238,238,210)
                
                -- Highlight last move
                local isLastMoveSquare = false
                if LastMoveData then
                    if (LastMoveData.fromR == r and LastMoveData.fromC == c) or 
                       (LastMoveData.toR == r and LastMoveData.toC == c) then
                        isLastMoveSquare = true
                        color = isDark and Color(170, 162, 58) or Color(205, 210, 106)
                    end
                end
                
                if SelectedSquare and SelectedSquare.r == r and SelectedSquare.c == c then
                    color = Color(186, 202, 68) 
                end
                
                local isValidMove = false
                for _, move in ipairs(ValidMoves) do
                    if move.r == r and move.c == c then
                        isValidMove = true
                        break
                    end
                end
                
                if isValidMove then
                    color = Color(100, 149, 237, 150)
                end

                btn.Paint = function(s, w, h)
                    draw.RoundedBox(0, 0, 0, w, h, color)
                    
                    if isValidMove and not CurrentBoard[r][c] then
                        draw.RoundedBox(w/4, w/2 - 6, h/2 - 6, 12, 12, Color(0, 0, 0, 100))
                    end
                    
                    local piece = CurrentBoard[r][c]
                    if piece then
                        local symbol = PIECE_SYMBOLS[piece.team][piece.type]
                        -- Better outline for black pieces
                        local pieceColor = (piece.team == TEAM_WHITE) and Color(255,255,255) or Color(50,50,50)
                        local outlineColor = (piece.team == TEAM_WHITE) and Color(0,0,0,150) or Color(255,255,255,200)
                        
                        draw.SimpleTextOutlined(symbol, "DermaLarge", w/2, h/2, 
                            pieceColor, 
                            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                            2,
                            outlineColor
                        )
                        
                        if isValidMove then
                            surface.SetDrawColor(255, 0, 0, 120)
                            surface.DrawOutlinedRect(2, 2, w-4, h-4)
                            surface.DrawOutlinedRect(3, 3, w-6, h-6)
                            surface.DrawOutlinedRect(4, 4, w-8, h-8)
                        end
                    end
                end

                btn.DoClick = function()
                    if not MyTurn and not IsSoloMode then return end

                    if not SelectedSquare then
                        local piece = CurrentBoard[r][c]
                        -- Check if it's the correct turn to move
                        local canSelect = false
                        if IsSoloMode then
                            canSelect = piece and piece.team == CurrentTurn
                        else
                            canSelect = piece and piece.team == MyTeam and piece.team == CurrentTurn
                        end
                        
                        if canSelect then
                            SelectedSquare = {r=r, c=c}
                            ValidMoves = GetAllValidMoves(CurrentBoard, r, c, piece.team, GameState)
                            DrawBoard(CurrentBoard, turnTeam)
                        end
                    else
                        net.Start("Chess_SendMove")
                            net.WriteUInt(SelectedSquare.r, 4)
                            net.WriteUInt(SelectedSquare.c, 4)
                            net.WriteUInt(r, 4)
                            net.WriteUInt(c, 4)
                        net.SendToServer()
                        
                        SelectedSquare = nil
                        ValidMoves = {}
                        DrawBoard(CurrentBoard, turnTeam)
                    end
                end
            end
        end
    end

    net.Receive("Chess_OpenGame", function()
        local whitePly = net.ReadEntity()
        local blackPly = net.ReadEntity()
        local board = net.ReadTable()
        local turn = net.ReadInt(3)
        IsSoloMode = net.ReadBool()
        local timerDuration = net.ReadInt(16)
        BoardEntity = net.ReadEntity()

        if IsValid(Frame) then Frame:Close() end

        if LocalPlayer() == whitePly then MyTeam = TEAM_WHITE
        elseif LocalPlayer() == blackPly then MyTeam = TEAM_BLACK end

        MyTurn = (turn == MyTeam)
        WhiteTime = timerDuration
        BlackTime = timerDuration
        GameState = {lastMove = nil, hasMoved = {}}
        LastMoveData = nil

        Frame = vgui.Create("DFrame")
        Frame:SetSize(700, 600)
        Frame:Center()
        Frame:SetTitle("Chess - " .. (IsSoloMode and "Solo Mode" or (MyTeam == TEAM_WHITE and "White" or "Black")))
        Frame:MakePopup()
        Frame:ShowCloseButton(false)

        local header = vgui.Create("DLabel", Frame)
        header:SetPos(10, 30)
        header:SetSize(430, 20)
        header:SetFont("DermaDefaultBold")
        header:SetContentAlignment(5)
        header.Think = function(s)
            if IsSoloMode then
                s:SetText("SOLO MODE - Play Both Sides")
                s:SetTextColor(Color(100, 100, 255))
            else
                s:SetText(MyTurn and "YOUR TURN" or "OPPONENT'S TURN")
                s:SetTextColor(MyTurn and Color(0,255,0) or Color(255,0,0))
            end
        end
        
        -- Resign Button
        local resignBtn = vgui.Create("DButton", Frame)
        resignBtn:SetPos(450, 30)
        resignBtn:SetSize(80, 20)
        resignBtn:SetText("Resign")
        resignBtn.DoClick = function()
            Derma_Query("Are you sure you want to resign?", "Resign", "Yes", function()
                net.Start("Chess_Resign")
                net.SendToServer()
            end, "No")
        end

        BoardPanel = vgui.Create("DPanel", Frame)
        BoardPanel:SetPos(20, 60)
        BoardPanel:SetSize(512, 512)
        
        -- Timer Panel
        local timerPanel = vgui.Create("DPanel", Frame)
        timerPanel:SetPos(550, 60)
        timerPanel:SetSize(130, 512)
        timerPanel.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40))
            
            -- Display opponent time at top, player time at bottom
            local topTeam = (MyTeam == TEAM_WHITE) and TEAM_BLACK or TEAM_WHITE
            local bottomTeam = MyTeam
            
            local topTime = (topTeam == TEAM_WHITE) and WhiteTime or BlackTime
            local bottomTime = (bottomTeam == TEAM_WHITE) and WhiteTime or BlackTime
            
            local topLabel = (topTeam == TEAM_WHITE) and "White" or "Black"
            local bottomLabel = (bottomTeam == TEAM_WHITE) and "White" or "Black"
            
            -- Top timer (opponent)
            draw.SimpleText(topLabel, "DermaDefaultBold", w/2, 20, Color(200,200,200), TEXT_ALIGN_CENTER)
            draw.SimpleText(FormatTime(topTime), "DermaLarge", w/2, 50, 
                topTime <= 30 and Color(255,0,0) or Color(200,200,200), TEXT_ALIGN_CENTER)
            
            -- Bottom timer (player)
            draw.SimpleText(bottomLabel, "DermaDefaultBold", w/2, h-80, Color(255,255,255), TEXT_ALIGN_CENTER)
            draw.SimpleText(FormatTime(bottomTime), "DermaLarge", w/2, h-50, 
                bottomTime <= 30 and Color(255,0,0) or Color(255,255,255), TEXT_ALIGN_CENTER)
        end
        
        DrawBoard(board, turn)
    end)

    net.Receive("Chess_UpdateBoard", function()
        local board = net.ReadTable()
        local turn = net.ReadInt(3)
        LastMoveData = net.ReadTable()
        GameState = {lastMove = LastMoveData, hasMoved = {}}
        MyTurn = (turn == MyTeam)
        SelectedSquare = nil
        ValidMoves = {}
        DrawBoard(board, turn)
        if MyTurn or IsSoloMode then surface.PlaySound("buttons/blip1.wav") end
    end)

    net.Receive("Chess_UpdateTimer", function()
        WhiteTime = net.ReadInt(16)
        BlackTime = net.ReadInt(16)
    end)

    net.Receive("Chess_EndGame", function()
        local winner = net.ReadInt(3)
        local reason = net.ReadString()
        if IsValid(Frame) then Frame:Close() end
        
        BoardEntity = nil
        
        local msg = ""
        if reason == "checkmate" then
            msg = (winner == MyTeam) and "CHECKMATE - VICTORY!" or "CHECKMATE - DEFEAT!"
        elseif reason == "timeout" then
            msg = (winner == MyTeam) and "OPPONENT OUT OF TIME - VICTORY!" or "TIME OUT - DEFEAT!"
        elseif reason == "resignation" then
            msg = (winner == MyTeam) and "OPPONENT RESIGNED - VICTORY!" or "YOU RESIGNED - DEFEAT"
        elseif reason == "disconnect" then
            msg = "OPPONENT DISCONNECTED"
        else
            msg = (winner == MyTeam) and "VICTORY" or "DEFEAT"
        end
        
        chat.AddText((winner == MyTeam) and Color(0,255,0) or Color(255,0,0), "[Chess] " .. msg)
    end)
    
    -- 3D Board Rendering
    hook.Add("PostDrawOpaqueRenderables", "CHESS_FORCE_3D2D", function()
        if not IsValid(GameBoardEntity) then return end

        local pos = GameBoardEntity:GetPos()
        local ang = GameBoardEntity:GetAngles()

        cam.Start3D2D(pos + GameBoardEntity:GetUp() * 5, ang, 0.25)
            draw.SimpleText("CHESS BOARD VISIBLE", "DermaLarge", 0, 0, Color(255,0,0),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        cam.End3D2D()
    end)

end