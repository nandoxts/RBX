// ==UserScript==
// @name         KAS ORO
// @namespace    http://tampermonkey.net/
// @version      2025-06-20
// @description  try to take over the world!
// @author       You
// @match        https://agarz.com/
// @icon         https://www.google.com/s2/favicons?sz=64&domain=agarz.com
// @grant        none
// ==/UserScript==

//autobotpro
var topMessage8 = "";

// dibujar los top messages
// Dibujar tiempo de sala y propietario del récord con fondo degradado visible
window.drawTimerAndRecord = function (y, fontSize, padding) {
  try {
    fontSize = 25;
    const t = Date.now() * 0.0003;

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
    if (
      !window.drawTimerAndRecord.maxRef ||
      countdownTime > window.drawTimerAndRecord.maxRef
    ) {
      window.drawTimerAndRecord.maxRef = countdownTime;
    }
    const timerText = `${this.gameName ? this.gameName + " " : ""}[${secToTime(
      countdownTime,
    )}]`;
    ctx.font = `bold ${fontSize}px 'Rajdhani', sans-serif`;
    const textWidth = ctx.measureText(timerText).width;
    const textX = (mainCanvas.width - textWidth) / 2;

    // Posición para el récord
    const recordFontSize = fontSize - 3;
    const recordLabel = recordHolder && recordHolder.length ? recordHolder : "";
    ctx.font = `bold ${recordFontSize}px 'Rajdhani', sans-serif`;
    const recordWidth = ctx.measureText(recordLabel).width;
    const recordX = (mainCanvas.width - recordWidth) / 2;
    const recordY = y + fontSize + padding * 3;

    if (renderMode === RENDERMODE_CTX) {
      const totalHeight =
        fontSize +
        padding * 2 +
        (recordLabel ? recordFontSize + padding * 4 : 0);

      // Fondo degradado superior (como ya lo tienes)
      const gradTop = ctx.createLinearGradient(0, y, 0, y + totalHeight);
      gradTop.addColorStop(0, "rgba(0, 0, 0, 0.7)");
      gradTop.addColorStop(0.5, "rgba(0, 0, 0, 0.3)");
      gradTop.addColorStop(1, "rgba(0, 0, 0, 0)");

      ctx.save();
      ctx.fillStyle = gradTop;
      ctx.fillRect(0, y, mainCanvas.width, totalHeight);
      ctx.restore();

      // Fondo degradado inferior (pegado abajo)
      const bottomY = mainCanvas.height - totalHeight;
      const gradBottom = ctx.createLinearGradient(
        0,
        bottomY + totalHeight,
        0,
        bottomY,
      );
      gradBottom.addColorStop(0, "rgba(0, 0, 0, 0.7)");
      gradBottom.addColorStop(0.5, "rgba(0, 0, 0, 0.3)");
      gradBottom.addColorStop(1, "rgba(0, 0, 0, 0)");
      ctx.save();
      ctx.fillStyle = gradBottom;
      ctx.fillRect(0, bottomY, mainCanvas.width, totalHeight);
      ctx.restore();
      // Texto del timer con sombra azul neón
      ctx.save();
      ctx.font = `bold ${fontSize}px 'Rajdhani', sans-serif`;
      ctx.shadowColor = "#66ccff";
      ctx.shadowBlur = 12;
      ctx.fillStyle = "#66ccff";
      ctx.fillText(timerText, textX, y + fontSize);
      ctx.restore();
      // Texto del récord (si hay)
      if (recordLabel) {
        ctx.save();
        ctx.font = `bold ${recordFontSize}px 'Rajdhani', sans-serif`;
        ctx.shadowColor = "#FFFF66";
        ctx.shadowBlur = 8;
        ctx.fillStyle = "#FFFF66";
        ctx.fillText(recordLabel, recordX, recordY + recordFontSize);
        ctx.restore();
      }
    } else if (renderMode === RENDERMODE_GL) {
      return; // sin render para GL
    }
  } catch (err) {
    console.error("drawTimerAndRecord error:", err);
  }
};

(function () {
  const floatingMessages = [];

  window.addFloatingMessage = function (text, color = "#fff") {
    floatingMessages.push({
      text,
      color,
      y: canvas.height - 50,
      opacity: 1,
      created: Date.now(),
    });
  };

  window.drawTopMessage = function () {
    try {
      const tGlobal = Date.now() * 0.0003;
      const fontsize = 17;

      const baseMsgs = [
        {
          text: topMessage1,
          colorFunc: (ctx, x, y, width) => {
            const l = 60 + Math.sin(Date.now() * 0.003) * 20;
            return `hsl(190, 100%, ${l}%)`;
          },
          position: "bottom",
        },
        {
          text: topMessage2,
          colorFunc: (ctx, x, y, width) => "#ff4444",
          position: "top",
        },
        {
          text: topMessage3,
          colorFunc: (ctx, x, y, width) => {
            const l = 60 + Math.sin(Date.now() * 0.003) * 20;
            return `hsl(120, 100%, ${l}%)`;
          },
          position: "top",
        },
        {
          text: topMessage8,
          colorFunc: (ctx, x, y, width) => {
            const l = 60 + Math.sin(Date.now() * 0.003) * 20;
            return `hsl(120, 100%, ${l}%)`;
          },
          position: "top",
        },
      ];

      const messages = baseMsgs.filter((m) => m.text && m.text.trim());

      function drawMessages(ctx, yTopStart, lineHeight) {
        const topMsgs = messages.filter((m) => m.position === "top");
        const bottomMsgs = messages.filter((m) => m.position === "bottom");

        let y = yTopStart;
        for (const m of topMsgs) {
          drawSingle(ctx, m, y);
          y += lineHeight;
        }

        let yBot = ctx.canvas.height - 10;
        for (let i = bottomMsgs.length - 1; i >= 0; i--) {
          drawSingle(ctx, bottomMsgs[i], yBot);
          yBot -= lineHeight;
        }

        return y;
      }

      function drawSingle(ctx, { text, colorFunc }, y) {
        ctx.font = `bold ${fontsize}px 'Rajdhani', sans-serif`;
        ctx.globalAlpha = 1;

        const width = ctx.measureText(text).width;
        const x = (ctx.canvas.width - width) / 2;

        if (colorFunc) {
          ctx.fillStyle = colorFunc(ctx, x, y, width);
        } else {
          ctx.fillStyle = "#39ff14";
        }

        ctx.fillText(text, x, y);
      }

      function drawFloatingMessages(ctx) {
        const now = Date.now();
        for (let i = floatingMessages.length - 1; i >= 0; i--) {
          const m = floatingMessages[i];
          const age = now - m.created;
          if (age > 4000) {
            floatingMessages.splice(i, 1);
            continue;
          }

          const y = m.y - age * 0.05;
          const alpha = 1 - age / 4000;

          ctx.globalAlpha = alpha;
          ctx.font = "18px Orbitron";
          ctx.fillStyle = m.color;
          const width = ctx.measureText(m.text).width;
          const x = (ctx.canvas.width - width) / 2;
          ctx.fillText(m.text, x, y);
        }
        ctx.globalAlpha = 1;
      }

      function getRGBNeonGradient(ctx, x, y, width, t) {
        const startX = Math.max(0, x - 50);
        const endX = Math.min(ctx.canvas.width, x + width + 50);
        const gradient = ctx.createLinearGradient(startX, y, endX, y);

        const colors = [
          `hsl(${(t * 360 + 0) % 360}, 100%, 60%)`,
          `hsl(${(t * 360 + 60) % 360}, 100%, 60%)`,
          `hsl(${(t * 360 + 120) % 360}, 100%, 60%)`,
          `hsl(${(t * 360 + 180) % 360}, 100%, 60%)`,
        ];

        const step = 1 / (colors.length - 1);
        colors.forEach((c, i) => gradient.addColorStop(i * step, c));
        return gradient;
      }

      function getDynamicFontSize() {
        const t = Date.now() * 0.005;
        return 20 + Math.sin(t) * 1;
      }

      function getDynamicColor(t) {
        return `hsl(${(t * 360) % 360}, 100%, 70%)`;
      }

      function getDynamicShadowColor(t) {
        return `hsl(${(t * 360) % 360}, 100%, 80%)`;
      }

      switch (renderMode) {
        case RENDERMODE_CTX:
          ctx.font = `bold ${fontsize}px 'Rajdhani', sans-serif`;
          ctx.globalAlpha = 1;
          ctx.fillStyle = "#39ff14";

          const staticMessages = messages.filter((m) => m.text !== trans[308]);
          const yAfterMessages = drawMessages(ctx, 75, 26, staticMessages);

          if (countdown > 0 && countdown <= 26) {
            ctx.save();
            const bigSize = getDynamicFontSize() * 1.01;
            ctx.font = `bold ${bigSize}px 'Rajdhani', sans-serif`;
            ctx.fillStyle = getDynamicColor(tGlobal);
            ctx.shadowBlur = 12;
            ctx.shadowColor = getDynamicShadowColor(tGlobal);
            const text = "ULTIMOS SEGUNDOS";
            const width = ctx.measureText(text).width;
            const x = (ctx.canvas.width - width) / 2;
            const y = yAfterMessages + 26 + 10;

            ctx.fillText(text, x, y);
            ctx.restore();
          }

          drawFloatingMessages(ctx);
          break;

        case RENDERMODE_GL:
          break;
      }
    } catch (error) {
      console.error("Error en drawTopMessage:", error);
    }
  };
})();

//autobotpro

let autoVirus = false;
let interval = null;
let virusBotInterval = null;
// Falta esta declaración al inicio
let feedingInterval = null;
const moveInterval = 50;

// Sistema anti-detección
const antiDetection = {
  baseInterval: 30,
  intervalVariation: 15, // ±15ms de variación
  lastActionTime: 0,
  minActionDelay: 100,
  maxActionDelay: 300,

  // Patrones de movimiento aleatorio
  getRandomInterval: function () {
    return (
      this.baseInterval +
      (Math.random() * this.intervalVariation * 2 - this.intervalVariation)
    );
  },

  // Delay aleatorio entre acciones
  getRandomDelay: function () {
    return (
      this.minActionDelay +
      Math.random() * (this.maxActionDelay - this.minActionDelay)
    );
  },

  // Verificar si puede ejecutar acción (anti-spam)
  canExecuteAction: function () {
    const now = Date.now();
    if (now - this.lastActionTime < this.getRandomDelay()) {
      return false;
    }
    this.lastActionTime = now;
    return true;
  },

  // Añadir ruido mínimo al movimiento (optimizado)
  addMovementNoise: function (x, y, intensity = 2) {
    const noiseX = (Math.random() - 0.5) * intensity;
    const noiseY = (Math.random() - 0.5) * intensity;
    return {
      x: x + noiseX,
      y: y + noiseY,
    };
  },

  // Simulación de comportamiento optimizado
  humanBehavior: {
    microMovements: 0.1, // 10% chance de micro-movimientos (reducido)
    shouldMicroMove: function () {
      return Math.random() < this.microMovements;
    },
  },
};

function simulateKeyPress(key) {
  if (typeof key !== "string" || !key) {
    console.error("Invalid key:", key);
    return; // Si el key no es válido, no ejecutamos el resto del código.
  }

  // Anti-detección: delay aleatorio y timing humanizado
  if (!antiDetection.canExecuteAction()) {
    return;
  }

  const randomDelay = 30 + Math.random() * 40; // 30-70ms delay aleatorio

  const eventDown = new KeyboardEvent("keydown", {
    key,
    keyCode: key.toUpperCase().charCodeAt(0),
    which: key.toUpperCase().charCodeAt(0),
    bubbles: true,
  });
  document.dispatchEvent(eventDown);

  setTimeout(() => {
    const eventUp = new KeyboardEvent("keyup", {
      key,
      keyCode: key.toUpperCase().charCodeAt(0),
      which: key.toUpperCase().charCodeAt(0),
      bubbles: true,
    });
    document.dispatchEvent(eventUp);
  }, randomDelay);
}

function simulateKeyRelease(key) {
  if (typeof key !== "string" || !key) {
    console.error("Invalid key:", key);
    return; // Si el key no es válido, no ejecutamos el resto del código.
  }
  const eventUp = new KeyboardEvent("keyup", {
    key,
    keyCode: key.toUpperCase().charCodeAt(0),
    which: key.toUpperCase().charCodeAt(0),
    bubbles: true,
  });
  document.dispatchEvent(eventUp);
}

function getPlayerCell() {
  const cellList = cellManager.getCellList();
  let closest = null;
  let closestDistance = Infinity;
  for (let i = 0; i < cellList.length; i++) {
    const cell = cellList[i];
    if (cell.cellType === CELLTYPE_PLAYER) {
      const dx = cell.x_draw - gameCoords.x;
      const dy = cell.y_draw - gameCoords.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < cell.size_draw && dist < closestDistance) {
        closest = cell;
        closestDistance = dist;
      }
    }
  }
  return closest;
}

function getNearestVirus(cell) {
  const celulas = cellManager.getCellList();
  let nearest = null;
  let minDist = Infinity;
  celulas.forEach((c) => {
    if (c.cellType === CELLTYPE_VIRUS) {
      const dx = c.x_draw - cell.x_draw;
      const dy = c.y_draw - cell.y_draw;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < minDist) {
        minDist = dist;
        nearest = c;
      }
    }
  });
  return { virus: nearest, distance: minDist };
}

function getMyMainCell() {
  const celulas = cellManager.getCellList();
  if (!Array.isArray(celulas) || celulas.length === 0) return null;
  const misCeldas = celulas.filter(
    (c) => c.cellType === CELLTYPE_PLAYER && c.pID === playerId,
  );
  if (misCeldas.length === 0) return null;

  return misCeldas.reduce((a, b) => (a.size_draw > b.size_draw ? a : b));
}
function agruparVirus(celdasVirus, distanciaMax = 300) {
  const grupos = [];

  celdasVirus.forEach((v) => {
    let agregado = false;
    for (let grupo of grupos) {
      for (let otro of grupo) {
        const dx = v.x_draw - otro.x_draw;
        const dy = v.y_draw - otro.y_draw;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < distanciaMax) {
          grupo.push(v);
          agregado = true;
          break;
        }
      }
      if (agregado) break;
    }
    if (!agregado) grupos.push([v]);
  });

  return grupos;
}

let tick = 0;

function simulateKeyDown(key) {
  const eventDown = new KeyboardEvent("keydown", {
    key,
    keyCode: key.toUpperCase().charCodeAt(0),
    which: key.toUpperCase().charCodeAt(0),
    bubbles: true,
  });
  document.dispatchEvent(eventDown);
}
function obtenerGrupoVirusRelevante() {
  const todas = cellManager.getCellList();
  const virus = todas.filter((c) => c.cellType === CELLTYPE_VIRUS);
  const grupos = agruparVirus(virus);
  if (grupos.length === 0) return null;

  const miMain = getMyMainCell();
  if (!miMain) return null;

  const misCeldas = todas.filter(
    (c) => c.cellType === CELLTYPE_PLAYER && c.pID === miMain.pID,
  );
  if (misCeldas.length === 0) return null;

  const centro = {
    x: misCeldas.reduce((sum, c) => sum + c.x_draw, 0) / misCeldas.length,
    y: misCeldas.reduce((sum, c) => sum + c.y_draw, 0) / misCeldas.length,
  };

  const enemyCeldas = todas.filter(
    (c) => c.cellType === CELLTYPE_PLAYER && c.pID !== miMain.pID,
  );
  const SAFE_DIST = 100;
  const myScore = misCeldas.reduce(
    (acc, c) =>
      acc + (typeof c.getScore === "function" ? c.getScore() : c.size),
    0,
  );

  let mejorGrupo = null;
  let mejorPuntaje = -Infinity;

  for (const grupo of grupos) {
    let esAmenazado = false;
    let hayTeammateEnGrupo = false; // ⬅️ NUEVO: detectar si hay teammate cerca del grupo

    for (const virus of grupo) {
      for (const enemigo of enemyCeldas) {
        // 1. Obtener tamaños reales
        const enemigoSize =
          typeof enemigo.getScore === "function"
            ? enemigo.getScore()
            : enemigo.size;
        const miCelulaMasGrande = Math.max(
          ...misCeldas.map((c) =>
            typeof c.getScore === "function" ? c.getScore() : c.size,
          ),
        );

        // 2. Solo considerar enemigos PELIGROSOS (más grandes que tu célula más grande)
        if (enemigoSize <= miCelulaMasGrande * 1.25) {
          continue; // Enemigo pequeño, no es amenaza
        }

        // 2.5. Verificar si es compañero de equipo (teammate) - MISMO SISTEMA QUE ULTIMATE.JS
        const esTeammate =
          enemigo.pID && getLeaderboardExt?.(enemigo.pID)?.sameTeam === 1;
        const esClanMate =
          enemigo.pID && getLeaderboardExt?.(enemigo.pID)?.sameClan === 1;
        const esAliado = esTeammate || esClanMate; // ⬆️ EVITAR TEAMMATES Y CLANMATES

        // 3. Calcular distancia enemigo → virus
        const dx = virus.x_draw - enemigo.x_draw;
        const dy = virus.y_draw - enemigo.y_draw;
        const distVirusEnemigo = Math.hypot(dx, dy);

        // 4. Radio de amenaza: aliados pueden estar MUY cerca, enemigos más lejos
        const radioAmenaza = esAliado
          ? 10 + enemigoSize * 0.005
          : 150 + enemigoSize * 0.04; // ⬆️ AUMENTADO de 80 a 150 (mayor detección virus)

        // 4.5. NUEVO: Si hay ALIADO cerca del virus, EVITAR ESTE GRUPO COMPLETAMENTE
        // Radio de detección aumentado: 400px para detectar aliados que defienden virus
        if (esAliado && distVirusEnemigo < 400) {
          const tipo = esTeammate ? "TEAM" : "CLAN";
          console.warn(
            `[AUTO-VIRUS] ⛔ EVITAR: ${tipo} (${enemigoSize.toFixed(
              0,
            )}) defendiendo virus a ${distVirusEnemigo.toFixed(0)}px`,
          );
          hayTeammateEnGrupo = true;
          break; // No ir por este grupo
        }

        // 5. Verificar si enemigo está cerca del virus (solo ENEMIGOS reales)
        if (!esAliado && distVirusEnemigo < radioAmenaza) {
          console.warn(
            `[AUTO-VIRUS] ❌ Virus: enemigo (${enemigoSize.toFixed(
              0,
            )}) a ${distVirusEnemigo.toFixed(
              0,
            )}px de virus (amenaza=${radioAmenaza.toFixed(0)})`,
          );
          esAmenazado = true;
          break;
        }

        // 6. Verificar distancia enemigo → TUS CÉLULAS
        for (const miCelda of misCeldas) {
          const dxMia = miCelda.x_draw - enemigo.x_draw;
          const dyMia = miCelda.y_draw - enemigo.y_draw;
          const distAMi = Math.hypot(dxMia, dyMia);

          // Detectar aliados cercanos a nuestras células también
          if (esAliado && distAMi < 400) {
            console.warn(
              `[AUTO-VIRUS] ⛔ EVITAR: Aliado cerca de nuestras células a ${distAMi.toFixed(0)}px`,
            );
            hayTeammateEnGrupo = true;
            break;
          }

          // Radio de seguridad: IGUALES para aliados y enemigos (ambos pueden interferi)
          const radioSeguridad = 1800 + enemigoSize * 0.12; // ⬆️ MISMO RADIO PARA TODOS (aliados también pueden interferir)

          if (distAMi < radioSeguridad) {
            const tipo = esAliado ? "ALIADO" : "enemigo";
            console.warn(
              `[AUTO-VIRUS] ❌ TU: ${tipo} (${enemigoSize.toFixed(
                0,
              )}) a ${distAMi.toFixed(
                0,
              )}px de TI (seguridad=${radioSeguridad.toFixed(0)})`,
            );
            esAmenazado = true;
            break;
          }
        }

        if (esAmenazado || hayTeammateEnGrupo) break;
      }
      if (esAmenazado || hayTeammateEnGrupo) break;
    }

    // NUEVO: Saltar este grupo SI hay teammate O si hay enemigo amenazante
    if (esAmenazado || hayTeammateEnGrupo) continue;
    // Calcular centro del grupo
    const centroGrupo = {
      x: grupo.reduce((s, c) => s + c.x_draw, 0) / grupo.length,
      y: grupo.reduce((s, c) => s + c.y_draw, 0) / grupo.length,
    };

    const dx = centroGrupo.x - centro.x;
    const dy = centroGrupo.y - centro.y;
    const dist = Math.hypot(dx, dy);
    const puntaje = grupo.length * 1000 - dist;

    if (puntaje > mejorPuntaje) {
      mejorPuntaje = puntaje;
      mejorGrupo = grupo;
    }
  }

  return mejorGrupo;
}

// Intervalo dinámico anti-detección
const getMoveInterval = () => antiDetection.getRandomInterval();

function sendBotMouseMove(x, y) {
  if (wsIsOpen()) {
    // Anti-detección: ruido mínimo optimizado
    const noisyPosition = antiDetection.addMovementNoise(x, y, 3);

    var buf = prepareData(0x15);
    buf.setUint8(0x0, OPCODE_C2S_MOUSE_MOVE);
    buf.setFloat64(0x1, noisyPosition.x, true);
    buf.setFloat64(0x9, noisyPosition.y, true);
    buf.setUint16(0x11, 0x0, true);
    wsSend(buf);
  }
}

function stopFeeding() {
  if (!autoVirus) return;
  autoVirus = false;
  sendUint8(OPCODE_C2S_EMITFOOD_STOP);
  clearInterval(feedingInterval); // Usar clearInterval porque usamos setInterval
  simulateKeyRelease(" ");
  isLockMouse = 0;
  console.log("[AUTO-VIRUS] Detenido.");
  topMessage8 = "";
}
let spinAngle = 0;
let lastSpinDirection = 1; // Para cambiar dirección aleatoriamente
let spinChangeCounter = 0;

// ACTIVACION CON TECLA - Presiona 'V' para activar/desactivar
document.addEventListener("keydown", function (e) {
  if (e.key === "v" || e.key === "V") {
    toggleFeeding();
    console.log("[KAS ORO] Bot " + (autoVirus ? "ACTIVADO" : "DESACTIVADO"));
  }
});

function getSpiralTarget(grupo) {
  // 1) Calcular centroide
  const centro = grupo.reduce(
    (acc, v) => {
      acc.x += v.x_draw;
      acc.y += v.y_draw;
      return acc;
    },
    { x: 0, y: 0 },
  );
  centro.x /= grupo.length;
  centro.y /= grupo.length;

  // 2) Calcular radio medio (distancia media al centro)
  const avgR =
    grupo.reduce(
      (sum, v) => sum + Math.hypot(v.x_draw - centro.x, v.y_draw - centro.y),
      0,
    ) / grupo.length;

  // 2.1) Radio optimizado con mínima variación
  const baseReduction = 0.5 + Math.random() * 0.1; // 0.5-0.6 variación reducida
  const reducedR = avgR * baseReduction;

  // 3) Sistema anti-detección optimizado
  spinChangeCounter++;
  if (spinChangeCounter > 80 + Math.random() * 40) {
    // Cambiar cada 80-120 iteraciones (más estable)
    lastSpinDirection *= -1;
    spinChangeCounter = 0;
  }

  // 4) Velocidad de rotación más consistente
  const baseSpeed = 0.04 + Math.random() * 0.02; // 0.04-0.06 velocidad más consistente
  spinAngle += baseSpeed * lastSpinDirection;

  // 5) Coordenada del punto giratorio con patrón impredecible
  const spiralVariation = Math.sin(spinAngle * 3) * 0.2; // Variación en el patrón
  const finalRadius = reducedR * (1 + spiralVariation);

  const targetX = centro.x + finalRadius * Math.cos(spinAngle);
  const targetY = centro.y + finalRadius * Math.sin(spinAngle);

  // 6) Encontrar el virus más cercano al punto giratorio
  let nearest = grupo[0],
    minD = Infinity;
  for (const v of grupo) {
    const d = Math.hypot(v.x_draw - targetX, v.y_draw - targetY);
    if (d < minD) {
      minD = d;
      nearest = v;
    }
  }

  // 7) Ruido mínimo final al objetivo
  const noisyTarget = antiDetection.addMovementNoise(
    nearest.x_draw,
    nearest.y_draw,
    4,
  );
  return {
    x_draw: noisyTarget.x,
    y_draw: noisyTarget.y,
  };
}

function startFeeding() {
  if (autoVirus) {
    console.log("[AUTO-VIRUS] Ya está activado.");
    return;
  }
  autoVirus = true;
  console.log("[AUTO-VIRUS] Iniciado.");
  topMessage8 = "Auto-bot activado";

  feedingInterval = setInterval(() => {
    try {
      const myCell = getMyMainCell();
      if (!myCell) {
        topMessage8 = "Auto-bot activado (fuera de juego)";
        sendUint8(OPCODE_C2S_EMITFOOD_STOP);
        simulateKeyRelease(" ");
        isLockMouse = 0;
        return;
      }

      // ✅ NUEVO: Verificar si tienes al menos UNA célula ≥500
      const todas = cellManager.getCellList();
      const misCeldas = todas.filter(
        (c) => c.cellType === CELLTYPE_PLAYER && c.pID === playerId,
      );

      const tengoCelulaSuficiente = misCeldas.some((c) => {
        const score = typeof c.getScore === "function" ? c.getScore() : c.size;
        return score >= 500;
      });

      if (!tengoCelulaSuficiente) {
        topMessage8 = "Auto-bot activado (esperando masa ≥500)";
        sendUint8(OPCODE_C2S_EMITFOOD_STOP);
        simulateKeyRelease(" ");
        isLockMouse = 0; // Devuelve control al jugador
        return; // Bot sigue activo, solo espera
      }

      // 1) Obtiene el grupo más relevante y seguro
      const grupo = obtenerGrupoVirusRelevante();

      // Verificación unificada del grupo - SI NO HAY GRUPO SEGURO, DETENER TODO
      if (!grupo || !Array.isArray(grupo) || grupo.length === 0) {
        topMessage8 = "Auto-bot activado (sin virus seguros)";
        sendUint8(OPCODE_C2S_EMITFOOD_STOP); // ⬅️ IMPORTANTE: Detener alimentación
        simulateKeyRelease(" "); // ⬅️ IMPORTANTE: Soltar space si está presionado
        isLockMouse = 0;
        return; // ⬅️ Salir sin hacer nada
      }

      // Si hay pocos virus, trabajar con ellos pero sin dividirse
      if (grupo.length < 5) {
        const objetivo = getSpiralTarget(grupo);
        if (
          !objetivo ||
          typeof objetivo.x_draw !== "number" ||
          typeof objetivo.y_draw !== "number" ||
          isNaN(objetivo.x_draw) ||
          isNaN(objetivo.y_draw)
        ) {
          console.warn("[AUTO-VIRUS] Objetivo inválido, continuando...");
          sendUint8(OPCODE_C2S_EMITFOOD_STOP); // ⬅️ Detener si hay error
          simulateKeyRelease(" ");
          return;
        }

        moveToX = objetivo.x_draw;
        moveToY = objetivo.y_draw;
        lockMouseX = moveToX;
        lockMouseY = moveToY;
        sendBotMouseMove(moveToX, moveToY);

        sendUint8(OPCODE_C2S_EMITFOOD_ONCE);
        sendUint8(OPCODE_C2S_EMITFOOD_START);

        simulateKeyRelease(" "); // no se divide aún
        isLockMouse = 1;

        topMessage8 = "Auto-bot activado (esperando más virus)";
        return;
      }

      // 2) Score bajo: no dividirse pero continuar
      if (userScoreCurrent <= 2200) {
        topMessage8 = "Auto-bot activado (poca masa - sin división)";
        // Solo alimentar sin dividirse
        const objetivo = getSpiralTarget(grupo);
        if (!objetivo || isNaN(objetivo.x_draw) || isNaN(objetivo.y_draw)) {
          sendUint8(OPCODE_C2S_EMITFOOD_STOP);
          simulateKeyRelease(" ");
          return;
        }
        moveToX = objetivo.x_draw;
        moveToY = objetivo.y_draw;
        lockMouseX = moveToX;
        lockMouseY = moveToY;
        sendBotMouseMove(moveToX, moveToY);

        sendUint8(OPCODE_C2S_EMITFOOD_ONCE);
        sendUint8(OPCODE_C2S_EMITFOOD_START);
        simulateKeyRelease(" "); // NO se divide
        isLockMouse = 1;
        return;
      }

      // 3) Objetivo tipo espiral
      const objetivo = getSpiralTarget(grupo);

      // Validar objetivo antes de usarlo
      if (
        !objetivo ||
        typeof objetivo.x_draw !== "number" ||
        typeof objetivo.y_draw !== "number" ||
        isNaN(objetivo.x_draw) ||
        isNaN(objetivo.y_draw)
      ) {
        console.warn(
          "[AUTO-VIRUS] Objetivo principal inválido, continuando...",
        );
        sendUint8(OPCODE_C2S_EMITFOOD_STOP); // ⬅️ Detener si hay error
        simulateKeyRelease(" ");
        return;
      }

      moveToX = objetivo.x_draw;
      moveToY = objetivo.y_draw;
      lockMouseX = moveToX;
      lockMouseY = moveToY;
      sendBotMouseMove(moveToX, moveToY);

      sendUint8(OPCODE_C2S_EMITFOOD_ONCE);
      sendUint8(OPCODE_C2S_EMITFOOD_START);
      simulateKeyPress(" ");
      isLockMouse = 1;
      topMessage8 = "Auto-bot activado";
    } catch (err) {
      console.error("[AUTO-VIRUS] Error en loop:", err);
      // No detener el bot, solo continuar con la siguiente iteración
      topMessage8 = "Auto-bot activado (error recuperado)";
    }
  }, getMoveInterval());
}
function toggleFeeding() {
  if (autoVirus) {
    stopFeeding();
  } else {
    startFeeding();
  }
}
