(function () {
    "use strict";

    var players = document.querySelectorAll(".song-table audio");
    var status = document.getElementById("nowPlaying");

    function onPlay(event) {
        var activePlayer = event.currentTarget;
        for (var i = 0; i < players.length; i++) {
            if (players[i] !== activePlayer) {
                players[i].pause();
            }
        }
        status.textContent = "Reproduciendo: " + activePlayer.getAttribute("data-song-title");
    }

    function onPause() {
        for (var i = 0; i < players.length; i++) {
            if (!players[i].paused && !players[i].ended) {
                return;
            }
        }
        status.textContent = "Reproducción en pausa. Elige una canción para continuar.";
    }

    for (var i = 0; i < players.length; i++) {
        players[i].addEventListener("play", onPlay);
        players[i].addEventListener("pause", onPause);
        players[i].addEventListener("ended", onPause);
        players[i].addEventListener("error", function () {
            status.textContent = "No se pudo reproducir el audio. Comprueba que el archivo MP3 esté disponible.";
        });
    }
}());
