// ==UserScript==
// @name         JohanXTS
// @namespace    http://tampermonkey.net/
// @version      2025-01-07
// @description  try to take over the world!
// @author       You
// @match        https://agarz.com/es
// @match        https://agarz.com
// @icon         https://mir-s3-cdn-cf.behance.net/project_modules/disp/d13ba675122137.5c44239685eb3.gif
// @grant        none
// ==/UserScript==

/* ==============================
    1. VARIABLES GLOBALES
    ============================== */

document
  .querySelectorAll('link[href*="maxcdn.bootstrapcdn.com/bootstrap"]')
  .forEach((el) => el.remove());

// Cargar estilos optimizados
["//maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css"].forEach(
  (href) => {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = href;
    document.head.appendChild(link);
  },
);

let topMessage4 = "";
let presionandoH = false;
let topMessage7 = "";
let intervalID = null;
let pendingMessages = [];
let imlost = 25;
let cMacroRunning = false;
let cIntervalAS, cIntervalZX;
let spaceIntervalId;
let wMacroRunning = false;
let wIntervalId;
let topMessage5 = "";
let topMessage6 = "";
let topMessage8 = "";
// ================================
// SISTEMA AGRESIVO DE CAPTURA DE TEXTO
// ================================
let allTextData = new Map();
let textId = 0;

// Definir función ANTES de usarla
function captureText(txt, x, y) {
  txt = String(txt).trim();
  if (!txt || txt.length > 200 || txt.length < 1) return;

  const id = ++textId;
  allTextData.set(id, {
    text: txt,
    x: Math.round(x),
    y: Math.round(y),
    time: Date.now(),
    id: id,
  });

  if (allTextData.size > 2000) {
    const now = Date.now();
    for (let [k, v] of allTextData) {
      if (now - v.time > 2000) allTextData.delete(k);
    }
  }
}

console.log(
  "[AGRESIVE TEXT CAPTURE ENABLED] Intercepting: fillText, strokeText, fillRect",
);

// INTERCEPTAR TODO: fillText
const origFillText = CanvasRenderingContext2D.prototype.fillText;
CanvasRenderingContext2D.prototype.fillText = function (text, x, y) {
  captureText(String(text), x, y);
  return origFillText.call(this, text, x, y);
};

// INTERCEPTAR TODO: strokeText
const origStrokeText = CanvasRenderingContext2D.prototype.strokeText;
CanvasRenderingContext2D.prototype.strokeText = function (text, x, y) {
  captureText(String(text), x, y);
  return origStrokeText.call(this, text, x, y);
};

// INTERCEPTAR TODO: fillRect para detectar fondo
const origFillRect = CanvasRenderingContext2D.prototype.fillRect;
CanvasRenderingContext2D.prototype.fillRect = function (x, y, w, h) {
  // Esto limpia el canvas, así que limpiar buffer viejo
  if (w > 500 && h > 500) {
    // Si es un clear grande
    allTextData.clear();
  }
  return origFillRect.call(this, x, y, w, h);
};

// CREAR OVERLAY INTERACTIVO INVISIBLE
const overlay = document.createElement("div");
overlay.id = "text-capture-overlay";
overlay.style.cssText = `
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 8888;
  background: transparent;
  cursor: crosshair;
  pointer-events: none;
`;
document.body.appendChild(overlay);

// CLICK HANDLER - MÁS AGRESIVO
document.addEventListener(
  "mousedown",
  function (e) {
    const canvas = document.querySelector("canvas");
    if (!canvas || allTextData.size === 0) return;

    // Usar coordenadas del viewport directamente
    const clickX = e.clientX;
    const clickY = e.clientY;

    console.log(
      "[CLICK] Viewport (" +
        clickX.toFixed(0) +
        ", " +
        clickY.toFixed(0) +
        ") - Buffer: " +
        allTextData.size +
        " texts",
    );

    // Buscar en TODOS los textos con tolerancia GRANDE (300px)
    let best = null,
      bestDist = 300;

    for (let [id, item] of allTextData) {
      // Los textos fueron capturados en coordenadas del canvas
      // Intentar buscar aproximadamente
      const dx = clickX - item.x;
      const dy = clickY - item.y;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < bestDist) {
        bestDist = dist;
        best = item.text;
      }
    }

    if (best) {
      // COPIAR INMEDIATAMENTE
      navigator.clipboard.writeText(best).then(() => {
        console.log("[COPIED] " + best);
        // showBigNotif("COPIED\n" + best.substring(0, 50));

        // También mostrar en consola grande
        console.log(best);
      });
    } else {
      console.log(
        "[NO TEXT] Closest distance: " +
          bestDist.toFixed(0) +
          "px (threshold: 300px)",
      );
    }
  },
  true,
); // Usar capture phase

// NOTIFICACIÓN MÁS GRANDE Y VISIBLE
function showBigNotif(msg) {
  const notif = document.createElement("div");
  notif.style.cssText = `
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: rgba(39, 174, 96, 0.95);
    color: #fff;
    padding: 20px 30px;
    border-radius: 8px;
    font-size: 16px;
    font-weight: bold;
    z-index: 99999;
    border: 3px solid #1e8449;
    box-shadow: 0 0 30px rgba(39, 174, 96, 0.5);
    text-align: center;
    white-space: pre-wrap;
    animation: popIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  `;
  notif.textContent = msg;
  document.body.appendChild(notif);

  setTimeout(() => {
    notif.style.animation = "popOut 0.3s ease-out";
    setTimeout(() => notif.remove(), 300);
  }, 2500);
}

// ================================
// CONVERTIDOR DE GOLD - OVERLAY FLOTANTE
// ================================
const goldConverterOverlay = document.createElement("div");
goldConverterOverlay.id = "gold-converter-overlay";
goldConverterOverlay.style.cssText = `
  position: fixed;
  top: 500px;
  right: 20px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-family: Arial, sans-serif;
`;

goldConverterOverlay.innerHTML = `
  <input type="number" id="golcAmount" placeholder="Cantidad" min="1" step="1" 
         style="padding: 8px; background: rgba(0, 0, 0, 0.4); color: #fff; border: 1px solid rgba(255, 255, 255, 0.2); 
                 border-radius: 4px; font-size: 13px; width: 120px; outline: none;">
  <button id="golcBtn" style="padding: 8px; background: rgba(0, 0, 0, 0.5); color: #fff; border: 1px solid rgba(255, 255, 255, 0.2); 
                             border-radius: 4px; cursor: pointer; font-weight: bold; font-size: 12px;">GO</button>
  <div style="display: flex; gap: 4px;">
    <button id="golc100k" style="flex: 1; padding: 6px; background: rgba(0, 0, 0, 0.5); color: #fff; border: 1px solid rgba(255, 255, 255, 0.2);
                               border-radius: 4px; cursor: pointer; font-size: 11px;">100K</button>
    <button id="golc200k" style="flex: 1; padding: 6px; background: rgba(0, 0, 0, 0.5); color: #fff; border: 1px solid rgba(255, 255, 255, 0.2);
                               border-radius: 4px; cursor: pointer; font-size: 11px;">200K</button>
  </div>
  <div style="display: flex; gap: 4px;">
    <button id="golc1m" style="flex: 1; padding: 6px; background: rgba(0, 0, 0, 0.5); color: #fff; border: 1px solid rgba(255, 255, 255, 0.2);
                             border-radius: 4px; cursor: pointer; font-size: 11px;">1M</button>
    <button id="golc2m" style="flex: 1; padding: 6px; background: rgba(0, 0, 0, 0.5); color: #fff; border: 1px solid rgba(255, 255, 255, 0.2);
                             border-radius: 4px; cursor: pointer; font-size: 11px;">2M</button>
  </div>
`;

document.body.appendChild(goldConverterOverlay);

// Función para enviar cantidad
function sendGoldAmount(amount) {
  sendChat2(`-bt ${amount}`);
  document.getElementById("golcAmount").value = "";
}

// Event listeners para el convertidor
document.getElementById("golcBtn").addEventListener("click", () => {
  const input = document.getElementById("golcAmount");
  const amount = input.value.trim();

  if (!amount || isNaN(amount) || amount <= 0) return;
  sendGoldAmount(amount);
});

document.getElementById("golc100k").addEventListener("click", () => {
  sendGoldAmount(100000);
});

document.getElementById("golc200k").addEventListener("click", () => {
  sendGoldAmount(200000);
});

document.getElementById("golc1m").addEventListener("click", () => {
  sendGoldAmount(1000000);
});

document.getElementById("golc2m").addEventListener("click", () => {
  sendGoldAmount(2000000);
});

// ESTILOS
const st = document.createElement("style");
st.textContent = `
  @keyframes popIn {
    from { transform: translate(-50%, -50%) scale(0.5); opacity: 0; }
    to { transform: translate(-50%, -50%) scale(1); opacity: 1; }
  }
  @keyframes popOut {
    to { transform: translate(-50%, -50%) scale(0.5); opacity: 0; }
  }
  
  #sikayetContainer input[type="button"] {
    padding: 8px 12px !important;
    background: rgba(0, 0, 0, 0.5) !important;
    color: #fff !important;
    border: 1px solid rgba(34, 197, 94, 0.8) !important;
    border-radius: 4px !important;
    cursor: pointer !important;
    font-weight: bold !important;
    font-size: 12px !important;
    transition: background 0.2s ease !important;
  }
  
  #sikayetContainer input[type="button"]:hover {
    background: rgba(0, 0, 0, 0.7) !important;
    border-color: rgba(34, 197, 94, 1) !important;
  }
  
  #sikayetContainer input[type="button"]:active {
    background: rgba(0, 0, 0, 0.8) !important;
  }
  /* Aplicar mismo diseño al botón con value="Mikrofonu Aç" */
  input[type="button"][value="Mikrofonu Aç"] {
    padding: 8px 12px !important;
    background: rgba(0, 0, 0, 0.5) !important;
    color: #fff !important;
    border: 1px solid rgba(34, 197, 94, 0.8) !important;
    border-radius: 4px !important;
    cursor: pointer !important;
    font-weight: bold !important;
    font-size: 12px !important;
    transition: background 0.2s ease !important;
  }
  input[type="button"][value="Mikrofonu Aç"]:hover {
    background: rgba(0, 0, 0, 0.7) !important;
    border-color: rgba(34, 197, 94, 1) !important;
  }
  input[type="button"][value="Mikrofonu Aç"]:active {
    background: rgba(0, 0, 0, 0.8) !important;
  }
`;
document.head.appendChild(st);

console.log(
  "[*] AGRESIVE TEXT CAPTURE - Buffer: " +
    allTextData.size +
    " textos, esperando click...",
);

/* ==============================
    2. EVENTOS DE TECLADO
    ============================== */
document.addEventListener("keydown", function (e) {
  if (e.keyCode === 51 && $("input:focus").length === 0) {
    // 51 = tecla "3"
    if (presionandoH) {
      detenerAutoplay();
    } else {
      iniciarAutoplay();
    }
  }
});

window.addEventListener("keydown", keydown);
window.addEventListener("keyup", keyup);
document.addEventListener("keydown", function (event) {
  if (event.key === "Escape") {
    let dialog = document.getElementById("finalLeaderboardDialog");
    if (dialog) {
      dialog.style.display = "none";
    }
  }
});
const link = document.createElement("link");
link.rel = "stylesheet";
link.href =
  "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css";
document.head.appendChild(link);
/* ==============================
    3. AUTOPLAY Y GAME MODE
    ============================== */
$("#gamemode").on("change", function () {
  if (presionandoH) {
    simularDetener();
    setTimeout(() => {
      iniciarAutoplay();
    }, 200);
  }
});
function simularDetener() {
  presionandoH = false;
}
function detenerAutoplay() {
  presionandoH = false;
  topMessage4 = "";
}
function iniciarAutoplay() {
  presionandoH = true;
  topMessage4 = "Autoplay Activado";
  onClickPlay();
}

/* ==============================
    4. WEBSOCKET ENVÍO
    ============================== */
function wsSend(messageObj) {
  const payload = messageObj.buffer;
  if (!ws) {
    console.error("wsSend falló: instancia de WebSocket no inicializada.");
    return;
  }
  switch (ws.readyState) {
    case WebSocket.OPEN:
      try {
        ws.send(payload);
      } catch (error) {
        console.error("Error al enviar mensaje por WebSocket:", error);
      }
      break;
    case WebSocket.CONNECTING:
      console.warn("WebSocket conectando, encolando mensaje.");
      pendingMessages.push(messageObj);
      if (!ws.__esperandoConectar) {
        ws.__esperandoConectar = true;
        ws.addEventListener(
          "open",
          () => {
            console.log("WebSocket abierto, enviando mensajes pendientes...");
            while (pendingMessages.length > 0) {
              const msg = pendingMessages.shift();
              try {
                ws.send(msg.buffer);
              } catch (error) {
                console.error("Error al enviar mensaje pendiente:", error);
              }
            }
            ws.__esperandoConectar = false;
          },
          { once: true },
        );
      }
      break;
    case WebSocket.CLOSING:
      console.warn("wsSend: WebSocket está cerrándose; mensaje no enviado.");
      break;
    case WebSocket.CLOSED:
      console.warn("wsSend: WebSocket cerrado; mensaje no enviado.");
      break;
    default:
      console.warn("wsSend: estado de WebSocket inesperado:", ws.readyState);
  }
}

/* ==============================
    5. FUNCIONES DE MACROS Y CONTROL
    ============================== */
function keydown(e) {
  if ($("input:focus").length) return;
  const key = e.key ? e.key.toLowerCase() : "";
  switch (key) {
    case "1":
      // Ejecutar `reaparecer()` sólo si no estamos en modo espectador
      if (typeof playMode === "undefined" || playMode !== PLAYMODE_SPECTATE) {
        reaparecer();
      }
      break;
    case "c":
      cMacroRunning ? stopCMacro() : startCMacro();
      e.preventDefault();
      break;
    case "n":
      dikey();
      split();
      break;
    case "m":
      yanlama();
      split();
      break;
    case "x":
      beyto();
      break;
    case "q":
      fireUltraBurst();
      break;
  }
}
function keyup(e) {
  if (e.keyCode === 81 && spaceIntervalId) {
    clearInterval(spaceIntervalId);
    spaceIntervalId = null;
    e.preventDefault();
  }
}
function dispatchKey(code) {
  const down = new KeyboardEvent("keydown", {
    key: " ",
    keyCode: code,
    code: "Space",
    which: code,
    bubbles: true,
  });
  const up = new KeyboardEvent("keyup", {
    key: " ",
    keyCode: code,
    code: "Space",
    which: code,
    bubbles: true,
  });
  document.dispatchEvent(down);
  document.dispatchEvent(up);
}
function fireUltraBurst() {
  for (let i = 0; i < 100; i++) {
    setTimeout(() => {
      dispatchKey(32);
    }, i * 5);
  }
}
function startCMacro() {
  cMacroRunning = true;
  cIntervalAS = setInterval(() => {
    $("body")
      .trigger($.Event("keydown", { keyCode: 65 }))
      .trigger($.Event("keyup", { keyCode: 65 }))
      .trigger($.Event("keydown", { keyCode: 83 }))
      .trigger($.Event("keyup", { keyCode: 83 }));
  }, 50);
  $("body").trigger($.Event("keydown", { keyCode: 90 }));
  $("body").trigger($.Event("keydown", { keyCode: 88 }));
}
function stopCMacro() {
  clearInterval(cIntervalAS);
  cMacroRunning = false;
  $("body").trigger($.Event("keyup", { keyCode: 90 }));
  $("body").trigger($.Event("keyup", { keyCode: 88 }));
}
function stopWMacro() {
  clearInterval(wIntervalId);
  wMacroRunning = false;
  $("body").trigger($.Event("keyup", { keyCode: 87 }));
}

/* ==============================
    6. FUNCIONES DE JUEGO
    ============================== */
function reaparecer() {
  const select = document.getElementById("gamemode");
  const serverURL = select.value;
  if (serverURL) {
    skipPopupOnClose = true;
    reconnect = 1;
    playMode = PLAYMODE_PLAY;
    setserver4(serverURL);
  } else {
    console.warn("No hay servidor seleccionado en #gamemode.");
  }
}
function sabit() {
  const e = window.innerWidth / 2,
    n = window.innerHeight / 2;
  document
    .querySelectorAll("canvas")
    .forEach((o) =>
      o.dispatchEvent(new MouseEvent("mousemove", { clientX: e, clientY: n })),
    );
}
function yanlama() {
  const X = window.innerWidth / 0,
    Y = window.innerHeight / 25;
  $("canvas").trigger($.Event("mousemove", { clientX: X, clientY: Y }));
}
function dikey() {
  const X = window.innerWidth / 25,
    Y = window.innerHeight / 0;
  $("canvas").trigger($.Event("mousemove", { clientX: X, clientY: Y }));
}
function split() {
  $("body")
    .trigger($.Event("keydown", { keyCode: 32 }))
    .trigger($.Event("keyup", { keyCode: 32 }));
}
function beyto() {
  $("body")
    .trigger($.Event("keydown", { keyCode: 65 }))
    .trigger($.Event("keyup", { keyCode: 65 }));
}
function beytociftspace() {
  $("body")
    .trigger($.Event("keydown", { keyCode: 32 }))
    .trigger($.Event("keyup", { keyCode: 32 }));
}

const originalHandleWsMessage = window.handleWsMessage;
window.handleWsMessage = function (messageBuffer) {
  const opcode = messageBuffer.getUint8(0);
  if (opcode === OPCODE_S2C_SHOW_MESSAGE) {
    return;
  }
  if (opcode === OPCODE_S2C_INFO) {
    const infoType = messageBuffer.getInt32(1, true);

    if (infoType === INFO_YOU_DEAD) {
      closeFullscreen();
      sendUint8(OPCODE_C2S_EMITFOOD_STOP);
      playMode = PLAYMODE_NONE;
      playerId = -1;
      spectatorId = -1;
      isLockMouse = 0;
      isLockFood = 0;

      if (presionandoH) {
        onClickPlay();
      }

      return;
    }
  }
  if (
    opcode === 121 ||
    opcode === 49 ||
    opcode === 113 /* prueba con varios */
  ) {
    let txt = new TextDecoder().decode(new DataView(messageBuffer.buffer, 1));
    if (txt.toLowerCase().includes("bonus")) {
      console.log("[🎁 BONUS CAPTURADO]", txt);
    }
  }

  originalHandleWsMessage(messageBuffer);
};

/* ==============================
    7. ESTILOS Y MODIFICACIONES DOM
    ============================== */
$("#idDiscord").remove();
$("#idTwitch > div:first").remove();
$("<style>")
  .prop("type", "text/css")
  .html(
    `
     #idTwitch { top: 0 !important; }
     .btn-primary { color: #fff; background-color: #0089ff; border-color: #0088ff; outline:none; }
     .btn {outline:none!important;}
     .btn-primary.active,
     .btn-primary.focus,
     .btn-primary:active,
     .btn-primary:focus,
     .btn-primary:hover,
     .open > .dropdown-toggle.btn-primary {
          color: #fff;
          background-color: #006fd1;
          border-color: #006fd1;
     }
  `,
  )
  .appendTo("head");

/* ==============================
    8. HALL OF FAME Y SHADOW DOM
    ============================== */
(function () {
  "use strict";

  $(document).ready(function () {
    const CACHE_KEY = "tablaDatos";
    const INTERVALO_SOLICITUD = 10000;
    let timeoutActualizacion = null;
    let tiemposActuales = [];

    // Crear shadow DOM en #helloDialog
    const wrapper = document.createElement("div");
    wrapper.id = "xts-shadow-wrapper";
    const shadow = wrapper.attachShadow({ mode: "open" });
    document.getElementById("helloDialog")?.appendChild(wrapper);

    // Estilos dentro del shadow DOM
    const style = document.createElement("style");
    style.textContent = `
*,
::before,
::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

#time-master {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding: 5px;
    border-radius: 8px;
    background: #ffffff;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    color: #111;
    width: 100%;
    max-width: 600px;
    font-family: sans-serif;
    z-index: 9999;
    position: absolute;
    left: 385px;
    top: 40px;
}

.header {
    width: 100%;
    display: flex;
    justify-content: flex-end;
}

#orden-selector {
    border-radius: 6px;
    padding: 6px 10px;
    font-size: 14px;
    cursor: pointer;
    width: 100%;
    outline: none;
    border: 2px solid rgb(255, 191, 0);
    background: rgb(255, 248, 220);
    color: rgb(17, 17, 17);
}

#orden-selector:hover {
    background-color: #e0e0e0;
}

#time-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(52px, 1fr));
    gap: 5px;
    width: 100%;
}

.animated-button {
    display: flex;
    justify-content: center;
    align-items: center;
    background: #f0f8ff;
    color: #005fa3;
    font-size: 12px;
    padding: 5px 2px;
    border: 1px solid #aad4f5;
    border-radius: 8px;
    transition: all 0.2s ease;
    cursor: pointer;
    text-align: center;
    position: relative;
    box-shadow: 0 0 2px rgba(0, 95, 163, 0.15);
    height: 33px;
}

.animated-button:hover {
    background: #d6ecff;
    color: #003f7f;
    border-color: #66b3ff;
    box-shadow: 0 0 6px rgba(0, 95, 163, 0.4);
}

.animated-button::after {
    content: attr(data-tooltip);
    position: absolute;
    bottom: 110%;
    left: 50%;
    transform: translateX(-50%);
    background: #333;
    color: #fff;
    padding: 4px 8px;
    font-size: 12px;
    border-radius: 6px;
    white-space: nowrap;
    opacity: 0;
    pointer-events: none;
    transition: opacity 0.2s ease, transform 0.2s ease;
    z-index: 10;
    box-shadow: 0 0 6px rgba(0, 0, 0, 0.4);
}

.animated-button:hover::after {
    opacity: 1;
    transform: translateX(-50%) translateY(-4px);

/* Estilos para el convertidor */

`;
    shadow.appendChild(style);

    // Estructura HTML
    const container = document.createElement("div");
    container.id = "time-master";
    container.innerHTML = `
        <div class="header">
            <select id="orden-selector" title="Ordenar por">
                <option value="original">Orden original</option>
                <option value="asc">Tiempo de menor a mayor</option>
                <option value="desc">Tiempo de mayor a menor</option>
            </select>
        </div>
        <div id="time-grid"></div>
    `;
    shadow.appendChild(container);

    // Evento selector
    shadow.querySelector("#orden-selector").addEventListener("change", () => {
      actualizarLista(tiemposActuales);
    });

    // Obtener datos
    async function obtenerTiempos() {
      try {
        const response = await fetch("https://agarz.com/tr/halloffame");
        const html = await response.text();
        const doc = new DOMParser().parseFromString(html, "text/html");
        const filas = doc.querySelectorAll(".tr_oda");
        const tiempos = [];

        for (const fila of filas) {
          const minSpan = fila.querySelector('span[id^="min_"]');
          const secSpan = fila.querySelector('span[id^="sec_"]');
          if (!minSpan || !secSpan) continue;

          let min = parseInt(minSpan.innerText);
          let sec = parseInt(secSpan.innerText);
          if (sec < 50) {
            min--;
            sec += 60;
          }

          const total = min + sec / 60;
          const texto = fila.querySelector("td")?.innerText || "";
          tiempos.push({ texto, tiempo: total });
        }

        const top = tiempos.map((obj) => ({
          texto: obj.texto,
          tiempo: obj.tiempo.toFixed(2),
        }));

        localStorage.setItem(CACHE_KEY, JSON.stringify(top));
        tiemposActuales = top;
        actualizarLista(top);
      } catch (err) {
        console.error("❌ Error al obtener tiempos:", err);
      }
    }

    // Renderizar lista
    function actualizarLista(tiemposOriginales) {
      const orden = shadow.querySelector("#orden-selector").value;
      const grid = shadow.querySelector("#time-grid");
      const favorita = localStorage.getItem("salaFavorita");
      grid.innerHTML = "";

      let tiempos = [...tiemposOriginales];

      if (orden === "asc") {
        tiempos.sort((a, b) => a.tiempo - b.tiempo);
      } else if (orden === "desc") {
        tiempos.sort((a, b) => b.tiempo - a.tiempo);
      }

      for (const obj of tiempos) {
        const tiempoFmt = formatearTiempo(obj.tiempo);
        const btn = document.createElement("button");
        btn.className = "animated-button";
        btn.innerHTML = `<span>${obj.texto}</span>`;
        btn.setAttribute("data-tooltip", `${tiempoFmt}`);

        if (obj.texto === favorita) {
          btn.style.border = "2px solid #ffbf00";
          btn.style.background = "#fff8dc";
          btn.style.color = "#111";
        }

        btn.onclick = () => {
          entrarJuego(obj.texto);
          btn.blur();
        };
        btn.oncontextmenu = (e) => {
          e.preventDefault();
          localStorage.setItem("salaFavorita", obj.texto);
          actualizarLista(tiemposOriginales);
        };

        grid.appendChild(btn);
      }
    }

    function formatearTiempo(decimal) {
      const min = Math.floor(decimal);
      const sec = Math.round((decimal - min) * 60);
      return `${min}:${sec.toString().padStart(2, "0")}`;
    }

    function entrarJuego(salaTexto) {
      const select = document.getElementById("gamemode");
      const autoplay = typeof presionandoH !== "undefined" && presionandoH;
      if (autoplay) simularDetener();

      let value = [...select.options].find((opt) =>
        opt.textContent.includes(salaTexto),
      )?.value;
      if (!value) return console.warn("❌ Sala no encontrada:", salaTexto);

      select.value = value;
      select.dispatchEvent(new Event("change"));

      setTimeout(() => {
        $("#playBtn").trigger("click");
        if (autoplay) setTimeout(() => iniciarAutoplay(), 100);
      }, 500);
    }

    function iniciarActualizaciones(intervalo) {
      if (timeoutActualizacion) clearTimeout(timeoutActualizacion);
      timeoutActualizacion = setTimeout(async () => {
        await obtenerTiempos();
        iniciarActualizaciones(intervalo);
      }, intervalo);
    }

    obtenerTiempos();
    iniciarActualizaciones(INTERVALO_SOLICITUD);
  });
})();
/* ==============================
    9. FUNCIONES DE COLOR Y FORMATO
    ============================== */
function getDynamicColor() {
  const timeFactor = Date.now() * 0.002;
  const r = Math.sin(timeFactor) * 127 + 128;
  const g = Math.sin(timeFactor + 2) * 127 + 128;
  const b = Math.sin(timeFactor + 4) * 127 + 128;
  return `rgb(${r | 0},${g | 0},${b | 0})`;
}
function getDynamicShadowColor() {
  const timeFactor = Date.now() * 0.002;
  const r = Math.sin(timeFactor) * 127 + 128;
  const g = Math.sin(timeFactor + 2) * 127 + 128;
  const b = Math.sin(timeFactor + 4) * 127 + 128;
  return `rgb(${r | 0},${g | 0},${b | 0})`;
}
function formatValue(value) {
  return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

/* ==============================
    10. FUNCIONES DE JUGADOR Y SCORE
    ============================== */
function obtenerJugadorConMasMasa() {
  const celulas = cellManager.getCellList();
  if (!Array.isArray(celulas)) return null;
  const masaPorJugador = {};
  const celdasPorJugador = {};
  celulas.forEach((cell) => {
    if (cell.cellType !== CELLTYPE_PLAYER) return;
    const id = String(cell.pID);
    const score = parseFloat(cell.getScore()) || 0;
    masaPorJugador[id] = (masaPorJugador[id] || 0) + score;
    (celdasPorJugador[id] ||= []).push(cell);
  });
  const jugadores = Object.keys(masaPorJugador);
  if (!jugadores.length) {
    topMessage6 = "skor ffa: 0";
    return null;
  }
  const totalMasa = jugadores.reduce((sum, id) => sum + masaPorJugador[id], 0);
  topMessage6 = `skor ffa: ${formatValue(totalMasa)}`;
  jugadores.sort((a, b) => masaPorJugador[b] - masaPorJugador[a]);
  const [topID, runnerUpID] = jugadores;
  const topScore = masaPorJugador[topID];
  const runnerScore = masaPorJugador[runnerUpID] || 0;
  const ventajaPct = runnerScore
    ? ((topScore - runnerScore) / runnerScore) * 100
    : 100;
  const estado =
    ventajaPct < 20
      ? "❗ Amenazado"
      : ventajaPct < 50
        ? "➖ Parejo"
        : "🔱 Dominando";
  const topCell = celdasPorJugador[topID].reduce((a, b) =>
    (parseFloat(a.getScore()) || 0) > (parseFloat(b.getScore()) || 0) ? a : b,
  );
  const nombre = topCell.name || "Sin nombre";
  const cantidadPartes = celdasPorJugador[topID].length;
  topMessage5 = `Player: ${nombre}  |  Skor: ${formatValue(topScore)}  |  Partes: ${cantidadPartes}`;
  celdasPorJugador[topID].forEach((c) => (c.isTop = true));
  return {
    pID: topID,
    name: nombre,
    score: topScore,
    partes: cantidadPartes,
    estado,
    topCell,
  };
}

/* ==============================
    11. DIBUJO DE TIMER Y RECORD
    ============================== */
window.drawTimerAndRecord = function (y, fontSizeX, padding, maxTime = 600) {
  try {
    var fontSize = 20;
    let countdownTime = countdown;
    if (
      [DRAWMODE_REPLAY_PLAY, DRAWMODE_REPLAY_STOP].includes(
        cellManager.drawMode,
      )
    ) {
      const item = cellManager.getReplayItem();
      if (item) countdownTime = item.countdown;
    }
    countdownTime = Math.max(0, countdownTime);
    const getVar = (prop, key, def) =>
      getComputedStyle(document.documentElement)
        .getPropertyValue(prop)
        .trim() || loadSetting(key, def);
    if (
      !window.drawTimerAndRecord.maxRef ||
      countdownTime > window.drawTimerAndRecord.maxRef
    ) {
      window.drawTimerAndRecord.maxRef = countdownTime;
    }
    const maxRef = window.drawTimerAndRecord.maxRef;
    let timerText = this.gameName ? `${this.gameName} ` : "";
    timerText += `[${secToTime(countdownTime)}]`;
    ctx.font = `${fontSize}px Ubuntu`;
    const textWidth = ctx.measureText(timerText).width;
    const textX = (mainCanvas.width - textWidth) / 2;
    const pct = countdownTime / maxRef;
    const flash =
      countdownTime <= 10 ? 0.4 + 0.6 * Math.sin(Date.now() / 120) : 1;
    const barWidth = textWidth;
    const barHeight = 4;
    const barX = textX;
    const barY = y + fontSize + padding * 4;
    const barFill = Math.floor(barWidth * pct);
    const timerColor =
      pct > 0.5 ? "#33FF66" : pct > 0.2 ? "#FFA500" : "#FF4040";
    if (renderMode === RENDERMODE_CTX) {
      ctx.globalAlpha = 0.2;
      ctx.fillStyle = "#000";
      ctx.fillRect(
        textX - padding,
        y,
        textWidth + padding * 2,
        fontSize + padding * 2,
      );
      ctx.globalAlpha = 1;
      ctx.save();
      ctx.shadowColor = timerColor;
      ctx.shadowBlur = 8;
      ctx.globalAlpha = flash;
      ctx.fillStyle = timerColor;
      ctx.fillText(timerText, textX, y + fontSize);
      ctx.restore();
      ctx.fillStyle = "#333";
      ctx.fillRect(barX, barY, barWidth, barHeight);
      ctx.fillStyle = timerColor;
      ctx.fillRect(barX, barY, barFill, barHeight);
    }
    if (renderMode === RENDERMODE_GL) {
      prog_rect.draw(
        textX - padding,
        y,
        textWidth + padding * 2,
        fontSize + padding * 2,
        ColorManager.Current_RGB_GL.TimerAndRecord_BG,
        0.2,
      );
      prog_font.drawUI(
        textX,
        y + fontSize,
        ColorManager.rgb(timerColor),
        flash,
        fontSize,
        timerText,
      );
      prog_rect.draw(
        barX,
        barY,
        barWidth,
        barHeight,
        ColorManager.rgb(51, 51, 51),
        1,
      );
      prog_rect.draw(
        barX,
        barY,
        barFill,
        barHeight,
        ColorManager.rgb(timerColor),
        1,
      );
    }
    if (recordHolder && recordHolder.length) {
      const recordY = barY + barHeight + padding;
      const recordWidth = ctx.measureText(recordHolder).width;
      const recordX = (mainCanvas.width - recordWidth) / 2;
      if (renderMode === RENDERMODE_CTX) {
        ctx.save();
        ctx.fillStyle = "#FFFF66";
        ctx.shadowColor = "#FFFF66";
        ctx.shadowBlur = 8;
        ctx.fillText(recordHolder, recordX, recordY + fontSize);
        ctx.restore();
      } else {
        prog_font.drawUI(
          recordX,
          recordY + fontSize,
          ColorManager.rgb(255, 255, 102),
          1,
          fontSize,
          recordHolder,
        );
      }
    }
  } catch (err) {
    console.error(err);
  }
};

/* ==============================
    12. DIBUJO DE MENSAJES TOP
    ============================== */
(function () {
  window.drawTopMessage = function () {
    try {
      obtenerJugadorConMasMasa();

      // 1) Construimos el array inicial de mensajes
      const baseMsgs = [
        {
          text: topMessage1,
          colorFunc: getFluorescentGreen,
          position: "bottom",
        },
        { text: topMessage3, colorFunc: getFluorescentGreen, position: "top" },
        {
          text: topMessage2,
          colorFunc: getFluorescentGreen,
          position: "bottom",
        },
      ];

      baseMsgs.push({
        text: topMessage4,
        colorFunc: getElectricBlue,
        position: "top",
      });
      baseMsgs.push({
        text: topMessage5,
        colorFunc: getLavaPlasmaColor,
        position: "top",
      });
      baseMsgs.push({
        text: topMessage7,
        colorFunc: getLavaPlasmaColor,
        position: "top",
      });
      baseMsgs.push({
        text: topMessage6,
        colorFunc: getGoldGlow,
        position: "top",
      });

      const messages = baseMsgs.filter((m) => m.text && m.text.trim());
      function getGoldGlow() {
        const t = Date.now() * 0.006;
        const r = 255;
        const g = Math.floor(200 + Math.sin(t) * 40); // amarillo cálido que brilla
        const b = Math.floor(40 + Math.cos(t) * 30); // ligero tono cálido
        return `rgb(${r},${g},${b})`;
      }

      // 3) Función que dibuja todos los mensajes top y bottom, y devuelve el Y final
      function drawMessages(ctx, yTopStart, lineHeight) {
        const topMsgs = messages.filter((m) => m.position === "top");
        const bottomMsgs = messages.filter((m) => m.position === "bottom");

        // Dibuja top de arriba hacia abajo
        let y = yTopStart;
        for (const m of topMsgs) {
          drawSingle(ctx, m, y);
          y += lineHeight;
        }

        // Dibuja bottom de abajo hacia arriba
        let yBot = ctx.canvas.height - 10;
        for (let i = bottomMsgs.length - 1; i >= 0; i--) {
          drawSingle(ctx, bottomMsgs[i], yBot);
          yBot -= lineHeight;
        }

        return y;
      }

      // 4) Función auxiliar inalterada
      function drawSingle(ctx, { text, colorFunc }, y) {
        ctx.save();
        ctx.font = "16px Ubuntu";
        ctx.globalAlpha = 1;

        const width = ctx.measureText(text).width;
        const x = (ctx.canvas.width - width) / 2;

        if (colorFunc) {
          ctx.shadowBlur = 8 + Math.sin(Date.now() * 0.006) * 4;
          ctx.shadowColor = "rgba(220,220,220,0.5)";
          ctx.fillStyle = colorFunc(ctx, x, y, width);
        } else {
          ctx.fillStyle = "#39ff14";
        }

        ctx.fillText(text, x, y);
        ctx.restore();
      }

      function getRedOrangeGradient(ctx, x3, y3, width) {
        try {
          if (
            !ctx ||
            typeof x3 !== "number" ||
            typeof y3 !== "number" ||
            typeof width !== "number"
          ) {
            console.error(
              "Error en getRedOrangeGradient: parámetros inválidos",
            );
            return "#f00";
          }
          const t = Date.now() * 0.002;
          const startX = Math.max(0, x3 - 50);
          const endX = Math.min(ctx.canvas.width, x3 + width + 50);

          const gradient = ctx.createLinearGradient(startX, y3, endX, y3);
          gradient.addColorStop(0, `hsl(${(t * 40) % 360}, 100%, 60%)`);
          gradient.addColorStop(0.5, `hsl(${(t * 40 + 30) % 360}, 100%, 65%)`);
          gradient.addColorStop(1, `hsl(${(t * 40 + 60) % 360}, 100%, 70%)`);

          return gradient;
        } catch (error) {
          console.error("Error en getRedOrangeGradient:", error);
          try {
            return (
              ctx?.createLinearGradient?.(0, y3 || 0, 100, y3 || 0) || "#f00"
            );
          } catch {
            return "#f00";
          }
        }
      }

      function getBlueGradient(ctx, x3, y3, width) {
        try {
          if (
            !ctx ||
            typeof x3 !== "number" ||
            typeof y3 !== "number" ||
            typeof width !== "number"
          ) {
            console.error("Error en getBlueGradient: parámetros inválidos");
            return "#00f";
          }

          const t = Date.now() * 0.002;

          const startX = Math.max(0, x3 - 50);
          const endX = Math.min(ctx.canvas.width, x3 + width + 50);

          const gradient = ctx.createLinearGradient(startX, y3, endX, y3);
          gradient.addColorStop(0, `hsl(${(t * 120) % 360}, 100%, 65%)`);
          gradient.addColorStop(0.5, `hsl(${(t * 120 + 90) % 360}, 100%, 70%)`);
          gradient.addColorStop(1, `hsl(${(t * 120 + 180) % 360}, 100%, 65%)`);

          return gradient;
        } catch (error) {
          console.error("Error en getBlueGradient:", error);
          try {
            return (
              ctx?.createLinearGradient?.(0, y3 || 0, 100, y3 || 0) || "#00f"
            ); // Azul por defecto si falla todo
          } catch {
            return "#00f"; // Fallback final si incluso eso falla
          }
        }
      }

      function getLavaPlasmaColor() {
        try {
          const t = Date.now() * 0.004; // velocidad moderada
          const r = Math.floor(200 + Math.sin(t) * 55); // rojo profundo a brillante
          const g = Math.floor(50 + Math.cos(t * 1.5) * 30); // verde tenue y variable
          const b = Math.floor(150 + Math.sin(t * 1.3) * 80); // azul-violeta pulsante

          return `rgb(${r},${g},${b})`;
        } catch (error) {
          console.error("Error en getLavaPlasmaColor:", error);
          return "rgb(255, 0, 150)"; // fallback vibrante
        }
      }
      function getGoodColor() {
        try {
          const t = Date.now() * 0.004; // velocidad moderada
          const r = Math.floor(50 + Math.sin(t) * 50); // verde brillante
          const g = Math.floor(200 + Math.cos(t * 1.5) * 55); // verde claro
          const b = Math.floor(50 + Math.sin(t * 1.3) * 50); // azul brillante

          return `rgb(${r},${g},${b})`;
        } catch (error) {
          console.error("Error en getGoodColor:", error);
          return "rgb(0, 255, 0)"; // fallback verde brillante
        }
      }

      // Función para obtener el color "malo"
      function getBadColor() {
        try {
          const t = Date.now() * 0.004; // velocidad moderada
          const r = Math.floor(200 + Math.sin(t) * 55); // rojo brillante
          const g = Math.floor(50 + Math.cos(t * 1.5) * 30); // verde tenue
          const b = Math.floor(50 + Math.sin(t * 1.3) * 30); // azul apagado

          return `rgb(${r},${g},${b})`;
        } catch (error) {
          console.error("Error en getBadColor:", error);
          return "rgb(255, 0, 0)"; // fallback rojo brillante
        }
      }

      function getElectricBlue() {
        try {
          const t = Date.now() * 0.006;
          const r = Math.floor(60 + Math.sin(t) * 40); // más bajo para resaltar el azul
          const g = Math.floor(180 + Math.cos(t) * 50); // un verde claro pulsante
          const b = Math.floor(255 - Math.sin(t) * 20); // mantener azul intenso
          return `rgb(${r},${g},${b})`;
        } catch (error) {
          console.error("Error en getElectricBlue:", error);
          return "rgb(0, 0, 255)"; // Valor por defecto en caso de error
        }
      }
      function getFluorescentGreen() {
        try {
          // velocidad de pulso (ajusta si lo quieres más rápido/lento)
          const t = Date.now() * 0.005;
          // lightness oscila entre 40% y 70%
          const lightness = 55 + Math.sin(t) * 15;
          // devolvemos en HSL para garantizar todo el rango de “fluor”
          return `hsl(120, 100%, ${lightness}%)`;
        } catch (error) {
          console.error("Error en getFluorescentGreen(HSL):", error);
          // Verde puro estándar si algo falla
          return "hsl(120, 100%, 55%)";
        }
      }

      // Devuelve un color dinámico basado en el tiempo (para el texto)

      // Devuelve un tamaño de fuente dinámico (en píxeles)
      function getDynamicFontSize() {
        const t = Date.now() * 0.005;
        return 20 + Math.sin(t) * 1; // Resultado entre 19 y 21 aproximadamente
      }

      // Otra función de color dinámico, que se usará para la sombra

      switch (renderMode) {
        case RENDERMODE_CTX:
          // Dentro de tu función de dibujo:
          ctx.font = '17px "Playfair Display", serif';

          ctx.globalAlpha = 1;
          ctx.fillStyle = "#39ff14";

          const staticMessages = messages.filter((m) => m.text !== trans[308]);
          const yAfterMessages = drawMessages(ctx, 85, 26, staticMessages);
          if (countdown > 0 && countdown <= 26) {
            ctx.save();
            const bigSize = getDynamicFontSize() * 1.01;
            ctx.font = bigSize + "px Ubuntu";
            ctx.fillStyle = getDynamicColor();
            ctx.shadowBlur = 12;
            ctx.shadowColor = getDynamicShadowColor();
            const text = "ULTIMOS SEGUNDOS";
            const width = ctx.measureText(text).width;
            const x = (ctx.canvas.width - width) / 2;
            const y = yAfterMessages + 26 + 10;

            ctx.fillText(text, x, y);
            ctx.restore();
          }
          break;

        case RENDERMODE_GL:
          // Igual para GL si lo necesitas…
          break;
      }
    } catch (error) {
      console.error("Error en drawTopMessage:", error);
    }
  };
})();

/* ==============================
    13. FUNCIONES DE ENVÍO DE INICIO
    ============================== */
window.sendStart = function () {
  if (clientVersion === serverVersion) {
    sendLang();
    const token = localStorage.userToken;
    if (token != null && token.length === 32) {
      const packet = prepareData(1 + token.length * 2);
      packet.setUint8(0, OPCODE_C2S_SET_TOKEN);
      let offset = 1;
      for (let i = 0; i < token.length; i++) {
        packet.setUint16(offset, token.charCodeAt(i), true);
        offset += 2;
      }
      wsSend(packet);
    } else if (playMode === PLAYMODE_SPECTATE) {
      spectatorId = -1;
      spectatorPlayer = null;
      if (isAdminSafe()) {
        sendAdminSpectate();
      } else {
        sendUint8(OPCODE_C2S_SPECTATE_REQUEST);
      }
    } else {
      sendUint8(OPCODE_C2S_PLAY_AS_GUEST_REQUEST);
    }
  } else if (serverVersion !== 0) {
    const errorMsg = trans[0x10a];
    showGeneralError(errorMsg, `C:${clientVersion} vs S:${serverVersion}`);
  }
};

const css = `
/* Panel: tema blanco, compacto, sin zooms ni glows */
#controlPanel {
  position: fixed;
  bottom: 30px;
  left: 10px;
  display: none;
  z-index: 1001;

  width: 140px;           /* más pequeño */
  max-width: 140px;
  padding: 10px;          /* menos padding */
  border-radius: 8px;

  background: #ffffff;
  color: #111827;
  border: 1px solid #e5e7eb;          /* borde gris claro */
  box-shadow: 0 2px 8px rgba(0,0,0,.06); /* sombra sutil */
  font-family: 'Poppins', system-ui, -apple-system, Segoe UI, Roboto, Ubuntu;
  margin-bottom: 520px;   /* tal como lo tenías, ajustado un poco */
}

.control-container{
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 10px;              /* espacios compactos */
  z-index: 1;
}

/* Título sobrio tipo UI clásica */
.card-title{
  font-size: 14px;        /* más chico */
  font-weight: 700;
  text-align: center;
  margin-bottom: 6px;
  color: #1f2937;         /* gris oscuro */
  text-shadow: none;      /* sin brillos */
}

/* Etiquetas */
.label-xts-pro{
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 6px;
  font-size: 11px;        /* más chico */
  text-transform: none;   /* sin uppercase para verse más clásico */
  color: #374151;         /* gris medio */
  font-weight: 600;
}

/* Sliders: azul clásico, sin efectos exagerados */
.custom-range{
  appearance: none;
  width: 100%;
  height: 3px;
  border-radius: 3px;
  background: linear-gradient(90deg,#3b82f6,#93c5fd); /* azul */
  outline: none;
  transition: background .2s ease;
}
.custom-range:hover{ box-shadow: none; }

.custom-range::-webkit-slider-thumb{
  appearance: none;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background-color: #ffffff;
  border: 1px solid #3b82f6;     /* azul */
  box-shadow: none;               /* sin glow */
  cursor: pointer;
}
.custom-range::-moz-range-thumb{
  width: 12px; height: 12px; border-radius: 50%;
  background-color: #ffffff;
  border: 1px solid #3b82f6;
  box-shadow: none; cursor: pointer;
}

/* Contenedor de botones */
.d-flex{
  display: flex;
  gap: 6px;               /* menos separación */
  justify-content: center;
}

/* Botones mini, estilo outline azul, sin zoom */
.chat-mode-button{
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid #d1d5db;     /* borde gris claro */
  background: #ffffff;
  color: #1f2937;
  font-size: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: none;
  transition: background .15s ease, border-color .15s ease, color .15s ease;
}
.chat-mode-button:hover{
  background: #f3f4f6;            /* gris muy claro */
  border-color: #3b82f6;          /* azul al hover */
  color: #1f2937;
}
.chat-mode-button:active{ transform: none; } /* sin zoom/scale */

/* Estados activos (colores suaves, sin brillos) */
#teamButton.active{
  background: #fef9c3;            /* amarillo pálido */
  border-color: #eab308;          /* amarillo */
  color: #92400e;
  box-shadow: none;
}
#clanButton.active{
  background: #dcfce7;            /* verde pálido */
  border-color: #22c55e;          /* verde */
  color: #065f46;
  box-shadow: none;
}

/* Hover "Select me" más discreto en rojo */
#selectMeButton:hover{
  background: #fee2e2;
  border-color: #ef4444;
  color: #991b1b;
  box-shadow: none;
}

/* Badge pequeña y clara */
.badge{
  font-size: 10px;                /* más chico */
  padding: 2px 4px;
  border-radius: 4px;
  background: #e5f0ff;            /* azul muy claro */
  color: #1e40af;                 /* azul oscuro */
  border: 1px solid #c7ddff;
  user-select: none;
}
`;

const style = document.createElement("style");
style.textContent = css;
document.documentElement.appendChild(style);

const controlPanel = document.createElement("div");
controlPanel.id = "controlPanel";
controlPanel.class = "card bg-dark text-white p-3 shadow-lg";
document.body.appendChild(controlPanel);

controlPanel.innerHTML = `
<div class="blur-layer"></div>
  <div class="control-container">
  <div>
    <label for="opacityControl" class="label-xts-pro">
    Opacity <span id="opacityValue" class="badge">0.015</span>
    </label>
    <input type="range" id="opacityControl" class="custom-range" min="0.010" max="1" step="0.01" value="0.015"/>
  </div>
  <div>
    <label for="borderControl" class="label-xts-pro">
    Grosor <span id="borderValue" class="badge">2.0</span>
    </label>
    <input type="range" id="borderControl" class="custom-range" min="0" max="4.0" step="0.1" value="2.0"/>
  </div>
  <div>
    <div class="d-flex gap-2">
    <button id="teamButton" class="chat-mode-button"><i class="fas fa-users"></i></button>
    <button id="clanButton" class="chat-mode-button"><i class="fas fa-shield-alt"></i></button>
    <button id="selectMeButton" class="chat-mode-button" title="Apuntar a mí"><i class="fas fa-crosshairs"></i></button>
    </div>
  </div>
  </div>
`;

let showTeamScore = false,
  showClanScore = false,
  borderControlFactor = 2.0,
  dynamicOpacity = 0.01,
  transparentRender = false,
  controlPanelVisible = false;
const opacityControl = document.getElementById("opacityControl");
const borderControl = document.getElementById("borderControl");
const opacityValue = document.getElementById("opacityValue");
const borderValue = document.getElementById("borderValue");

function updateRangeProgress(e) {
  const v = ((e.value - e.min) / (e.max - e.min)) * 100;
  e.style.background = `linear-gradient(90deg, #0ff ${v}%, #333 ${v}%)`;
}

updateRangeProgress(opacityControl);
updateRangeProgress(borderControl);

opacityControl.addEventListener("input", () => {
  let maxOpacity = transparentRender ? 0.6 : 1;
  dynamicOpacity = parseFloat(opacityControl.value);
  if (dynamicOpacity > maxOpacity) dynamicOpacity = maxOpacity;
  opacityValue.textContent = dynamicOpacity.toFixed(3);
  updateRangeProgress(opacityControl);
});
borderControl.addEventListener("input", () => {
  borderControlFactor = parseFloat(borderControl.value);
  borderValue.textContent = borderControlFactor.toFixed(1);
  updateRangeProgress(borderControl);
});
function updateToggleButton(id, active) {
  const btn = document.getElementById(id);
  btn.classList.toggle("active", !!active);
}
document.getElementById("teamButton").addEventListener("click", () => {
  showTeamScore = !showTeamScore;
  updateToggleButton("teamButton", showTeamScore);
});
document.getElementById("clanButton").addEventListener("click", () => {
  showClanScore = !showClanScore;
  updateToggleButton("clanButton", showClanScore);
});

window.getBoardArea = () => {
  const xMin = Math.min(leftPos, rightPos),
    xMax = Math.max(leftPos, rightPos),
    xMid = (xMin + xMax) / 2;
  const yMin = Math.min(topPos, bottomPos),
    yMax = Math.max(topPos, bottomPos),
    yMid = (yMin + yMax) / 2;
  const isInside = (x, y) => x >= xMin && x <= xMax && y >= yMin && y <= yMax;
  return {
    x_min: xMin,
    x_mid: xMid,
    x_max: xMax,
    y_min: yMin,
    y_mid: yMid,
    y_max: yMax,
    width: xMax - xMin,
    height: yMax - yMin,
    center: { x: xMid, y: yMid },
    isInside,
  };
};

let isTransparentMode = false,
  selectedEnemyPID = null;
document.getElementById("selectMeButton").addEventListener("click", () => {
  selectedEnemyPID = null;
});

window.tryClickChangeSpectator = function (mouseX, mouseY) {
  try {
    if (playMode !== PLAYMODE_SPECTATE)
      return console.warn(
        "Sólo puedes cambiar de espectador en modo SPECTATE.",
      );
    const cellList = cellManager.getCellList();
    if (!Array.isArray(cellList))
      return console.error("La lista de celdas no es válida.");
    const gameCoords = cameraManager.convertPixelToGame(mouseX, mouseY);
    if (
      !gameCoords ||
      typeof gameCoords.x !== "number" ||
      typeof gameCoords.y !== "number"
    )
      return console.error("No se pudieron convertir las coordenadas.");
    let closestSize = Number.MAX_SAFE_INTEGER,
      closestPID = null;
    for (let cell of cellList) {
      if (cell.cellType !== CELLTYPE_PLAYER) continue;
      const dx = cell.x_draw - gameCoords.x,
        dy = cell.y_draw - gameCoords.y,
        dist = Math.hypot(dx, dy);
      if (dist < cell.size_draw && cell.size_draw < closestSize)
        ((closestSize = cell.size_draw), (closestPID = cell.pID));
    }
    if (closestPID !== null) {
      spectatorId = closestPID;
      selectedEnemyPID = closestPID;
      setSpectator(spectatorId);
    }
  } catch (error) {
    console.error("Ocurrió un error al intentar cambiar el espectador:", error);
  }
};

function toggleDrawOptions() {
  try {
    if (isTransparentMode) {
      if (options.get("showScore") === false) options.set("showScore", true);
      if (options.get("drawEdge") === false) options.set("drawEdge", true);
      Cell.prototype.isDrawScore = function () {
        return options.get("showScore") === true || this.pID === playerId;
      };
      Cell.prototype.isDrawSkin = function () {
        return options.get("showSkin") && this.skinName;
      };
      Cell.prototype.isDrawName = function () {
        return (options.get("showName") && this.name) || this.pID === playerId;
      };
      Cell.prototype.drawOneCell_player_ctx = function () {
        try {
          ctx.globalAlpha = options.get("transparentRender") === true ? 0.7 : 1;
          if (this.tailDbg.length) {
            ctx.strokeStyle = "#FFFFFF";
            ctx.lineWidth = 1;
            for (let i = 0; i < this.tailDbg.length; i++) {
              ctx.fillStyle = "rgba(255,255,255)";
              ctx.beginPath();
              ctx.arc(
                this.tailDbg[i].x,
                this.tailDbg[i].y,
                5,
                0,
                2 * Math.PI,
                false,
              );
              ctx.stroke();
            }
          }
          if (this.nodeDbg.length) {
            ctx.strokeStyle = "#FFFFFF";
            ctx.lineWidth = 1;
            for (let i = 0; i < this.nodeDbg.length; i++) {
              ctx.beginPath();
              ctx.arc(
                this.nodeDbg[i].x,
                this.nodeDbg[i].y,
                6,
                0,
                2 * Math.PI,
                false,
              );
              ctx.stroke();
            }
          }
          ctx.fillStyle = this.color;
          this.drawSimple(ctx);
          ctx.fill();
          if (this.isDrawSkin()) {
            const skinName = this.skinName,
              skinUrl = `//cdn.agarz.com/${
                skinName.endsWith(".png") ? skinName : skinName + ".png"
              }`;
            if (!skins[skinName]) {
              skins[skinName] = new Image();
              skins[skinName].src = skinUrl;
              skins[skinName].onload = () => (skinsLoaded[skinName] = true);
            }
            if (skinsLoaded[skinName]) {
              ctx.save();
              ctx.beginPath();
              ctx.arc(this.x_draw, this.y_draw, this.size_draw, 0, 2 * Math.PI);
              ctx.clip();
              ctx.drawImage(
                skins[skinName],
                this.x_draw - this.size_draw,
                this.y_draw - this.size_draw,
                this.size_draw * 2,
                this.size_draw * 2,
              );
              ctx.restore();
              const info = playerInfoList[this.pID];
              if (info?.uid === record_uid && record_uid !== 0)
                ctx.drawImage(
                  crownImage,
                  this.x_draw - this.size_draw * 0.5,
                  this.y_draw - this.size_draw * 2,
                  this.size_draw,
                  this.size_draw,
                );
            }
          }
          ctx.globalAlpha = 1;
          let textColor;
          if (this.pID === playerId) textColor = "#FFFFFF";
          else {
            let leaderboardEntry = getLeaderboardExt(this.pID);
            if (!leaderboardEntry) textColor = "#FFFFFF";
            else if (leaderboardEntry.sameTeam == 1) textColor = "#FFFF00";
            else if (leaderboardEntry.sameClan == 1) textColor = "#00FF00";
            else textColor = "#FFFFFF";
          }
          ctx.fillStyle = textColor;
          if (this.isDrawName()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            this.calcNameWidth(ctx);
            let textWidth = ctx.measureText(this.name).width;
            let nameX = this.x_draw - textWidth * 0.5;
            ctx.fillText(this.name, nameX, this.y_draw);
          }
          if (this.isDrawClan()) {
            let clanName = this.getClanName();
            let clanFontSize = Math.floor(this.getNameSize() * 0.5);
            ctx.font = clanFontSize + "px Ubuntu";
            let clanWidth = ctx.measureText(clanName).width;
            let clanX = this.x_draw - clanWidth * 0.5;
            ctx.fillText(clanName, clanX, this.y_draw - clanFontSize * 2);
          }
          if (this.isDrawScore()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            let scoreText = formatValue(parseFloat(this.getScore()));
            let scoreWidth = ctx.measureText(scoreText).width;
            let scoreX = this.x_draw - scoreWidth * 0.5;
            ctx.fillText(scoreText, scoreX, this.y_draw + this.getNameSize());
          }
        } catch (error) {}
      };
    } else {
      if (options.get("showScore") === true) options.set("showScore", false);
      if (options.get("drawEdge") === true) options.set("drawEdge", false);
      Cell.prototype.isDrawScore = function () {
        const leaderboardEntry = getLeaderboardExt(this.pID);
        if (this.pID === selectedEnemyPID || this.pID === playerId) return true;
        if (options.get("showScore") === true) return true;
        if (
          showTeamScore &&
          leaderboardEntry &&
          leaderboardEntry.sameTeam === 1
        )
          return true;
        if (
          showClanScore &&
          leaderboardEntry &&
          leaderboardEntry.sameClan === 1
        )
          return true;
        return false;
      };
      function mostrarJugadorClickPro(mouseX, mouseY) {
        try {
          if (playMode !== PLAYMODE_PLAY) return null;
          const cellList = cellManager.getCellList();
          if (!Array.isArray(cellList)) return null;
          const gameCoords = cameraManager.convertPixelToGame(mouseX, mouseY);
          if (
            !gameCoords ||
            typeof gameCoords.x !== "number" ||
            typeof gameCoords.y !== "number"
          )
            return null;
          let closestPlayer = null,
            closestDistance = Infinity;
          for (let i = 0; i < cellList.length; i++) {
            const cell = cellList[i];
            if (cell.cellType === CELLTYPE_PLAYER) {
              const dx = cell.x_draw - gameCoords.x,
                dy = cell.y_draw - gameCoords.y,
                distance = Math.sqrt(dx * dx + dy * dy);
              if (distance < cell.size_draw && distance < closestDistance)
                ((closestPlayer = cell), (closestDistance = distance));
            }
          }
          if (closestPlayer) {
            selectedEnemyPID = closestPlayer.pID;
            return closestPlayer.pID;
          } else return null;
        } catch (error) {
          return null;
        }
      }
      document.addEventListener("click", function (event) {
        if (playMode !== PLAYMODE_PLAY) return;
        const target = event.target;
        if (
          target.closest(
            "input, textarea, button, select, .menu, .ui, #mainMenu, .popup",
          )
        )
          return;
        mostrarJugadorClickPro(event.clientX, event.clientY);
      });
      Cell.prototype.isDrawSkin = function () {
        const leaderboardEntry = getLeaderboardExt(this.pID);
        if (!this.skinName) return false;
        if (this.pID === playerId || options.get("showSkin") === true)
          return true;
        if (
          showTeamScore &&
          leaderboardEntry &&
          leaderboardEntry.sameTeam === 1
        )
          return true;
        if (
          showClanScore &&
          leaderboardEntry &&
          leaderboardEntry.sameClan === 1
        )
          return true;
        return false;
      };
      Cell.prototype.isDrawName = function () {
        const leaderboardEntry = getLeaderboardExt(this.pID);
        if (this.pID === playerId || this.pID === selectedEnemyPID) return true;
        if (
          showTeamScore &&
          leaderboardEntry &&
          leaderboardEntry.sameTeam === 1
        )
          return true;
        if (
          showClanScore &&
          leaderboardEntry &&
          leaderboardEntry.sameClan === 1
        )
          return true;
        return false;
      };
      Cell.prototype.drawOneCell_player_ctx = function () {
        try {
          const leaderboardEntry = getLeaderboardExt(this.pID);
          const isOwn = this.pID === playerId,
            isTarget = this.pID === selectedEnemyPID;
          const isTeamMate =
            showTeamScore &&
            leaderboardEntry &&
            leaderboardEntry.sameTeam === 1;
          const isClanMate =
            showClanScore &&
            leaderboardEntry &&
            leaderboardEntry.sameClan === 1;
          const isPlayerOrAlly = isOwn || isTarget || isTeamMate || isClanMate;
          const transparentRender = options.get("transparentRender");
          ctx.globalAlpha = isPlayerOrAlly
            ? transparentRender
              ? 0.8
              : 1
            : dynamicOpacity;
          if (this.tailDbg.length) {
            ctx.strokeStyle = "#FFFFFF";
            ctx.lineWidth = 1;
            for (let i = 0; i < this.tailDbg.length; i++) {
              ctx.fillStyle = "rgba(255,255,255)";
              ctx.beginPath();
              ctx.arc(
                this.tailDbg[i].x,
                this.tailDbg[i].y,
                5,
                0,
                2 * Math.PI,
                false,
              );
              ctx.stroke();
            }
          }
          if (this.nodeDbg.length) {
            ctx.strokeStyle = "#FFFFFF";
            ctx.lineWidth = 1;
            for (let i = 0; i < this.nodeDbg.length; i++) {
              ctx.beginPath();
              ctx.arc(
                this.nodeDbg[i].x,
                this.nodeDbg[i].y,
                6,
                0,
                2 * Math.PI,
                false,
              );
              ctx.stroke();
            }
          }
          ctx.fillStyle = this.color;
          this.drawSimple(ctx);
          ctx.fill();
          if (this.isDrawSkin()) {
            const skinName = this.skinName,
              skinUrl = `//cdn.agarz.com/${
                skinName.endsWith(".png") ? skinName : skinName + ".png"
              }`;
            if (!skins[skinName]) {
              skins[skinName] = new Image();
              skins[skinName].src = skinUrl;
              skins[skinName].onload = () => (skinsLoaded[skinName] = true);
            }
            if (skinsLoaded[skinName]) {
              ctx.save();
              ctx.beginPath();
              ctx.arc(this.x_draw, this.y_draw, this.size_draw, 0, 2 * Math.PI);
              ctx.clip();
              ctx.drawImage(
                skins[skinName],
                this.x_draw - this.size_draw,
                this.y_draw - this.size_draw,
                this.size_draw * 2,
                this.size_draw * 2,
              );
              ctx.restore();
              const info = playerInfoList[this.pID];
              if (info?.uid === record_uid && record_uid !== 0)
                ctx.drawImage(
                  crownImage,
                  this.x_draw - this.size_draw * 0.5,
                  this.y_draw - this.size_draw * 2,
                  this.size_draw,
                  this.size_draw,
                );
            }
          }
          ctx.globalAlpha = 1;
          let lineWidth = Math.min(
            210,
            Math.max(0, this.size_draw * 0.1 * borderControlFactor),
          );
          let strokeColor = "#FFFFFF",
            threshold = 216000;
          if (
            document.getElementById("vsffa") &&
            document.getElementById("vsffa").selected
          )
            threshold = 176000;
          else if (
            document.getElementById("tffa1") &&
            document.getElementById("tffa1").selected
          )
            threshold = 246000;
          let baseLineWidth = Math.min(
            210,
            Math.max(0, this.size_draw * 0.1 * borderControlFactor),
          );
          if (isOwn || isTeamMate || isClanMate || isTarget) {
            if (isOwn) {
              strokeColor = "#FFFFFF";
              lineWidth = baseLineWidth;
              if (this.getScore() > threshold) {
                const time = Date.now(),
                  pulse = (Math.sin(time / 200) + 1) / 2;
                lineWidth = baseLineWidth + pulse * 80;
                strokeColor = "rgba(255,0,0,1)";
                ctx.save();
                ctx.shadowColor = strokeColor;
                ctx.shadowBlur = 20 + pulse * 30;
                ctx.strokeStyle = strokeColor;
                ctx.lineWidth = lineWidth;
                ctx.beginPath();
                ctx.arc(
                  this.x_draw,
                  this.y_draw,
                  this.size_draw - lineWidth / 2,
                  0,
                  2 * Math.PI,
                );
                ctx.stroke();
                ctx.restore();
              } else {
                ctx.save();
                ctx.strokeStyle = strokeColor;
                ctx.lineWidth = lineWidth;
                ctx.beginPath();
                ctx.arc(
                  this.x_draw,
                  this.y_draw,
                  this.size_draw - lineWidth / 2,
                  0,
                  2 * Math.PI,
                );
                ctx.stroke();
                ctx.restore();
              }
            } else if (isTarget) {
              strokeColor = "#FFFFFF";
              ctx.save();
              ctx.strokeStyle = strokeColor;
              ctx.lineWidth = baseLineWidth;
              ctx.beginPath();
              ctx.arc(
                this.x_draw,
                this.y_draw,
                this.size_draw - baseLineWidth / 2,
                0,
                2 * Math.PI,
              );
              ctx.stroke();
              ctx.restore();
            } else if (isTeamMate) {
              strokeColor = ColorManager.Current.Name_SameTeamOnMap;
              ctx.save();
              ctx.strokeStyle = strokeColor;
              ctx.lineWidth = baseLineWidth;
              ctx.beginPath();
              ctx.arc(
                this.x_draw,
                this.y_draw,
                this.size_draw - baseLineWidth / 2,
                0,
                2 * Math.PI,
              );
              ctx.stroke();
              ctx.restore();
            } else if (isClanMate) {
              strokeColor = ColorManager.Current.Name_SameClanOnList;
              ctx.save();
              ctx.strokeStyle = strokeColor;
              ctx.lineWidth = baseLineWidth;
              ctx.beginPath();
              ctx.arc(
                this.x_draw,
                this.y_draw,
                this.size_draw - baseLineWidth / 2,
                0,
                2 * Math.PI,
              );
              ctx.stroke();
              ctx.restore();
            }
          }
          let textColor;
          if (this.pID === playerId) textColor = "#FFFFFF";
          else {
            let leaderboardEntry = getLeaderboardExt(this.pID);
            if (!leaderboardEntry) textColor = "#FFFFFF";
            else if (leaderboardEntry.sameTeam == 1) textColor = "#FFFF00";
            else if (leaderboardEntry.sameClan == 1) textColor = "#00FF00";
            else textColor = "#FFFFFF";
          }
          ctx.fillStyle = textColor;
          if (this.isDrawName()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            this.calcNameWidth(ctx);
            let textWidth = ctx.measureText(this.name).width;
            let nameX = this.x_draw - textWidth * 0.5;
            ctx.fillText(this.name, nameX, this.y_draw);
          }
          if (this.isDrawClan()) {
            let clanName = this.getClanName();
            let clanFontSize = Math.floor(this.getNameSize() * 0.5);
            ctx.font = clanFontSize + "px Ubuntu";
            let clanWidth = ctx.measureText(clanName).width;
            let clanX = this.x_draw - clanWidth * 0.5;
            ctx.fillText(clanName, clanX, this.y_draw - clanFontSize * 2);
          }
          if (this.isDrawScore()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            let scoreText = formatValue(parseFloat(this.getScore()));
            let scoreWidth = ctx.measureText(scoreText).width;
            let scoreX = this.x_draw - scoreWidth * 0.5;
            ctx.fillText(scoreText, scoreX, this.y_draw + this.getNameSize());
          }
          if (this.isDrawUID()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            let uidText = spectatorPlayer.name;
            let uidWidth = ctx.measureText(uidText).width;
            let uidX = this.x_draw - uidWidth * 0.5;
            ctx.fillText(uidText, uidX, this.y_draw - this.getNameSize());
          }
        } catch (error) {}
      };
    }
    isTransparentMode = !isTransparentMode;
    controlPanelVisible = !controlPanelVisible;
    controlPanel.style.display = controlPanelVisible ? "block" : "none";
  } catch (error) {}
}

document.addEventListener("keydown", function (event) {
  try {
    if (
      event.key === "4" && // Tecla número 4
      document.activeElement.tagName !== "INPUT" &&
      document.activeElement.tagName !== "TEXTAREA"
    ) {
      setTimeout(toggleDrawOptions, 0);
    }
  } catch (error) {
    console.error("Error handling keydown event: ", error);
  }
});
