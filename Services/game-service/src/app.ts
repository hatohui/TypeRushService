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

io.on("connection", (socket) => {
    console.log("Connected:", socket.id);

    // socket.on("createRoom", () => {
    //     const roomId = uuidv4().slice(0, 6);
    //     const config = {
    //         words: ["apple", "banana", "cherry", "monkey", "typewriter"],
    //         duration: 60,
    //     };
    //     rooms[roomId] = { players: [], config };
    //     socket.join(roomId);
    //     socket.emit("roomCreated", roomId, config);
    // });
    //
    // socket.on("joinRoom", ({ roomId, name }) => {
    //     const room = rooms[roomId];
    //     if (!room) return;
    //     if (room.players.length >= 4) return; // max 4 players
    //
    //     const player = { id: socket.id, name, progress: 0 };
    //     room.players.push(player);
    //
    //     socket.join(roomId);
    //     io.to(roomId).emit("roomJoined", roomId, room.players, room.config);
    // });
    //
    // socket.on("updateProgress", (progress) => {
    //     for (const roomId in rooms) {
    //         const room = rooms[roomId];
    //         const player = room.players.find((p) => p.id === socket.id);
    //         if (player) {
    //             player.progress = progress;
    //             io.to(roomId).emit("playerUpdate", room.players);
    //         }
    //     }
    // });
    //
    // socket.on("disconnect", () => {
    //     for (const roomId in rooms) {
    //         const room = rooms[roomId];
    //         room.players = room.players.filter((p) => p.id !== socket.id);
    //         io.to(roomId).emit("playerUpdate", room.players);
    //     }
    // });
});

export default app;
