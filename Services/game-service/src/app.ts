import express from "express";
import router from "./router/router.js";
import { createServer } from "node:http"
import {Server} from "socket.io";
import { v4 as uuidv4 } from 'uuid';
import cors from "cors";

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

type Player = {
    id: string
    name: string
}

type GameConfig = {
    words: string[]
    duration: number
}

type Room = {
    roomId: string
    players: Player[]
    config: GameConfig
}

const rooms: Record<string, Room> = {}

io.on("connection", (socket) => {
    console.log("Connected:", socket.id);

    socket.on("createRoom", ({ name }) => {
        const roomId = uuidv4().slice(0, 6);
        const config = {
            words: ["apple", "banana", "cherry", "monkey", "typewriter"],
            duration: 60,
        };
        rooms[roomId] = {
            roomId: roomId,
            players: [{ id: socket.id, name }],
            config,
        };
        socket.join(roomId);
        io.to(roomId).emit("roomCreated", rooms[roomId]);
    });

    socket.on("joinRoom", ({ roomId, name }) => {
        const room = rooms[roomId];
        if (!room) {
            io.to(socket.id).emit("errorEvent", { type: "ROOM_NOT_EXIST", message: "Room not exist" })
            return
        }
        if (room.players.length >= 4) {
            io.to(socket.id).emit("errorEvent", { type: "ROOM_FULL", message: "Room is full" })
            return
        }

        const player = { id: socket.id, name };
        room.players.push(player);

        socket.join(roomId);
        io.to(roomId).emit("roomJoined", room);
    });

    socket.on("disconnect", () => {
        for (const roomId in rooms) {
            const room = rooms[roomId];
            if (!room) return
            room.players = room.players.filter((p) => p.id !== socket.id);
            io.to(roomId).emit("playerUpdate", room.players);
        }
    });
});

export default app;
