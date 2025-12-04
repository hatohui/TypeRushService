import express from "express";
import router from "./router/router.js";
import {createServer} from "node:http"
import {Server} from "socket.io";
import {v4 as uuidv4} from 'uuid';
import cors from "cors";
import {GameConfig, PlayerStats, Room, WaveRushRoundResultType} from './common/types.js'

const app = express();

app.use(cors())
app.use(express.json());
app.use(router);

app.get('/', (req, res) => {
    res.send('<h1>Hello world</h1>');
});

export const server = createServer(app);

const io = new Server(server, {
    cors: {
        origin: "http://localhost:5173",
        methods: ["GET", "POST"],
    },
});

function resetGameState(room : Room) {
    if (room.transitionTimer) {
        clearTimeout(room.transitionTimer);
        room.transitionTimer = null;
    }
    room.typeRaceGameResult = [];
    room.waveRushGameResult = {
        byPlayer: {},
        byRound: {},
        currentRound: 0,
    };
    room.gameStartTime = null;
    room.players.forEach(player => {
        player.progress.caret = { caretIdx: -1, wordIdx: 0 };
    });
    room.players = room.players.filter(player => !player.isDisconnected)
}

const rooms: Record<string, Room> = {}

io.on("connection", (socket) => {
    console.log("Connected:", socket.id);

    socket.on("configChange", ({config, roomId}: {config: GameConfig, roomId: string}) => {
        const room = rooms[roomId];
        if (!room) return

        const player = room.players.find(p => p.id === socket.id);
        if (!player?.isHost) {
            io.to(socket.id).emit("errorEvent", {type: "UNAUTHORIZED", message: "Only host can change config"});
            return;
        }

        room.config = config;

        io.to(roomId).emit("configChanged", config);
    })

    socket.on("createRoom", ({playerName} : {playerName: string}) => {
        const roomId = uuidv4().slice(0, 6);
        const config : GameConfig = {
            words: ["apple", "banana", "cherry", "monkey", "typewriter"],
            mode: 'type-race',
            // duration: 5,
            // waves: 3,
            // timeBetweenRounds: 3,
        }
        rooms[roomId] = {
            roomId: roomId,
            players: [{id: socket.id, playerName, progress: {caret: {caretIdx: -1, wordIdx: 0}}, isHost: true, isDisconnected: false}],
            config,
            typeRaceGameResult: [],
            waveRushGameResult: {
                byPlayer: {},
                byRound: {},
                currentRound: 0,
            },
            gameStartTime: null,
            transitionTimer: null,
        };
        socket.join(roomId);
        io.to(roomId).emit("roomCreated", rooms[roomId]);
    });

    socket.on("joinRoom", ({roomId, playerName}: {roomId: string, playerName: string}) => {
        const room = rooms[roomId];
        if (!room) {
            io.to(socket.id).emit("errorEvent", {type: "ROOM_NOT_EXIST", message: "Room not exist"})
            return
        }
        if (room.players.length >= 4) {
            io.to(socket.id).emit("errorEvent", {type: "ROOM_FULL", message: "Room is full"})
            return
        }
        if (room.gameStartTime) {
            io.to(socket.id).emit("errorEvent", {type: "GAME_IN_PROGRESS", message: "Game is in progress"})
            return
        }

        const player = {id: socket.id, playerName, progress: {caret: {caretIdx: -1, wordIdx: 0}}, isHost: false, isDisconnected: false};
        room.players.push(player);

        socket.join(roomId);
        io.to(roomId).emit("roomJoined", room);
    });

    socket.on("startGame", ({ roomId }: {roomId: string}) => {
        const room = rooms[roomId];
        if (!room) return;

        const player = room.players.find(p => p.id === socket.id);
        if (!player?.isHost) {
              io.to(socket.id).emit("errorEvent", {type: "UNAUTHORIZED", message: "Only host can start game"});
             return;
        }

        resetGameState(room);
        room.gameStartTime = Date.now();

        io.to(roomId).emit("gameStarted");
        //io.to(roomId).emit("playersUpdated", room.players);
    });

    socket.on("stopGame", ({ roomId }: {roomId: string}) => {
        const room = rooms[roomId];
        if (!room) return;

        const player = room.players.find(p => p.id === socket.id);
        if (!player?.isHost) {
            io.to(socket.id).emit("errorEvent", {type: "UNAUTHORIZED", message: "Only host can stop the game"});
            return;
        }

        resetGameState(room);

        io.to(roomId).emit("gameStopped");
        io.to(roomId).emit("playersUpdated", room.players);
    });

    socket.on("updateCaret", ({caretIdx, wordIdx, roomId}: {caretIdx: number, wordIdx: number, roomId: string}) => {
        const room = rooms[roomId];
        if (!room) return;

        const player = room.players.find(p => p.id === socket.id);
        if (player) {
            player.progress.caret = { caretIdx, wordIdx };
        }

        io.to(roomId).emit("caretUpdated", {
            playerId: socket.id,
            caret: { caretIdx, wordIdx }
        });
    })

    socket.on("playerFinished", ({roomId, stats}: {roomId: string, stats: PlayerStats}) => {
        const room = rooms[roomId];
        if (!room) return;

        const mode = room.config.mode;
        const gameStartTime = room.gameStartTime;

        if (!gameStartTime || mode !== "type-race") return;

        const isInRoom = room.players.find(p => p.id === socket.id)
        if (!isInRoom) {
            io.to(socket.id).emit("errorEvent", {type: "NOT_IN_ROOM", message: "You are not in this room"});
            return;
        }

        const existingResult = room.typeRaceGameResult.find(
                       r => r.playerId === socket.id
        );

        if (existingResult) {
         console.log(`Duplicate submission from ${socket.id}, ignoring`);
          return;
        }

        room.typeRaceGameResult.push({playerId: socket.id, stats: stats});

        io.to(roomId).emit("typeRaceGameResultUpdated", socket.id, stats);

        const activePlayersCount = room.players.filter(player => !player.isDisconnected).length; //only count isDisconnected = false

        if (room.typeRaceGameResult.length === activePlayersCount) {
            io.to(roomId).emit("gameFinished");
            resetGameState(room);
        }

        io.to(roomId).emit("playersUpdated", room.players);
    })

    socket.on("playerFinishRound", ({roomId, results} : {roomId: string, results: WaveRushRoundResultType}) => {
        const room = rooms[roomId];
        if (!room) return;

        const mode = room.config.mode;
        const gameStartTime = room.gameStartTime;
        if (!gameStartTime || mode !== "wave-rush") return;

        const isInRoom = room.players.find(p => p.id === socket.id);
        if (!isInRoom) {
            io.to(socket.id).emit("errorEvent", {type: "NOT_IN_ROOM", message: "You are not in this room"});
            return;
        }

        // Never trust client-sent playerId: override with socket id
        results.playerId = socket.id;

        const currentRound = room.waveRushGameResult.currentRound;

        // Check if player already submitted for this round (prevent duplicates)
        const existingResult = room.waveRushGameResult.byRound[currentRound]?.find(
            r => r.playerId === results.playerId
        );

        if (existingResult) {
            console.log(`Duplicate submission from ${results.playerId} for round ${currentRound}, ignoring`);
            return;
        }

        // Initialize arrays if they don't exist
        if (!room.waveRushGameResult.byRound[currentRound]) {
            room.waveRushGameResult.byRound[currentRound] = [];
        }
        if (!room.waveRushGameResult.byPlayer[results.playerId]) {
            room.waveRushGameResult.byPlayer[results.playerId] = [];
        }

        room.waveRushGameResult.byRound[currentRound]?.push(results);
        room.waveRushGameResult.byPlayer[results.playerId]?.push(results);
        console.log(`Player ${results.playerId} finished round ${currentRound}. Total: ${room.waveRushGameResult.byRound[currentRound]?.length}/${room.players.length}`);

        io.to(roomId).emit("waveRushGameStateUpdated", room.waveRushGameResult);

        const activePlayersCount = room.players.filter(player => !player.isDisconnected).length;

        if (room.waveRushGameResult.byRound[currentRound]?.length === activePlayersCount) {
            console.log(`✅ All players finished round ${currentRound}, starting transition`);
            io.to(roomId).emit("startTransition");
            const transitionDuration = room.config.mode === 'wave-rush'
                ? (room.config.timeBetweenRounds || 5) * 1000 + 1000
                : 5000;

            room.transitionTimer = setTimeout(() => {
                if (!rooms[roomId]) return;

                room.waveRushGameResult.currentRound += 1;

                if (room.config.mode === 'wave-rush' && room.waveRushGameResult.currentRound >= room.config.waves) {
                    io.to(roomId).emit("gameFinished")
                    resetGameState(room)
                    io.to(roomId).emit("playersUpdated", room.players)
                    return;
                }

                // Broadcast new round
                io.to(roomId).emit("waveRushGameStateUpdated", room.waveRushGameResult);
                io.to(roomId).emit("nextRoundStarted");

                room.transitionTimer = null;
            }, transitionDuration);
        }
    });

    socket.on("disconnect", () => {
        for (const roomId in rooms) {
            const room = rooms[roomId];
            if (!room) continue;

            // Find the player in the room
            const player = room.players.find(p => p.id === socket.id);
            if (!player) continue;

            player.isDisconnected = true;
            console.log('player disconnected:', player.playerName);

            if (player.isHost) {
                player.isHost = false; // unset host
                const nextHost = room.players.find(p => !p.isDisconnected);
                if (nextHost) {
                    nextHost.isHost = true;
                    console.log('new host assigned:', nextHost.playerName);
                    io.to(nextHost.id).emit("hostChanged")
                }
            }

            if (!room.gameStartTime) {
                room.players = room.players.filter(player => !player.isDisconnected);
            }

            io.to(roomId).emit("playersUpdated", room.players);

            const allDisconnected = room.players.every(p => p.isDisconnected);
            if (allDisconnected) {
                console.log('all players disconnected, deleting room:', roomId);
                delete rooms[roomId];
            }
        }
    });
});

export default app;
