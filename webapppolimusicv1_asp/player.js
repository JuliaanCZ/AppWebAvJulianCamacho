"use strict";

(() => {
    const audio = document.getElementById("audio");
    if (!audio) return;

    const $ = (id) => document.getElementById(id);
    const cards = [...document.querySelectorAll(".song-card")];
    const tracks = cards.map((card) => ({
        id: card.dataset.trackId,
        title: card.dataset.title,
        artist: card.dataset.artist,
        album: card.dataset.album,
        cover: card.dataset.cover,
        src: card.dataset.audio,
        card
    }));
    const user = document.body.dataset.userId;
    const storageKey = `frecuencia:favorites:${user}`;
    const volumeKey = `frecuencia:volume:${user}`;
    const progress = $("progress");
    const volume = $("volume");
    const playButton = $("toggle-play");
    const status = $("player-status");
    const search = $("search");
    let current = null;
    let filter = "all";
    let shuffled = false;
    let playVersion = 0;
    let statusTimer;
    let favorites = new Set();

    function announce(message, isError = false) {
        clearTimeout(statusTimer);
        status.textContent = message;
        status.classList.toggle("is-error", isError);
        statusTimer = setTimeout(() => { status.textContent = ""; }, 7000);
    }

    try {
        const stored = JSON.parse(localStorage.getItem(storageKey) || "[]");
        if (Array.isArray(stored)) {
            favorites = new Set(stored.filter((id) => tracks.some((track) => track.id === id)));
        }
        const storedVolume = localStorage.getItem(volumeKey);
        const savedVolume = storedVolume === null ? 0.7 : Number(storedVolume);
        if (Number.isFinite(savedVolume) && savedVolume >= 0 && savedVolume <= 1) {
            volume.value = String(savedVolume);
        }
    } catch {
        // El reproductor también funciona cuando el navegador bloquea localStorage.
    }
    audio.volume = Number(volume.value);

    function formatTime(seconds) {
        if (!Number.isFinite(seconds) || seconds < 0) return "0:00";
        return `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, "0")}`;
    }

    function paintPlay(button, isPlaying) {
        const path = button.querySelector("path");
        if (!path) return;
        path.setAttribute("d", isPlaying ? "M8 5v14M16 5v14" : "m9 5 11 7-11 7z");
        path.setAttribute("fill", isPlaying ? "none" : "currentColor");
        path.setAttribute("stroke", isPlaying ? "currentColor" : "none");
        path.setAttribute("stroke-width", "4");
    }

    function syncPlayback() {
        const playing = Boolean(current && !audio.paused && !audio.ended);
        paintPlay(playButton, playing);
        playButton.setAttribute("aria-label", playing ? "Pausar" : "Reproducir");
        tracks.forEach((track) => {
            const active = Boolean(current && track.id === current.id);
            track.card.classList.toggle("is-current", active);
            track.card.classList.toggle("is-playing", active && playing);
            const button = track.card.querySelector("[data-play]");
            paintPlay(button, active && playing);
            button.setAttribute("aria-label", `${active && playing ? "Pausar" : "Reproducir"} ${track.title}`);
        });
        $("hero-play").setAttribute("aria-label", playing ? "Pausar canción actual" : "Reproducir catálogo");
        paintPlay($("hero-play"), playing);
    }

    function syncFavorites() {
        document.querySelectorAll("[data-like]").forEach((button) => {
            const liked = favorites.has(button.dataset.like);
            button.setAttribute("aria-pressed", String(liked));
            const track = tracks.find((item) => item.id === button.dataset.like);
            button.setAttribute("aria-label", `${liked ? "Quitar de favoritas" : "Me gusta"}: ${track.title}`);
        });
        $("favorite-count").textContent = String(favorites.size);
        const liked = Boolean(current && favorites.has(current.id));
        $("player-like").setAttribute("aria-pressed", String(liked));
        $("player-like").setAttribute("aria-label", liked ? "Quitar canción actual de favoritas" : "Me gusta la canción actual");
    }

    function normalized(text) {
        return text.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLocaleLowerCase("es");
    }

    function applyFilter() {
        const query = normalized(search.value.trim());
        let count = 0;
        tracks.forEach((track) => {
            const inFilter = filter === "all" || (filter === "available" && track.src) || (filter === "favorites" && favorites.has(track.id));
            const matches = normalized(`${track.title} ${track.artist} ${track.album}`).includes(query);
            track.card.hidden = !(inFilter && matches);
            if (!track.card.hidden) count++;
        });
        $("result-count").textContent = `${count} ${count === 1 ? "canción" : "canciones"}`;
        $("empty-state").hidden = count !== 0;
        $("empty-description").textContent = filter === "favorites" && !query
            ? "Pulsa el corazón de una canción para encontrarla aquí."
            : "Prueba otra búsqueda o cambia el filtro del catálogo.";
        document.querySelectorAll("[data-filter]").forEach((button) => {
            const selected = button.dataset.filter === filter;
            button.classList.toggle("selected", selected);
            button.setAttribute("aria-pressed", String(selected));
        });
        document.querySelectorAll(".main-nav .nav-link").forEach((link) => {
            link.classList.toggle("active", filter === "favorites" ? link.dataset.view === "favorites" : link.matches("[aria-current]"));
        });
        $("hero-play").disabled = !tracks.some((track) => track.src && !track.card.hidden) && !current;
    }

    function toggleFavorite(id) {
        if (favorites.has(id)) favorites.delete(id);
        else favorites.add(id);
        try {
            localStorage.setItem(storageKey, JSON.stringify([...favorites]));
        } catch {
            announce("Tu navegador no permite guardar los likes. Se conservarán mientras esta página esté abierta.", true);
        }
        syncFavorites();
        applyFilter();
    }

    function queue() {
        const visible = tracks.filter((track) => track.src && !track.card.hidden);
        return visible.length ? visible : tracks.filter((track) => track.src);
    }

    async function startPlayback() {
        const version = ++playVersion;
        try {
            await audio.play();
            if (version === playVersion) syncPlayback();
        } catch (error) {
            if (version !== playVersion || error.name === "AbortError") return;
            syncPlayback();
            announce(error.name === "NotAllowedError"
                ? "Pulsa Play para permitir la reproducción en tu navegador."
                : "No pudimos reproducir este audio. Comprueba que el archivo esté disponible.", true);
        }
    }

    function selectTrack(track) {
        if (!track || !track.src) return;
        ++playVersion;
        audio.pause();
        current = track;
        audio.src = track.src;
        $("player-title").textContent = track.title;
        $("player-artist").textContent = track.artist;
        $("player-cover").src = track.cover;
        $("player-cover").hidden = false;
        $("player-placeholder").hidden = true;
        $("player-like").disabled = false;
        [playButton, $("previous"), $("next"), $("shuffle"), $("repeat")].forEach((button) => { button.disabled = false; });
        progress.value = "0";
        progress.disabled = true;
        $("elapsed").textContent = "0:00";
        $("duration").textContent = "0:00";
        syncFavorites();
        syncPlayback();
        startPlayback();
    }

    function togglePlay() {
        if (!current) {
            selectTrack(queue()[0]);
        } else if (audio.paused) {
            startPlayback();
        } else {
            ++playVersion;
            audio.pause();
        }
    }

    function moveTrack(direction) {
        const available = queue();
        if (!available.length) return;
        if (direction < 0 && current && audio.currentTime > 3) {
            audio.currentTime = 0;
            startPlayback();
            return;
        }
        const position = available.findIndex((track) => current && track.id === current.id);
        if (shuffled && available.length > 1) {
            const choices = available.filter((track) => !current || track.id !== current.id);
            selectTrack(choices[Math.floor(Math.random() * choices.length)]);
        } else {
            const next = position < 0 ? 0 : (position + direction + available.length) % available.length;
            selectTrack(available[next]);
        }
    }

    function updateDuration() {
        const ready = Number.isFinite(audio.duration) && audio.duration > 0;
        progress.disabled = !ready;
        $("duration").textContent = formatTime(audio.duration);
        if (ready && current) {
            const label = current.card.querySelector("[data-duration]");
            label.textContent = formatTime(audio.duration);
        }
    }

    $("song-grid").addEventListener("click", (event) => {
        const like = event.target.closest("[data-like]");
        if (like) { toggleFavorite(like.dataset.like); return; }
        const play = event.target.closest("[data-play]");
        if (!play || play.disabled) return;
        const track = tracks.find((item) => item.id === play.dataset.play);
        if (current && track.id === current.id) togglePlay();
        else selectTrack(track);
    });
    playButton.addEventListener("click", togglePlay);
    $("hero-play").addEventListener("click", togglePlay);
    $("previous").addEventListener("click", () => moveTrack(-1));
    $("next").addEventListener("click", () => moveTrack(1));
    $("player-like").addEventListener("click", () => { if (current) toggleFavorite(current.id); });
    $("shuffle").addEventListener("click", () => {
        shuffled = !shuffled;
        $("shuffle").setAttribute("aria-pressed", String(shuffled));
        announce(shuffled ? "Reproducción aleatoria activada." : "Reproducción en orden activada.");
    });
    $("repeat").addEventListener("click", () => {
        audio.loop = !audio.loop;
        $("repeat").setAttribute("aria-pressed", String(audio.loop));
        announce(audio.loop ? "La canción actual se repetirá." : "Repetición desactivada.");
    });
    audio.addEventListener("play", syncPlayback);
    audio.addEventListener("pause", syncPlayback);
    audio.addEventListener("ended", () => moveTrack(1));
    audio.addEventListener("loadedmetadata", updateDuration);
    audio.addEventListener("durationchange", updateDuration);
    audio.addEventListener("error", () => {
        progress.disabled = true;
        syncPlayback();
        announce("Este audio no está disponible o su formato no es compatible. Puedes elegir otra canción.", true);
    });
    audio.addEventListener("timeupdate", () => {
        $("elapsed").textContent = formatTime(audio.currentTime);
        if (Number.isFinite(audio.duration) && audio.duration > 0) {
            progress.value = String(Math.round((audio.currentTime / audio.duration) * 1000));
            progress.setAttribute("aria-valuetext", `${formatTime(audio.currentTime)} de ${formatTime(audio.duration)}`);
        }
    });
    progress.addEventListener("input", () => {
        if (Number.isFinite(audio.duration) && audio.duration > 0) {
            audio.currentTime = (Number(progress.value) / 1000) * audio.duration;
        }
    });

    function syncVolume() {
        const muted = audio.muted || audio.volume === 0;
        volume.value = muted ? "0" : String(audio.volume);
        $("mute").setAttribute("aria-pressed", String(muted));
        $("mute").setAttribute("aria-label", muted ? "Activar sonido" : "Silenciar");
    }
    volume.addEventListener("input", () => {
        audio.volume = Number(volume.value);
        audio.muted = audio.volume === 0;
        try { localStorage.setItem(volumeKey, String(audio.volume)); } catch { /* Volumen solo en memoria. */ }
        syncVolume();
    });
    $("mute").addEventListener("click", () => {
        if (audio.volume === 0) { audio.volume = 0.7; audio.muted = false; }
        else audio.muted = !audio.muted;
        syncVolume();
    });
    document.querySelectorAll("[data-filter]").forEach((button) => {
        button.addEventListener("click", () => { filter = button.dataset.filter; applyFilter(); });
    });
    document.querySelectorAll("[data-view]").forEach((button) => {
        button.addEventListener("click", () => {
            filter = button.dataset.view;
            search.value = "";
            applyFilter();
            $("catalogo").scrollIntoView({ block: "start" });
        });
    });
    search.addEventListener("input", applyFilter);
    document.addEventListener("keydown", (event) => {
        const editing = event.target.closest("input, textarea, select, button, a, [contenteditable='true']");
        if (event.key === "Escape" && event.target === search) search.blur();
        if (editing || event.ctrlKey || event.metaKey || event.altKey || event.repeat) return;
        if (event.key === "/") { event.preventDefault(); search.focus(); }
        if (event.code === "Space" && tracks.some((track) => track.src)) { event.preventDefault(); togglePlay(); }
    });
    syncFavorites();
    syncVolume();
    applyFilter();
})();
