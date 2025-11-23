import express from "express";
import router from "./router/router.js";
import {createServer} from "node:http"
import {Server} from "socket.io";
import {v4 as uuidv4} from 'uuid';
import cors from "cors";
import {GameConfig, Room, WaveRushRoundResultType} from './common/types.js'

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
}

const rooms: Record<string, Room> = {}

io.on("connection", (socket) => {
    console.log("Connected:", socket.id);

    socket.on("configChange", ({config, roomId}) => {
        const room = rooms[roomId];
        if (!room) return
        room.config = config;

        io.to(roomId).emit("configChanged", config);
    })

    socket.on("createRoom", ({playerName}) => {
        const roomId = uuidv4().slice(0, 6);
        const config : GameConfig = {
            words: [["apple", "banana", "cherry", "monkey", "typewriter"]],
            mode: 'wave-rush',
            duration: 4,
            waves: 3,
            timeBetweenRounds: 3,
        }
        rooms[roomId] = {
            roomId: roomId,
            players: [{id: socket.id, playerName, progress: {caret: {caretIdx: -1, wordIdx: 0}}, isHost: true}],
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

    socket.on("joinRoom", ({roomId, playerName}) => {
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
        }

        const player = {id: socket.id, playerName, progress: {caret: {caretIdx: -1, wordIdx: 0}}, isHost: false};
        room.players.push(player);

        socket.join(roomId);
        io.to(roomId).emit("roomJoined", room);
    });

    socket.on("startGame", ({ roomId }) => {
        const room = rooms[roomId];
        if (!room) return;

        resetGameState(room);
        room.gameStartTime = Date.now();

        io.to(roomId).emit("gameStarted");
        io.to(roomId).emit("playersUpdated", room.players);
    });

    socket.on("stopGame", ({ roomId }) => {
        const room = rooms[roomId];
        if (!room) return;

        // ✅ Clear transition timer if exists
        if (room.transitionTimer) {
            clearTimeout(room.transitionTimer);
            room.transitionTimer = null;
        }

        resetGameState(room);

        io.to(roomId).emit("gameStopped");
        io.to(roomId).emit("playersUpdated", room.players);
    });

    socket.on("updateSharedTextbox", ({input, roomId}) => {
        const room = rooms[roomId];

        if (!room) {
            return
        }

        io.to(roomId).emit("updateTextbox", input);
    })

    socket.on("updateCaret", ({caretIdx, wordIdx, roomId}) => {
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

    socket.on("playerFinished", ({roomId, stats}) => {
        const room = rooms[roomId];
        if (!room) return;

        room.typeRaceGameResult.push({playerId: socket.id, stats: stats});

        io.to(roomId).emit("typeRaceGameResultUpdated", socket.id, stats);

        if (room.typeRaceGameResult.length === room.players.length) {
            io.to(roomId).emit("gameFinished");
        }
    })

    socket.on("playerFinishRound", ({roomId, results} : {roomId: string, results: WaveRushRoundResultType}) => {
        const room = rooms[roomId];
        if (!room) return;
        const gameStartTime = room.gameStartTime;
        if (!gameStartTime) return;

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

        if (room.waveRushGameResult.byRound[currentRound]?.length === room.players.length) {
            console.log(`✅ All players finished round ${currentRound}, starting transition`);
            io.to(roomId).emit("startTransition");
            const transitionDuration = room.config.mode === 'wave-rush'
                ? (room.config.timeBetweenRounds || 5) * 1000 + 1000
                : 5000;

            room.transitionTimer = setTimeout(() => {
                if (!rooms[roomId]) return;

                room.waveRushGameResult.currentRound += 1;

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
            if (!room) return
            room.players = room.players.filter((p) => p.id !== socket.id);
            io.to(roomId).emit("playersUpdated", room.players);
        }
    });
});

export default app;
