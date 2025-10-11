import express from "express";
import router from "./router/router.js";
import {createServer} from "node:http"
import {Server} from "socket.io";
import {v4 as uuidv4} from 'uuid';
import cors from "cors";
import { Caret, Player, Room, GameConfig } from './common/types.js'

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

const rooms: Record<string, Room> = {}

io.on("connection", (socket) => {
    console.log("Connected:", socket.id);

    socket.on("createRoom", ({playerName}) => {
        const roomId = uuidv4().slice(0, 6);
        const config = {
            words: ["apple", "banana", "cherry", "monkey", "typewriter"],
            duration: 15,
        };
        rooms[roomId] = {
            roomId: roomId,
            players: [{id: socket.id, playerName, progress: {caret: {caretIdx: -1, wordIdx: 0}}, isHost: true}],
            config,
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

        const player = {id: socket.id, playerName, progress: {caret: {caretIdx: -1, wordIdx: 0}}, isHost: false};
        room.players.push(player);

        socket.join(roomId);
        io.to(roomId).emit("roomJoined", room);
    });

    socket.on("startGame", ({ roomId }) => {
        io.to(roomId).emit("gameStarted", roomId);
    })

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

    socket.on("disconnect", () => {
        for (const roomId in rooms) {
            const room = rooms[roomId];
            if (!room) return
            room.players = room.players.filter((p) => p.id !== socket.id);
            io.to(roomId).emit("playerUpdated", room.players);
        }
    });
});

export default app;
