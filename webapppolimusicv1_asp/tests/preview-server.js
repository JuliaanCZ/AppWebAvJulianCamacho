"use strict";
// Servidor exclusivo de pruebas: sirve una captura HTML de la plantilla ASP.
// No ejecuta backend ni admite escrituras. Nunca se utiliza para la aplicación.
const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const project = path.resolve(__dirname, "..");
const types = { ".css": "text/css", ".js": "text/javascript", ".png": "image/png", ".jpg": "image/jpeg", ".mp3": "audio/mpeg", ".asp": "text/html; charset=utf-8" };
const server = http.createServer((request, response) => {
    let url;
    try { url = decodeURIComponent(new URL(request.url, "http://localhost").pathname); }
    catch { response.writeHead(400).end(); return; }
    let file;
    if (url === "/" || url === "/index.asp") file = path.join(__dirname, ".preview", "index.asp");
    else if (url === "/responsive.asp") file = path.join(__dirname, ".preview", "responsive.asp");
    else if (url === "/styles.css" || url === "/player.js") file = path.join(project, url.slice(1));
    else if (url.startsWith("/SongFilesAndImages_resources/")) {
        const root = path.join(project, "SongFilesAndImages_resources");
        file = path.resolve(project, url.slice(1));
        if (!file.startsWith(root + path.sep) || ![".png", ".jpg", ".mp3"].includes(path.extname(file))) file = null;
    }
    if (!file || !fs.existsSync(file)) { response.writeHead(404).end(); return; }
    const size = fs.statSync(file).size;
    const headers = { "Content-Type": types[path.extname(file)], "Cache-Control": "no-store", "Accept-Ranges": "bytes" };
    const match = /^bytes=(\d+)-(\d*)$/.exec(request.headers.range || "");
    if (match) {
        const start = Number(match[1]);
        const end = match[2] ? Math.min(Number(match[2]), size - 1) : size - 1;
        if (start > end || start >= size) { response.writeHead(416, { "Content-Range": `bytes */${size}` }).end(); return; }
        response.writeHead(206, { ...headers, "Content-Range": `bytes ${start}-${end}/${size}`, "Content-Length": end - start + 1 });
        fs.createReadStream(file, {start, end}).pipe(response);
    } else {
        response.writeHead(200, { ...headers, "Content-Length": size });
        fs.createReadStream(file).pipe(response);
    }
});
server.listen(8099, "127.0.0.1", () => process.stdout.write("Pruebas de interfaz: http://127.0.0.1:8099/index.asp\n"));
