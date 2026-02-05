// ==UserScript==
// @name         ULTIMATE2025
// @namespace    http://tampermonkey.net/
// @version      2025-06-17
// @description  try to take over the world!
// @author       You
// @match        https://agarz.com/
// @match        https://agarz.com/es
// @icon         https://www.google.com/s2/favicons?sz=64&domain=agarz.com
// @grant        none
// ==/UserScript==
// === INICIALIZACIÓN DE DEPENDENCIAS ===

const sweetAlertScript = document.createElement("script");
sweetAlertScript.src = "https://cdn.jsdelivr.net/npm/sweetalert2@11";
document.head.appendChild(sweetAlertScript);

(function ($) {
  // =======================
  // 1. ELIMINAR ESTILOS EXISTENTES
  // =======================
  document.querySelectorAll('link[rel="stylesheet"]').forEach((link) => {
    const href = link.href;
    if (
      href.includes("css/index.css") ||
      href.includes("maxcdn.bootstrapcdn.com/bootstrap")
    ) {
      link.remove();
    }
  });

  document.querySelectorAll("style").forEach((style) => {
    const css = style.textContent;
    if (css.includes(".skin-popup") || css.includes(".isim-popup")) {
      style.remove();
    }
  });

  // =======================
  // 2. AGREGAR NUEVAS HOJAS DE ESTILO
  // =======================
  [
    // Fuentes esenciales
    "https://fonts.googleapis.com/css2?family=Rajdhani:wght@400;700&display=swap",
    "https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap",
    // Librerías necesarias
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css", // NECESARIO - Iconos extensivos
    "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css", // NECESARIO - Form switches
  ].forEach((href) => {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = href;
    link.loading = "async"; // Carga asíncrona para mejor rendimiento
    document.head.appendChild(link);
  });

  // =======================
  // 3. CREAR E INSERTAR EL MENÚ HTML
  // =======================
  var nuevoDiv = $("<div>", {
    id: "xts-container-menu",
    class: "menu-xts-container",
    html: `
        <div class="menu-xts-content">
            <!-- Botones arriba a la derecha -->
            <div class="menu-xts-buttons">
                <button id="btnModal1" class="menu-xts-btn menu-btn" data-tooltip="Menú">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <rect x="3" y="3" width="7" height="7" rx="1"></rect>
                    <rect x="14" y="3" width="7" height="7" rx="1"></rect>
                    <rect x="14" y="14" width="7" height="7" rx="1"></rect>
                    <rect x="3" y="14" width="7" height="7" rx="1"></rect>
                </svg
                </button>
                <button id="btnModal2" class="menu-xts-btn menu-btn" data-tooltip="Configuración">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <line x1="4" y1="21" x2="4" y2="14"></line>
                    <line x1="4" y1="10" x2="4" y2="3"></line>
                    <line x1="12" y1="21" x2="12" y2="12"></line>
                    <line x1="12" y1="8" x2="12" y2="3"></line>
                    <line x1="20" y1="21" x2="20" y2="16"></line>
                    <line x1="20" y1="12" x2="20" y2="3"></line>
                    <line x1="1" y1="14" x2="7" y2="14"></line>
                    <line x1="9" y1="8" x2="15" y2="8"></line>
                    <line x1="17" y1="16" x2="23" y2="16"></line>
                </svg>
                </button>
            </div>
            <!-- Modales -->
            <div id="modal1" class="menu-xts-modal">
                <div class="blur-layer"></div>
                <div class="content">
                <div class="menu-xts-modal-header">
                   <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <rect x="3" y="3" width="7" height="7" rx="1"></rect>
                    <rect x="14" y="3" width="7" height="7" rx="1"></rect>
                    <rect x="14" y="14" width="7" height="7" rx="1"></rect>
                    <rect x="3" y="14" width="7" height="7" rx="1"></rect>
                </svg>
                    <span>MENU</span>
                </div>
                <!-- Pestañas -->
                <div class="menu-xts-tabs">
                    <button class="menu-xts-tab active" data-target="#menuLogin">
                        Cuenta
                    </button>
                    <button class="menu-xts-tab" data-target="#menuExtras">
                        Más
                    </button>
                </div>
                <!-- Sección: Login -->
                <div id="menuLogin" class="menu-xts-tab-content active">
                    <!-- Contenido de login por defecto aquí -->
                </div>
                <!-- Sección: Más -->
                <div id="menuExtras" class="menu-xts-tab-content">
                    <!-- Enlaces extras aquí -->
                    <label class="dificil"><a href="/es/halloffame" class="prospanxts" target="_blank">Salón de la Fama</a></label>
                    <label class="dificil"><a href="/es/bestplayers" class="prospanxts" target="_blank">Mejores Jugadores</a></label>
                    <label class="dificil"><a href="/es/bestclans" class="prospanxts" target="_blank">Mejores Clanes</a></label>
                    <label class="dificil"><a href="/es/lastrecords" class="prospanxts" target="_blank">Últimos Archivos</a></label>
                    <label class="dificil"><a href="/es/howtoplay" class="prospanxts" target="_blank">How to play</a></label>
                    <label class="dificil"><a href="/es/lastupdates" class="prospanxts" target="_blank">Últimas actualizaciones</a></label>
                    <label class="dificil"><a href="/es/isimara/" class="prospanxts" target="_blank">Nombre de búsqueda</a></label>
                    <label class="dificil"><a href="/es/pin/" class="prospanxts" target="_blank">Premium de búsqueda</a></label>
                    <label class="dificil"><a href="/es/presat_psa" class="prospanxts" target="_blank">Compra-venta premium</a></label>
                    <label class="dificil"><a href="/es/buy_premium" class="prospanxts" target="_blank">Comprar Premium!</a></label>
                    <label class="dificil"><a href="/es/rekorsat" class="prospanxts" target="_blank">Récord de Comercio</a></label>
                    <label class="dificil"><a href="https://agarz.com/es/golddetail/EKP-1" class="prospanxts" target="_blank">Ekip Lista</a></label>
                </div>
                <!-- Botón Cerrar -->
                <button class="menu-xts-close" onclick="xts_closeModal('modal1')">
                    <i class="fas fa-times"></i> Cerrar
                </button>
                </div>
            </div>
            <div id="modal2" class="menu-xts-modal">
             <div class="blur-layer"></div>
                <div class="content">
                <div class="menu-xts-modal-header">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <line x1="4" y1="21" x2="4" y2="14"></line>
                    <line x1="4" y1="10" x2="4" y2="3"></line>
                    <line x1="12" y1="21" x2="12" y2="12"></line>
                    <line x1="12" y1="8" x2="12" y2="3"></line>
                    <line x1="20" y1="21" x2="20" y2="16"></line>
                    <line x1="20" y1="12" x2="20" y2="3"></line>
                    <line x1="1" y1="14" x2="7" y2="14"></line>
                    <line x1="9" y1="8" x2="15" y2="8"></line>
                    <line x1="17" y1="16" x2="23" y2="16"></line>
                </svg>
                    <span>AJUSTES</span>
                </div>
                <div class="menu-xts-tabs">
                    <button class="menu-xts-tab active" data-target="#settingsNormal">Normales</button>
                    <button class="menu-xts-tab" data-target="#settingsPlus">Plus</button>
                </div>
                <div id="settingsNormal" class="menu-xts-tab-content active">
                   <div id="yesno_settings" >

                   <label><input type="checkbox">Mostrar Top 1</label>
                   <label><input type="checkbox">Mostrar skor sala</label>
                   </div>
                </div>
              <div id="settingsPlus" class="menu-xts-tab-content">
                 <!-- TEMAS - Diseño Minimalista -->
                 <div class="settings-section">
                   <h5 class="section-title"><i class="fas fa-palette"></i> Temas</h5>
                   <div class="theme-grid-mini">
                     <button class="theme-btn-mini" data-theme="default" title="Default">
                       <div class="theme-dots">
                         <span style="background: #0ff"></span>
                         <span style="background: #ff00ff"></span>
                         <span style="background: #00ff88"></span>
                       </div>
                     </button>
                     <button class="theme-btn-mini" data-theme="purple" title="Purple">
                       <div class="theme-dots">
                         <span style="background: #9d4edd"></span>
                         <span style="background: #7209b7"></span>
                         <span style="background: #c77dff"></span>
                       </div>
                     </button>
                     <button class="theme-btn-mini" data-theme="green" title="Green">
                       <div class="theme-dots">
                         <span style="background: #00ff00"></span>
                         <span style="background: #00cc00"></span>
                         <span style="background: #39ff14"></span>
                       </div>
                     </button>
                     <button class="theme-btn-mini" data-theme="red" title="Red">
                       <div class="theme-dots">
                         <span style="background: #ff0055"></span>
                         <span style="background: #ff006e"></span>
                         <span style="background: #ff4d6d"></span>
                       </div>
                     </button>
                     <button class="theme-btn-mini" data-theme="gold" title="Gold">
                       <div class="theme-dots">
                         <span style="background: #ffd700"></span>
                         <span style="background: #ffb700"></span>
                         <span style="background: #ffe55c"></span>
                       </div>
                     </button>
                     <button class="theme-btn-mini" data-theme="blue" title="Blue">
                       <div class="theme-dots">
                         <span style="background: #00b4d8"></span>
                         <span style="background: #0077b6"></span>
                         <span style="background: #48cae4"></span>
                       </div>
                     </button>
                   </div>

                   <!-- Custom Colors Compacto -->
                   <div class="custom-section-mini">
                     <div class="color-row">
                       <input type="color" id="custom-main" value="#00ffff" title="Color Principal">
                       <input type="color" id="custom-secondary" value="#ff00ff" title="Color Secundario">
                       <input type="color" id="custom-accent" value="#00ff88" title="Color Acento">
                       <button class="btn-apply-mini" onclick="applyCustomTheme()" title="Aplicar Custom">
                         <i class="fas fa-check"></i>
                       </button>
                     </div>
                     <input type="text" id="custom-bg-image" class="input-mini" placeholder="URL imagen fondo (opcional)">
                   </div>
                 </div>

                 <!-- Aquí irán más secciones en el futuro -->

              </div>

                <button class="menu-xts-close" onclick="xts_closeModal('modal2')">
                    <i class="fas fa-times"></i> Cerrar
                </button>
            </div>
             </div>

        </div>
    `,
  });
  $("#overlays").prepend(nuevoDiv);

  // =======================
  // 4. EVENTOS DE INTERFAZ (MODALES Y TABS)
  // =======================
  // Abrir modales con animación (SIN BACKDROP)
  $(document).on("click", "#btnModal1", function () {
    xts_openModal("#modal1");
  });

  $(document).on("click", "#btnModal2", function () {
    xts_openModal("#modal2");
  });

  // Función para abrir modal con animación (SIN BACKDROP)
  window.xts_openModal = function (modalId) {
    const $modal = $(modalId);

    if (!$modal.length) return;

    // Cerrar otros modales primero
    $(".menu-xts-modal.active").each(function () {
      $(this).hide().removeClass("active closing");
    });

    // Mostrar modal
    $modal.show().removeClass("closing");

    // Forzar reflow
    $modal[0].offsetHeight;

    // Activar animación
    $modal.addClass("active");
  };

  // Función para cerrar modal con animación
  window.xts_closeModal = function (modalId) {
    const $modal = $(modalId);

    if (!$modal.length) return;

    // Iniciar animación de salida
    $modal.addClass("closing").removeClass("active");

    // Esperar a que termine la animación
    setTimeout(() => {
      $modal.hide().removeClass("closing");
    }, 300);
  };

  // Cerrar modal al hacer click en botón cerrar
  $(document).on("click", ".menu-xts-close, .xts-modal-close", function () {
    const modalId = $(this).closest(".menu-xts-modal").attr("id");
    xts_closeModal("#" + modalId);
  });

  // Tabs con animación mejorada
  $(document).on("click", ".menu-xts-tab", function () {
    const $btn = $(this);
    const $modal = $btn.closest(".menu-xts-modal");
    const target = $btn.data("target");

    // Si ya está activo, no hacer nada
    if ($btn.hasClass("active")) return;

    // Cambiar tab activo
    $modal.find(".menu-xts-tab").removeClass("active");
    $btn.addClass("active");

    // Animar cambio de contenido
    const $currentContent = $modal.find(".menu-xts-tab-content.active");
    const $newContent = $modal.find(target);

    // Fade out del contenido actual
    $currentContent.fadeOut(200, function () {
      $currentContent.removeClass("active");

      // Fade in del nuevo contenido
      $newContent.addClass("active").hide().fadeIn(300);
    });
  });

  // Opcional: Efecto shake para errores
  window.xts_shakeModal = function (modalId) {
    const $modal = $(modalId);
    if (!$modal.length) return;

    $modal.addClass("shake");
    setTimeout(() => {
      $modal.removeClass("shake");
    }, 500);
  };

  // =======================
  // FUNCIONES DE TEMAS
  // =======================

  // Aplicar tema personalizado
  window.applyCustomTheme = function () {
    const main = document.getElementById("custom-main").value;
    const secondary = document.getElementById("custom-secondary").value;
    const accent = document.getElementById("custom-accent").value;
    const bgImage = document.getElementById("custom-bg-image").value;

    // Efecto visual de confirmación
    const btn = document.querySelector(".apply-custom-btn");
    if (btn) {
      btn.style.animation = "themeColorPulse 0.5s ease-out";
      setTimeout(() => {
        btn.style.animation = "";
      }, 500);
    }

    window.ThemeManager.setCustomColors(main, secondary, accent, bgImage);
    updateThemeButtons("custom");

    xts_toast("success", "¡Tema personalizado aplicado!");
  };

  // Actualizar botones de tema
  function updateThemeButtons(activeTheme) {
    document.querySelectorAll(".theme-btn-mini").forEach((btn) => {
      if (btn.dataset.theme === activeTheme) {
        btn.classList.add("active");
        // Efecto visual al activar
        btn.style.animation = "none";
        setTimeout(() => {
          btn.style.animation = "themeColorPulse 0.6s ease-out";
        }, 10);
      } else {
        btn.classList.remove("active");
      }
    });
  }

  // Event listeners para los botones de tema (nueva clase)
  $(document).on("click", ".theme-btn-mini", function () {
    const theme = $(this).data("theme");

    window.ThemeManager.applyTheme(theme);
    updateThemeButtons(theme);
    xts_toast(
      "success",
      `Tema ${window.ThemeManager.themes[theme].name} aplicado`,
    );
  });

  // Actualizar inputs de color personalizado cuando se carga un tema custom
  $(document).on("click", '[data-target="#settingsPlus"]', function () {
    setTimeout(() => {
      const currentTheme = window.ThemeManager.currentTheme;
      updateThemeButtons(currentTheme);

      // Siempre cargar los valores guardados en los inputs, independientemente del tema activo
      const colors = window.ThemeManager.themes.custom.colors;
      const bgImage = window.ThemeManager.themes.custom.bgImage || "";

      document.getElementById("custom-main").value = colors.main;
      document.getElementById("custom-secondary").value = colors.secondary;
      document.getElementById("custom-accent").value = colors.accent;
      document.getElementById("custom-bg-image").value = bgImage;
    }, 100);
  });

  //agregardatos al opciones normales
  options.init();
  options.addYesNoSetting("Mostrar el nombre", "showName", true, null);
  options.addYesNoSetting("Mostrar la piel", "showSkin", true, null);
  options.addYesNoSetting("Transparente", "transparentRender", true, null);
  options.addYesNoSetting("Mostrar Puntuación", "showScore", true, null);
  options.addYesNoSetting("Makro", "showMakro", true, null);
  options.addYesNoSetting("Mostrar alrededor", "scopeAround", true, null);
  options.addYesNoSetting("Muestra información", "showInfo", true, null);
  options.addYesNoSetting("Ocultar los chats", "hideChat", false, function () {
    options.get("hideChat") ? $(DIV_CHAT).hide() : $(DIV_CHAT).show();
  });
  options.addYesNoSetting("Borde", "drawEdge", false, null);
  options.addYesNoSetting("Clan", "showClanName", true, null);
  options.addYesNoSetting("Rápida", "quickSplit", true, null);
  options.addYesNoSetting("Mostrar id en el chat", "accNoShow", true, null);

  //poner estilo de switch a los settins del juego
  var yesnoSettingsDiv = document.getElementById("yesno_settings");
  if (!yesnoSettingsDiv) return;

  var labels = yesnoSettingsDiv.getElementsByTagName("label");

  for (var i = 0; i < labels.length; i++) {
    var label = labels[i];
    if (label.dataset.modified === "true") continue;
    var input = label.querySelector("input");
    if (!input) continue;
    var originalText = label.textContent.trim();
    label.innerHTML = "";
    label.classList.add("form-check", "form-switch", "dark-mode-label");
    label.appendChild(input);
    var span = document.createElement("span");
    span.classList.add("prospanxts");
    span.textContent = originalText;
    label.appendChild(span);
    var slug = originalText.replace(/\s+/g, "-").toLowerCase();
    input.id = slug;
    input.classList.add("form-check-input", "dark-mode-switch");
    label.setAttribute("for", slug);
    label.dataset.modified = "true";
  }

  const style = document.createElement("style");
  style.textContent = `
  .form-check-input[type="checkbox"] {
    background-color: #222 !important;
  }

  .form-check-input:focus {
    border-color: var(--xts-main-color);
    outline: 0;
    box-shadow: 0 0 0 .15rem rgba(var(--xts-main-rgb), 0.52);
  }
  .form-switch .form-check-input{
     --bs-form-switch-bg: url("data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='-4 -4 8 8'><circle r='3' fill='rgba%28255%2C255%2C255%2C0.25%29'/></svg>");
  }
  .form-switch .form-check-input:focus {
    --bs-form-switch-bg: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='-4 -4 8 8'%3E%3Ccircle r='3' fill='rgba%280%2C255%2C255%2C0.25%29'/%3E%3C/svg%3E");
  }

  .form-check .form-check-input {
    border-color: #575757b5;
  }

  .form-check-input[type="checkbox"]::before {
    background-color: #0f0 !important;
    transition: background-color 0.3s ease, transform 0.3s ease;
  }

  .form-check-input[type="checkbox"]:checked {
    background-color: var(--xts-main-color) !important;
    --bs-form-switch-bg: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='-4 -4 8 8'%3E%3Ccircle r='3' fill='%2300000080'/%3E%3C/svg%3E");
    border-color: var(--xts-main-color);
  }

  .form-check-input[type="checkbox"]:checked::before {
    background-color: #111 !important;
  }
  .wip-xts {
    font-style: italic;
    color: #ccc;
    font-weight: 500;
  }

  .dots::after {
    content: '';
    display: inline-block;
    animation: dotsAnimation 1.2s steps(3, end) infinite;
  }

  @keyframes dotsAnimation {
    0%   { content: ''; }
    33%  { content: '.'; }
    66%  { content: '..'; }
    100% { content: '...'; }
  }
`;
  document.head.appendChild(style);

  // =======================
  // 5. LOGIN: HTML POR DEFECTO Y FUNCIONES RELACIONADAS
  // =======================

  // HTML del login por defecto
  var loginxdefecto = `
<div class="xts-login-container" id="xts-container-dinamico">
    <div class="xts-banner">
        <img src="https://agarz.com/banner.png" alt="Banner AgarZ" width="150" style="filter: invert(1);">
    </div>
    <form onsubmit="xts_user_login(); return false;" autocomplete="on" class="formlogin-xts">
        <div class="xts-input-group">
            <input type="text" id="xts_user" class="text-xts-plusxyz" placeholder="Usuario" autocomplete="username" required>
            <input type="password" id="xts_pass" class="text-xts-plusxyz" placeholder="Contraseña" autocomplete="current-password" required>
        </div>
        <button type="submit" class="menu-xts-login-btn">
           Entrar
        </button>
    </form>
    <div class="menu-xts-actions">
        <div class="button-proxts-infox" onclick="xts_mostrarCrearCuenta()">
            <i class="fas fa-user-plus"></i> Crear Cuenta
        </div>
        <div class="button-proxts-infox" onclick="xts_mostrarRecuperar()">
            <i class="fas fa-key"></i> Recuperar Contraseña
        </div>
    </div>
</div>
<div id="xts-login-msg" class="xts-login-msg"></div>
`;

  // Función para cargar reCAPTCHA
  window.xts_onRecaptchaLoaded = function () {
    const recaptchaEl = document.querySelector(".g-recaptcha");
    if (recaptchaEl && typeof grecaptcha !== "undefined") {
      grecaptcha.render(recaptchaEl, {
        sitekey: "6LdKWRITAAAAAIuQGFJUfCV7NvZY4bNo1tNJMvNv",
        theme: "dark",
      });
    }
  };

  // Mostrar formulario de registro
  window.xts_mostrarCrearCuenta = function () {
    document.getElementById("xts-container-dinamico").innerHTML = `
        <div class="xts-banner">
            <img src="https://agarz.com/banner.png" alt="Banner AgarZ" width="150" style="filter: invert(1);">
        </div>
        <form id="xts-register-form" class="formlogin-xts" autocomplete="on">
            <div class="xts-input-group">
                <input type="email" name="email" class="text-xts-plusxyz" placeholder="Correo electrónico" autocomplete="email" required>
                <input type="password" name="pass1" class="text-xts-plusxyz" placeholder="Clave" autocomplete="new-password" required>
                <input type="password" name="pass2" class="text-xts-plusxyz" placeholder="Repetir clave" autocomplete="new-password" required>
            </div>
            <div class="g-recaptcha" data-sitekey="6LdKWRITAAAAAIuQGFJUfCV7NvZY4bNo1tNJMvNv"></div>
             <button type="submit" class="menu-xts-login-btn">Registrar</button>
        </form>
           <div class="menu-xts-actions">
                <div class="button-proxts-infox" onclick="xts_volverLogin()">
                    <i class="fas fa-arrow-left"></i> Volver al Login
                </div>
            </div>
    `;

    if (typeof grecaptcha === "undefined") {
      const s = document.createElement("script");
      s.src =
        "https://www.google.com/recaptcha/api.js?onload=xts_onRecaptchaLoaded&render=explicit";
      document.body.appendChild(s);
    } else {
      xts_onRecaptchaLoaded();
    }
    setTimeout(() => {
      document.getElementById("xts-register-form").onsubmit = async function (
        e,
      ) {
        e.preventDefault();
        const email = this.email.value.trim();
        const pass1 = this.pass1.value.trim();
        const pass2 = this.pass2.value.trim();
        const token = grecaptcha.getResponse();
        const $btn = this.querySelector(".menu-xts-login-btn");
        $btn.classList.add("loading");
        $btn.disabled = true;
        if (pass1 !== pass2) {
          message_xts("error", "Las contraseñas no coinciden.");
          $btn.classList.remove("loading");
          $btn.disabled = false;
          return;
        }
        if (
          !/[a-z]/.test(pass1) ||
          !/[A-Z]/.test(pass1) ||
          !/[0-9]/.test(pass1)
        ) {
          message_xts(
            "warn",
            "La clave debe tener minúsculas, mayúsculas y números.",
          );
          $btn.classList.remove("loading");
          $btn.disabled = false;
          return;
        }
        if (!token) {
          message_xts("warn", "Completa el reCAPTCHA antes de continuar.");
          $btn.classList.remove("loading");
          $btn.disabled = false;
          return;
        }
        const data = new FormData();
        data.append("email", email);
        data.append("pass1", pass1);
        data.append("pass2", pass2);
        data.append("g-recaptcha-response", token);

        try {
          const res = await fetch("/es/register", {
            method: "POST",
            body: data,
          });
          const html = await res.text();
          const temp = document.createElement("div");
          temp.innerHTML = html;

          const h2 = temp.querySelectorAll("h2")[1] || temp.querySelector("h2");

          if (h2) {
            const mensaje = h2.innerHTML.trim();
            const texto = mensaje.toLowerCase();

            const esError = [
              "registrada",
              "existe",
              "error",
              "falló",
              "ya está",
              "fracasó",
            ].some((k) => texto.includes(k));

            if (esError) {
              message_xts("error", mensaje);
            } else {
              message_xts("success", mensaje);
              this.reset();
              grecaptcha.reset?.();
            }
          } else {
            message_xts("error", "Error desconocido. Intenta nuevamente.");
          }
        } catch {
          message_xts("error", "Error de red. Intenta más tarde.");
        } finally {
          $btn.classList.remove("loading");
          $btn.disabled = false;
        }
      };
    }, 100);
  };

  // Mostrar formulario de recuperación de contraseña
  window.xts_mostrarRecuperar = function () {
    document.getElementById("xts-container-dinamico").innerHTML = `
        <div class="xts-banner">
            <img src="https://agarz.com/banner.png" alt="Banner AgarZ" width="150" style="filter: invert(1);">
        </div>
        <form id="xts-recover-form" class="formlogin-xts">
            <div class="xts-input-group">
                <input type="email" name="email" class="text-xts-plusxyz" placeholder="Correo asociado a la cuenta" autocomplete="email" required>
            </div>
            <div class="g-recaptcha" data-sitekey="6LdKWRITAAAAAIuQGFJUfCV7NvZY4bNo1tNJMvNv"></div>
                <button type="submit" class="menu-xts-login-btn">
                    <i class="fas fa-paper-plane"></i> Enviar recuperación
                </button>
            <div id="xts-recover-msg" class="xts-login-msg"></div>
        </form>
         <div class="menu-xts-actions">
           <div class="button-proxts-infox" onclick="xts_volverLogin()">
                <i class="fas fa-arrow-left"></i> Volver al Login
            </div>
        </div>
    `;

    if (typeof grecaptcha === "undefined") {
      const s = document.createElement("script");
      s.src =
        "https://www.google.com/recaptcha/api.js?onload=xts_onRecaptchaLoaded&render=explicit";
      document.body.appendChild(s);
    } else {
      xts_onRecaptchaLoaded();
    }

    setTimeout(() => {
      document.getElementById("xts-recover-form").onsubmit = async function (
        e,
      ) {
        e.preventDefault();

        const email = this.email.value.trim();
        const token = grecaptcha.getResponse();

        const $btn = this.querySelector(".menu-xts-login-btn");
        $btn.classList.add("loading");
        $btn.disabled = true;

        if (!/^[^@]+@[^@]+\.[^@]+$/.test(email)) {
          message_xts("error", "Correo inválido.");
          $btn.classList.remove("loading");
          $btn.disabled = false;
          return;
        }

        if (!token) {
          message_xts("warn", "Completa el reCAPTCHA antes de continuar.");
          $btn.classList.remove("loading");
          $btn.disabled = false;
          return;
        }

        const data = new FormData();
        data.append("email", email);
        data.append("g-recaptcha-response", token);
        try {
          const res = await fetch("/es/resetpass", {
            method: "POST",
            body: data,
          });
          const html = await res.text();
          const temp = document.createElement("div");
          temp.innerHTML = html;

          let mensaje =
            temp.querySelectorAll("div")[2]?.innerHTML ||
            "Respuesta desconocida.";
          const mensajeTexto = mensaje.trim().toLowerCase();
          if (
            mensajeTexto.includes("falló") ||
            mensajeTexto.includes("Falló")
          ) {
            message_xts("error", mensaje);
          } else {
            message_xts("success", mensaje);
            this.reset();
            grecaptcha.reset?.();
          }
        } catch {
          message_xts("error", "Error de red. Intenta más tarde.");
        } finally {
          $btn.classList.remove("loading");
          $btn.disabled = false;
        }
      };
    }, 100);
  };

  // Volver al login por defecto
  window.xts_volverLogin = function () {
    document.getElementById("xts-container-dinamico").outerHTML = loginxdefecto;
  };

  // =======================
  // 6. FUNCIONES DE AUTENTICACIÓN
  // =======================
  function deleteText(elementId, speed, callback) {
    const element = document.getElementById(elementId);
    if (!element || !element.value) return;

    let text = element.value;
    let index = text.length;

    function erase() {
      if (index > 0) {
        element.value = text.slice(0, index - 1);
        index--;

        // Disparar evento input si lo necesitas
        const event = new Event("input", { bubbles: true });
        element.dispatchEvent(event);
      } else {
        clearInterval(intervalId);
        if (typeof callback === "function") callback(); // Llama a callback si existe
      }
    }

    const intervalId = setInterval(erase, speed);
  }

  function typeText(elementId, text, speed) {
    if (!text) return;
    const element = document.getElementById(elementId);
    if (!element) {
      return;
    }
    element.value = "";
    let index = 0;

    function type() {
      if (index < text.length) {
        element.value += text.charAt(index);
        index++;
        const event = new Event("input", { bubbles: true });
        element.dispatchEvent(event);
      } else {
        clearInterval(intervalId);
      }
    }
    const intervalId = setInterval(type, speed);
  }

  window.message_xts = function (tipo, mensaje) {
    const tipos = {
      info: { c: "#6cf", i: "fas fa-info-circle" },
      error: { c: "#f55", i: "fas fa-exclamation-circle" },
      warn: { c: "#fa3", i: "fas fa-triangle-exclamation" },
      success: { c: "#6f6", i: "fas fa-check-circle" },
    };

    const { c, i } = tipos[tipo] || tipos.info;
    let $box = $("#xts-login-msg");
    $box
      .css({
        color: c,
        display: "block",
        opacity: 0,
        transform: "translateY(-10px)",
      })
      .html(`<i class="${i}"></i> ${mensaje}`);
    void $box[0].offsetWidth;

    $box.css({ opacity: 1, transform: "translateY(0)" });
    setTimeout(() => {
      $box.css({ opacity: 0, transform: "translateY(-10px)" });
      setTimeout(() => $box.hide(), 400);
    }, 3000);
  };

  window.xts_user_login = async function () {
    const email = $("#xts_user").val();
    const pass = $("#xts_pass").val();
    const $btn = $(".menu-xts-login-btn");

    if (!email || !pass) {
      message_xts("warn", "Por favor, completa usuario y contraseña.");
      return;
    }

    $btn.addClass("loading").prop("disabled", true);

    try {
      const response = await fetch(ajax_url, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          me: "login",
          email: email,
          password: pass,
          isMobile: isMobile,
        }),
        cache: "no-cache",
      });

      const msg = await response.text();
      const temp = $("<div>").html(msg);
      const visibleText = temp.text().toLowerCase();

      // Detectores de error
      const isRateLimited = visibleText.includes("intentalo");
      const isBanned = visibleText.includes("ban");
      const ERR_KEYS = ["error", "intentarlo", "sonra", "giri"];
      const isError =
        ERR_KEYS.some((k) => visibleText.includes(k)) || isRateLimited;

      if (isError || isBanned) {
        let mensaje = "Credenciales incorrectas";
        let tipo = "error";

        if (isBanned) {
          mensaje = "Cuenta baneada. Contacta con soporte.";
          tipo = "error";
        } else if (isRateLimited) {
          mensaje = "Demasiados intentos. Espera unos minutos.";
          tipo = "warn";
        }

        message_xts(tipo, mensaje);
        return;
      }

      // Login correcto

      const username = temp.find("#idNameDefault").text().trim();
      const skin = temp.find("#idSkinDefault").text().trim();
      const userToken = temp.find("#userToken").text().trim();
      const pageUrl = temp.find('a[href*="home"]').attr("href") || "";
      const pageId = pageUrl.split("/").pop() || "";
      xts_toast("success", `👋 Bienvenido | ID: ${pageId}`);

      localStorage.setItem("userToken", userToken);
      xts_renderLoginContent(msg);
      setTimeout(() => {
        typeText("nick", username, 100);
        typeText("txtSkin", skin, 100);
        xts_skinFavori();
        xts_isimFavori();
      }, 0);
    } catch (error) {
      console.error("Error en login:", error);
      message_xts("error", "Error de conexión. Intenta nuevamente.");
    } finally {
      $btn.removeClass("loading").prop("disabled", false);
    }
  };

  // ------ 6.2 Token login ------
  window.user_token = async function () {
    const token = localStorage.getItem("userToken");
    if (!token) {
      $("#menuLogin").html(loginxdefecto);
      return;
    }
    try {
      const response = await fetch(ajax_url, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          me: "token",
          token: token,
          isMobile: isMobile,
        }),
        cache: "no-cache",
      });
      const msg = await response.text();
      xts_renderLoginContent(msg);
      setTimeout(() => {
        const nd = $("#namexts").html();
        const sd = $("#skinxts").html();
        typeText("nick", nd, 100);
        typeText("txtSkin", sd, 100);
        xts_skinFavori();
        xts_isimFavori();
      }, 0);
    } catch (error) {
      console.error("Error en user_token:", error);
      $("#menuLogin").html(loginxdefecto);
    }
  };
  user_token();

  function buscarSkinUrl(nombre) {
    nombre = nombre.trim().toLowerCase();

    const img = $(".img-div-pro img")
      .filter(function () {
        return $(this).attr("alt")?.trim().toLowerCase() === nombre;
      })
      .get(0);

    return img?.src || `https://cdn.agarz.com/${nombre}.png`;
  }

  // ------ 6.3 Renderizar contenido de login ------
  window.xts_renderLoginContent = async function (msg) {
    const temp = $("<div>").html(msg);
    const username = temp.find("#idNameDefault").text().trim();
    const skin = temp.find("#idSkinDefault").text().trim();
    const userToken = temp.find("#userToken").text().trim();
    const pageUrl = temp.find('a[href*="home"]').attr("href") || "";
    const pageId = pageUrl.split("/").pop();
    const logoutLink = temp.find('a[onclick*="user_logout"]').attr("onclick");

    const html = `
    <div class="xts-profile-modern">
        <!-- Header del perfil simplificado -->
        <div class="xts-profile-header">
            <div class="xts-user-info">
                <h3 class="xts-username">${username}</h3>
                <div class="xts-user-id">
                    <span class="xts-id-label">ID:</span>
                    <span class="xts-id-value">${pageId}</span>
                    <button class="xts-copy-btn" title="Copiar ID" onclick="xts_copyToClipboard('${pageId}', this)">
                        <i class="fas fa-copy"></i>
                    </button>
                </div>
            </div>
        </div>


        <!-- Acciones principales -->
        <div class="xts-actions-modern">
            <div class="xts-action-row">
                <a href="${pageUrl}" class="xts-action-btn xts-primary" target="_blank">
                    <div class="xts-btn-icon">
                        <i class="fas fa-home"></i>
                    </div>
                    <div class="xts-btn-content">
                        <span class="xts-btn-title">Mi Página</span>
                        <span class="xts-btn-subtitle">Perfil principal</span>
                    </div>
                </a>
                <a href="https://agarz.com/tr/home_ks/${pageId}" class="xts-action-btn xts-secondary" target="_blank">
                    <div class="xts-btn-icon">
                        <i class="fas fa-palette"></i>
                    </div>
                    <div class="xts-btn-content">
                        <span class="xts-btn-title">Skins</span>
                        <span class="xts-btn-subtitle">Colección</span>
                    </div>
                </a>
            </div>
            <div class="xts-action-row">
                <a href="https://agarz.com/tr/home_bt/${pageId}" class="xts-action-btn xts-accent" target="_blank">
                    <div class="xts-btn-icon">
                        <i class="fas fa-exchange-alt"></i>
                    </div>
                    <div class="xts-btn-content">
                        <span class="xts-btn-title">Transferencias</span>
                        <span class="xts-btn-subtitle">Historial</span>
                    </div>
                </a>
                <div class="xts-action-btn-group">
                  <button class="xts-action-btn xts-special" onclick="toggleBonusDropdown()">
                      <div class="xts-btn-icon">
                          <i class="fas fa-magic"></i>
                      </div>
                      <div class="xts-btn-content">
                          <span class="xts-btn-title">Convertir</span>
                          <span class="xts-btn-subtitle">Bonus → Gold</span>
                      </div>
                  </button>
                  <div class="xts-bonus-dropdown">
                      <div class="xts-bonus-dropdown-content">
                          <button id="btnAll" onclick="xts_convertBonusAmount('all')">Convertir Todo</button>
                          <button id="btnHalf" onclick="xts_convertBonusAmount('half')">Mitad</button>
                          <button id="btnQuarter" onclick="xts_convertBonusAmount('quarter')">1/4 Parte</button>
                          <button id="btnEighth" onclick="xts_convertBonusAmount('eighth')">1/8 Parte</button>
                      </div>
                  </div>
                </div>
            </div>
        </div>

        <!-- Botón de logout mejorado -->
        <div class="xts-logout-section">
            <button class="xts-logout-btn" onclick='${logoutLink}'>
                <i class="fas fa-sign-out-alt"></i>
                <span>Cerrar Sesión</span>
                <div class="xts-logout-ripple"></div>
            </button>
        </div>

        <!-- Datos ocultos -->
        <div style="display:none">
            <span id="tokenxts">${userToken}</span>
            <span id="skinxts">${skin}</span>
            <span id="namexts">${username}</span>
        </div>
    </div>
    `;
    $("#menuLogin").html(html);

    // Actualizar stats si están disponibles
    setTimeout(() => {
      if (window.goldxt) {
        $("#xts-gold-display").text(window.goldxt.toLocaleString());
      }
      if (window.bonusxt) {
        $("#xts-bonus-display").text(window.bonusxt.toLocaleString());
      }
    }, 100);

    await xts_skinFavori();
  };
  window.xts_copyToClipboard = function (text, btn) {
    const icon = btn.querySelector("i");
    if (!icon) return;
    icon.style.transition = "opacity 0.2s ease";
    icon.style.opacity = "0";

    setTimeout(() => {
      icon.className = "fas fa-check";
      icon.style.opacity = "1";
      btn.title = "Copiado";
      setTimeout(() => {
        icon.style.opacity = "0";
        setTimeout(() => {
          icon.className = "fas fa-copy";
          icon.style.opacity = "1";
          btn.title = "Copiar ID";
        }, 150);
      }, 1500);
    }, 200);

    navigator.clipboard.writeText(text).catch(() => {
      btn.title = "Error al copiar";
    });
  };

  const stylecopy = document.createElement("style");
  stylecopy.textContent = `
      .copy-id-btn {
        background: none;
        border: none;
        color: var(--xts-main-color);
        cursor: pointer;
        margin-left: 6px;
        font-size: 0.9em;
      }
      .copy-id-btn:hover {
        color: #fff;
      }
      .copy-id-btn i {
       transition: opacity 0.2s ease;
      }
    `;
  document.head.appendChild(stylecopy);

  window.xts_toast = function (type = "info", text = "") {
    Swal.fire({
      toast: true,
      position: "top",
      icon: type,
      title: text,
      showConfirmButton: false,
      timer: 3000,
      timerProgressBar: true,
      background: "#111",
      color: "#fff",
      padding: "0.75rem 1.5rem",
      customClass: {
        popup: "swal2-popup-xts",
      },
      didOpen: (toast) => {
        // Centrar el texto
        toast.querySelector(".swal2-title").style.textAlign = "center";

        // Personalizar progress bar
        toast.querySelector(".swal2-timer-progress-bar").style.background =
          "#636363";
        toast.querySelector(".swal2-timer-progress-bar").style.boxShadow =
          "0 0 6px var(--xts-main-color), 0 0 12px var(--xts-main-color)";

        // Detener / reanudar temporizador con hover
        toast.addEventListener("mouseenter", Swal.stopTimer);
        toast.addEventListener("mouseleave", Swal.resumeTimer);
      },
    });
  };
  window.toggleBonusDropdown = function () {
    try {
      const raw = String(window.bonusxt).replace(/[^\d]/g, "");
      const total = parseInt(raw);

      if (!total || isNaN(total) || total <= 0) {
        xts_toast("error", "No hay bonus suficiente");
        return;
      }

      // Función para formatear números con puntos
      function formatNumber(num) {
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
      }

      // Calcular cantidades
      const all = total;
      const half = Math.floor(total / 2);
      const quarter = Math.floor(total / 4);
      const eighth = Math.floor(total / 8);

      // Actualizar texto de botones con números formateados
      document.getElementById("btnAll").textContent = formatNumber(all);
      document.getElementById("btnHalf").textContent = formatNumber(half);
      document.getElementById("btnQuarter").textContent = formatNumber(quarter);
      document.getElementById("btnEighth").textContent = formatNumber(eighth);

      // Toggle dropdown con animación suave
      const dropdown = document.querySelector(".xts-bonus-dropdown");
      const isVisible = dropdown.classList.contains("xts-show");

      if (isVisible) {
        // Ocultar
        dropdown.classList.remove("xts-show");
        setTimeout(() => {
          dropdown.style.display = "none";
        }, 300); // Tiempo igual a la transición CSS
      } else {
        // Mostrar
        dropdown.style.display = "block";
        // Forzar reflow para que la transición funcione
        dropdown.offsetHeight;
        dropdown.classList.add("xts-show");
      }
    } catch (error) {
      console.error("Error al mostrar opciones de conversión:", error);
      xts_toast("error", "Ocurrió un error al mostrar opciones");
    }
  };

  window.xts_convertBonusAmount = function (option) {
    try {
      const raw = String(window.bonusxt).replace(/[^\d]/g, "");
      const total = parseInt(raw);

      if (!total || isNaN(total) || total <= 0) {
        xts_toast("error", "No hay bonus suficiente");
        return;
      }

      let cantidad;
      switch (option) {
        case "all":
          cantidad = total;
          break;
        case "half":
          cantidad = Math.floor(total / 2);
          break;
        case "quarter":
          cantidad = Math.floor(total / 4);
          break;
        case "eighth":
          cantidad = Math.floor(total / 8);
          break;
        default:
          xts_toast("error", "Opción inválida");
          return;
      }

      // Validaciones de seguridad
      if (!Number.isInteger(cantidad) || cantidad <= 0 || cantidad > total) {
        xts_toast("error", "Cantidad inválida para conversión");
        return;
      }

      sendChat2(`-bt ${cantidad}`);
      xts_toast(
        "success",
        `Se convirtió ${cantidad
          .toString()
          .replace(/\B(?=(\d{3})+(?!\d))/g, ".")} bonus a gold`,
      );
      document.querySelector(".xts-bonus-dropdown").style.display = "none";
    } catch (error) {
      console.error("Error al convertir bonus:", error);
      xts_toast("error", "Ocurrió un error al convertir Bonus");
    }
  };

  // ------ 6.4 Mostrar login por defecto ------
  window.user_show = function () {
    $.ajax({
      url: ajax_url,
      method: "POST",
      data: { me: "show", isMobile: isMobile },
      cache: false,
    }).done(function (msg) {
      $("#menuLogin").html(loginxdefecto);
      $("loginButton").click(function () {
        alert("j");
      });
    });
  };

  // ------ 6.5 Resetear usuario ------
  var user_reset = function () {
    localStorage.userToken = null;
    deleteText("nick", 100);
    deleteText("txtSkin", 100);
    $(".skin-popup").html("");
    $(".skin-popup").removeClass("active");
    $(".isim-popup").html("");
    $(".isim-popup").removeClass("active");
    user_show();
  };

  // ------ 6.6 Logout ------
  window.user_logout = function (token) {
    user_reset();
    $.ajax({
      url: ajax_url,
      method: "POST",
      data: { me: "logout", token: token, isMobile: isMobile },
      cache: false,
    }).done(function (msg) {
      xts_skinFavori();
      xts_isimFavori();
    });
  };

  function xts_skinFavori() {
    return new Promise((resolve) => {
      $.ajax({
        url: "/ajax_skinFavori",
        method: "POST",
        data: { token: localStorage.userToken },
        cache: false,
      })
        .done(function (msg) {
          const skinList = JSON.parse(msg);
          const container = $("#xts-car-pro");
          const counter = document.getElementById("skin-count-indicator");

          if (container.length === 0) {
            if (counter) counter.textContent = "0";
            return resolve();
          }

          container.empty();

          let validCount = 0;

          skinList.forEach((skin) => {
            const primarySrc = `//cdn.agarz.com/${skin.skin}`;
            const fallbackSrc = `//agarz.com/skins_uploaded/${skin.skin}`;
            const defaultSrc =
              "https://i.ibb.co/Mr6Dr4B/imagen-2025-04-09-192504990.png";

            const img = $("<img>", {
              src: primarySrc,
              class: "skin-img",
              alt: skin.isim,
              title: skin.isim,
              css: {
                width: "70px",
                height: "70px",
                opacity: 0,
              },
            });

            img.one("error", function () {
              $(this)
                .off("error")
                .attr("src", fallbackSrc)
                .one("error", function () {
                  $(this).attr("src", defaultSrc);
                });

              $(this)
                .parent()
                .addClass("skin-inactive")
                .find("img")
                .removeAttr("title");
            });

            const div = $("<div>", {
              class: "img-div-pro",
            }).append(img);

            div.on("click", () => {
              $("#xts-car-wrapper").removeClass("visible");
            });

            container.append(div);
            img.animate({ opacity: 1 }, 1650);

            validCount++;
          });

          if (counter) {
            counter.textContent = validCount;

            counter.classList.remove("pop");
            void counter.offsetWidth;
            counter.classList.add("pop");

            counter.addEventListener("animationend", function handler(e) {
              if (e.animationName === "popUp") {
                counter.classList.remove("pop");
                counter.removeEventListener("animationend", handler);
              }
            });
          }

          resolve();
        })
        .fail(function () {
          console.error("Error al obtener las skins favoritas.");

          // En caso de fallo, forzar contador a 0
          const counter = document.getElementById("skin-count-indicator");
          if (counter) {
            counter.textContent = "0";
            counter.classList.add("visible");
          }

          resolve();
        });
    });
  }

  function xts_isimFavori() {
    return new Promise((resolve, reject) => {
      const listContainer = $("#xts-nick-list");
      const toggleBtn = $("#xts-nick-toggle");

      $.ajax({
        url: "/ajax_isimFavori",
        method: "POST",
        data: { token: localStorage.userToken },
        cache: false,
      })
        .done((msg) => {
          listContainer.html("");

          if (!msg?.trim()) {
            listContainer.html(
              "<div class='no-results'>No se encontraron nombres</div>",
            );
            return resolve();
          }

          let isimList;
          try {
            isimList = JSON.parse(msg);
          } catch (e) {
            console.error("Error al parsear nombres:", e);
            listContainer.html(
              "<div class='no-results'>Error al cargar nombres</div>",
            );
            return resolve();
          }

          if (!Array.isArray(isimList) || isimList.length === 0) {
            listContainer.html(
              "<div class='no-results'>No se encontraron nombres</div>",
            );
            return resolve();
          }

          isimList.forEach((isim) => {
            listContainer.append(
              $("<div>", {
                class: "isim-item",
                text: isim,
              }),
            );
          });

          resolve();
        })
        .fail((xhr, status, error) => {
          console.error("Error al obtener nombres favoritos:", error);
          listContainer.html("<div class='no-results'>Error de conexión</div>");
          reject(error);
        });
    });
  }

  $("body").on("click", "#xts-nick-list .isim-item", function () {
    const isim = $(this).text();
    $("#nick").val(isim);
    $("#xts-nick-list").slideUp(200);
    $("#xts-nick-toggle").removeClass("rotated");
  });

  // =======================
  // 7. HELLO DIALOG (SKIN Y BOTONES PRINCIPALES)
  // =======================
  $("#helloDialog").html(`
<div class="xts-container-plus">
    <div id="xts-car-wrapper">
        <div class="xts-car-pro" id="xts-car-pro"></div>
    </div>
    <div class="skin-preview-circle" multibox="off" id="open-profiles-catalogue">
        <div id="skin-count-indicator">0</div>
        <div id="skinPreviPro">
            <div class="preview" id="skin-preview-1"></div>
        </div>
    </div>
    <div class="xts-btn-div-plus">
        <button class="xts-btn gamer-btn" type="submit" id="playBtn" onclick="onClickPlay(); return false;">
            <i class="fa-solid fa-circle-play iconxc"></i>
        </button>
        <button class="xts-btn gamer-btn" id="spectateBtn" onclick="spectate(); return false;">
            <i class="fa-solid fa-circle-notch iconxc"></i>
        </button>
        <button class="xts-btn gamer-btn" id="replayBtn">
            <i class="fa-solid fa-rotate-right iconxc"></i>
        </button>
    </div>
    <div class="xts-comand-input">
        <div class="blur-layer"></div>
        <div class="content">
        <div class="div-list-item xts-nick-wrapper">
  <div class="xts-nick-input-group">
    <input id="nick" class="text-xts-plusxyz" placeholder="İsim" maxlength="15">
    <button id="xts-nick-toggle" type="button" class="nick-dropdown-btn">
  <i class="fa-solid fa-chevron-down"></i>
</button>

  </div>
  <div id="xts-nick-list" class="list-item"><div class='no-results'>No se encontraron nombres</div></div>
</div>

        <div class="sre-xts-e">
            <input id="txtSkin" class="text-xts-plusxyz" placeholder="Skin" autocomplete="off" maxlength="45">
            <input id="myTeam" class="text-xts-plusxyz" placeholder="Takım" autocomplete="off" maxlength="6">
        </div>
        <select id="gamemode" class="text-xts-plusxyz" onchange="setserver4($(this).val());" required="">
            <option id="ffa1" value="wss://ws.agarz.com:1042">FFA-1</option>
            <option id="ffa2" value="wss://ws.agarz.com:1002">FFA-2</option>
            <option id="ffa3" value="wss://ws.agarz.com:1003">FFA-3</option>
            <option id="ffa4" value="wss://ws.agarz.com:1004">FFA-4</option>
            <option id="ffa5" value="wss://ws.agarz.com:1005">FFA-5</option>
            <option id="ffa6" value="wss://ws.agarz.com:1006">FFA-6</option>
            <option id="ffa7" value="wss://ws.agarz.com:1007">FFA-7</option>
            <option id="ffa8" value="wss://ws.agarz.com:1248">FFA-8</option>
            <option id="ffa9" value="wss://ws.agarz.com:1249">FFA-9</option>
            <option id="ffa10" value="wss://ws.agarz.com:1250">FFA-10</option>
            <option id="ffa11" value="wss://ws.agarz.com:1251">FFA-11</option>
            <option id="ffa12" value="wss://ws.agarz.com:1243">FFA-12</option>
            <option id="ffa13" value="wss://ws.agarz.com:1244">FFA-13</option>
            <option id="ffa14" value="wss://ws.agarz.com:1245">FFA-14</option>
            <option id="ffa15" value="wss://ws.agarz.com:1230">FFA-15</option>
            <option id="ffa16" value="wss://ws.agarz.com:1009">FFA-16</option>
            <option id="ffa17" value="wss://ws.agarz.com:1246">FFA-17</option>
            <option id="ffa18" value="wss://ws.agarz.com:1257">FFA-18</option>
            <option id="ffa19" value="wss://ws.agarz.com:1208">FFA-19</option>
            <option id="ffa20" value="wss://ws.agarz.com:1231">FFA-20</option>
            <option id="ffa21" value="wss://ws.agarz.com:1232">FFA-21</option>
            <option id="ffa22" value="wss://ws.agarz.com:1253">FFA-22</option>
            <option id="ffa23" value="wss://ws.agarz.com:1254">FFA-23</option>
            <option id="ffa24" value="wss://ws.agarz.com:1255">FFA-24</option>
            <option id="ffa25" value="wss://ws.agarz.com:1256">FFA-25</option>
            <option id="ffa26" value="wss://ws.agarz.com:1258">FFA-26</option>
            <option id="ffa27" value="wss://ws.agarz.com:1259">FFA-27</option>
            <option id="ffa28" value="wss://ws.agarz.com:1029">FFA-28</option>
            <option id="ffa29" value="wss://ws.agarz.com:1260">FFA-29</option>
            <option id="ffa30" value="wss://ws.agarz.com:1247">FFA-30</option>
            <option id="ffa31" value="wss://ws.agarz.com:1233">FFA-31</option>
            <option id="ffa32" value="wss://ws.agarz.com:1234">FFA-32</option>
            <option id="ffa33" value="wss://ws.agarz.com:1235">FFA-33</option>
            <option id="ffa34" value="wss://ws.agarz.com:1236">FFA-34</option>
            <option id="ffa35" value="wss://ws.agarz.com:1043">FFA-35</option>
            <option id="ffa36" value="wss://ws.agarz.com:1237">FFA-36</option>
            <option id="ffa37" value="wss://ws.agarz.com:1238">FFA-37</option>
            <option id="ffa38" value="wss://ws.agarz.com:1210">FFA-38</option>
            <option id="ffa39" value="wss://ws.agarz.com:1221">FFA-39</option>
            <option id="ffa40" value="wss://ws.agarz.com:1219">FFA-40</option>
            <option id="ffa41" value="wss://ws.agarz.com:1207">FFA-41</option>
            <option id="ffa42" value="wss://ws.agarz.com:1206">FFA-42</option>
            <option id="ffa43" value="wss://ws.agarz.com:1205">FFA-43</option>
            <option id="ffa44" value="wss://ws.agarz.com:1202">FFA-44</option>
            <option id="ffa45" value="wss://ws.agarz.com:1201">FFA-45</option>
            <option id="ffa46" value="wss://ws.agarz.com:1200">FFA-46</option>
            <option id="ffa47" value="wss://ws.agarz.com:1001">FFA-47</option>
            <option id="ffa48" value="wss://ws.agarz.com:1252">FFA-48</option>
            <option id="ffa49" value="wss://ws.agarz.com:1220">FFA-49</option>
            <option id="ffa50" value="wss://ws.agarz.com:1239">FFA-50</option>
            <option id="ffa51" value="wss://ws.agarz.com:1240">FFA-51</option>
            <option id="ffa52" value="wss://ws.agarz.com:1241">FFA-52</option>
            <option id="ffa53" value="wss://ws.agarz.com:1261">FFA-53</option>
            <option id="ffa54" value="wss://ws.agarz.com:1242">FFA-54</option>
            <option id="ffa55" value="wss://ws.agarz.com:1222">FFA-55</option>
            <option id="ffa56" value="wss://ws.agarz.com:1223">FFA-56</option>
            <option id="ffa57" value="wss://ws.agarz.com:1224">FFA-57</option>
            <option id="ffa58" value="wss://ws.agarz.com:1225">FFA-58</option>
            <option id="ffa59" value="wss://ws.agarz.com:1226">FFA-59</option>
            <option id="ffa60" value="wss://ws.agarz.com:1227">FFA-60</option>
            <option id="ffa61" value="wss://ws.agarz.com:1228">FFA-61</option>
            <option id="ffa62" value="wss://ws.agarz.com:1211">FFA-62</option>
            <option id="ffa63" value="wss://ws.agarz.com:1218">FFA-63</option>
            <option id="ffa64" value="wss://ws.agarz.com:1213">FFA-64</option>
            <option id="ffa65" value="wss://ws.agarz.com:1214">FFA-65</option>
            <option id="ffa66" value="wss://ws.agarz.com:1215">FFA-66</option>
            <option id="ffa67" value="wss://ws.agarz.com:1216">FFA-67</option>
            <option id="ffa68" value="wss://ws.agarz.com:1217">FFA-68</option>
            <option id="ffa69" value="wss://ws.agarz.com:1209">FFA-69</option>
            <option id="ffa70" value="wss://ws.agarz.com:1041">FFA-70</option>
            <option id="ffa71" value="wss://ws.agarz.com:1204">FFA-71</option>
            <option id="ffa72" value="wss://ws.agarz.com:1203">FFA-72</option>
            <option id="ffa73" value="wss://ws.agarz.com:1044">FFA-73</option>
            <option id="ffa74" value="wss://ws.agarz.com:1045">FFA-74</option>
            <option id="ffa75" value="wss://ws.agarz.com:1046">FFA-75</option>
            <option id="ffa76" value="wss://ws.agarz.com:1047">FFA-76</option>
            <option id="ffa77" value="wss://ws.agarz.com:1229">FFA-77</option>
            <option id="tatil" value="wss://ws.agarz.com:1013">Etkinlik-1</option>
            <option id="alan1" value="wss://ws.agarz.com:1273">Alan-1</option>
            <option id="cffa1" value="wss://ws.agarz.com:1011">CFFA-1</option>
            <option id="cffa2" value="wss://ws.agarz.com:1012">CFFA-2</option>
            <option id="tffa1" value="wss://ws.agarz.com:1008">VS-CFFA</option>
            <option id="vsffa" value="wss://ws.agarz.com:1023">VS-FFA</option>
            <option id="gsz1" value="wss://ws.agarz.com:1021">VS-GSZ</option>
            <option id="ks_ffa1" value="wss://ws.agarz.com:1031">EKP-1</option>
            <option id="gsz1" value="wss://ws.agarz.com:1271">GSZ-1</option>
        </select>
        </div>
    </div>
</div>
`);

  $("#replayBtn").click(function () {
    cellManager["recordN"] = 0;
    cellManager["drawMode"] = DRAWMODE_REPLAY_PLAY;
    $(DIV_MAIN_MENU).hide();
  });

  const listContainer = $("#xts-nick-list");
  const toggleBtn = $("#xts-nick-toggle");

  toggleBtn.on("click", () => {
    if (!listContainer.is(":visible") && listContainer.children().length === 0)
      xts_isimFavori();
    listContainer.slideToggle(200);
    toggleBtn.toggleClass("rotated");
  });

  $(document).on("click", (e) => {
    if (
      !$(e.target).closest(".xts-nick-wrapper").length &&
      listContainer.is(":visible")
    ) {
      listContainer.slideUp(200);
      toggleBtn.removeClass("rotated");
    }
  });

  // Cargar CSS
  const css = document.createElement("link");
  css.rel = "stylesheet";
  css.href =
    "https://cdn.jsdelivr.net/npm/choices.js/public/assets/styles/choices.min.css";
  document.head.appendChild(css);
  const script = document.createElement("script");
  script.src =
    "https://cdn.jsdelivr.net/npm/choices.js/public/assets/scripts/choices.min.js";
  script.onload = () => {
    const select = document.getElementById("gamemode");
    if (!select) return;
    const choices = new Choices(select, {
      searchEnabled: true,
      itemSelectText: "",
      placeholderValue: "FFA",
      searchPlaceholderValue: "Buscar sala...",
      shouldSort: false,
    });
    select.choicesInstance = choices;
  };
  document.body.appendChild(script);

  const customStyle = document.createElement("style");
  customStyle.textContent = `

    /* 🔽 Reemplazo del ícono nativo por FontAwesome */
    .choices[data-type*='select-one']::after {
      display: none !important;
    }
    .choices[data-type*='select-one'] .choices__inner {
      position: relative;
    }
    .choices[data-type*='select-one'] .choices__inner::after {
      content: "\\f078"; /* Unicode fa-chevron-down */
      font-family: "Font Awesome 6 Free";
      font-weight: 900;
      position: absolute;
      right: 12px;
      top: 50%;
      transform: translateY(-50%);
      transition: transform 0.3s ease;
      pointer-events: none;
      color: #6d6d6d;
      font-size: 12px;
    }
    .choices[data-type*='select-one'].is-open .choices__inner::after {
      transform: translateY(-50%) rotate(180deg);
    }
    .choices__list--dropdown .choices__list, .choices__list[aria-expanded] .choices__list {
        position: relative;
        max-height: 180px!important;
        overflow: auto;
        -webkit-overflow-scrolling: touch;
        will-change: scroll-position;
    }
    /* 📦 Estilo del dropdown */
    .choices__list--dropdown,
    .choices__list[aria-expanded] {
      position: absolute;
      top: 100%;
      background: #141414;
      border-radius: 10px;
      margin-top: 6px;
      border: 1px solid #313131 !important;
      width: 100%;
      z-index: 23;
      overflow: hidden;
      word-break: break-word;
    }

    /* 🎯 Estilo de cada item */
    .choices__list--dropdown .choices__item,
    .choices__list[aria-expanded] .choices__item {
      padding: 4px;
      color: white;
      text-align: center;
      cursor: pointer;
      border-bottom: 1px solid #2d2d2d;
      font-family: 'Poppins', sans-serif;
      font-size: 13px;
      transition: background 0.3s ease;
    }

    /* ✨ Hover o seleccionado */
    .choices__list--dropdown .choices__item--selectable.is-highlighted,
    .choices__list[aria-expanded] .choices__item--selectable.is-highlighted {
      background: rgba(var(--xts-main-rgb), 0.2);
      color: var(--xts-main-color);
    }

    /* ⌨️ Input de búsqueda */
    .choices[data-type*=select-one] .choices__input {
      display: block;
      width: 100%;
      margin: 0;
      padding: 5px 12px;
      appearance: none;
      background: #141414;
      color: #ffffff;
      font-family: 'Poppins', sans-serif;
      font-size: 14px;
      border: 1px solid #292929;
      box-shadow: 0 0 0px 1000px #141414 inset;
      transition: all 0.2s ease-in-out;
    }

    /* 🧱 Contenedor principal */
    .choices__inner {
      appearance: none;
      background: #141414 !important;
      color: #ffffff;
      font-family: 'Poppins', sans-serif;
      font-size: 14px;
      padding: 0 8px !important;
      border-radius: 8px !important;
      border: 1px solid #292929 !important;
      box-shadow: 0 0 0px 1000px #141414 inset;
      min-height: auto;
      outline: none;
      transition: all 0.2s ease-in-out;
    }

    /* 🔵 Enfocado o abierto */
    .is-focused .choices__inner,
    .is-open .choices__inner {
      border-color: var(--xts-main-color) !important;
      box-shadow: 0 0 0px 1000px rgba(0, 0, 0, 0.36) inset, 0 0 10px var(--xts-main-color) inset;
      outline: none;
    }
    `;
  document.head.appendChild(customStyle);

  // =======================
  // 8. SKIN PREVIEW Y SELECCIÓN
  // =======================
  function buscarSkin(nombre) {
    return new Promise((resolve) => {
      const urlPorDefecto =
        "https://i.pinimg.com/originals/f4/42/45/f4424545bb27a296c426e93916abf99a.gif";
      const urlNoDeseado = "https://cdn.agarz.com/.png";
      if (!nombre || nombre === urlNoDeseado) {
        resolve(urlPorDefecto);
        return;
      }
      nombre = nombre.trim().toLowerCase();
      let encontrado = null;
      $(".img-div-pro img").each(function () {
        const alt = $(this).attr("alt")?.trim().toLowerCase() || "";
        if (alt === nombre) {
          encontrado = $(this).prop("src");
          return false;
        }
      });
      if (encontrado) {
        resolve(encontrado);
      } else {
        const urlImagen = "https://cdn.agarz.com/" + nombre + ".png";
        const img = new Image();
        img.onload = () => resolve(urlImagen);
        img.onerror = () => resolve(urlPorDefecto);
        img.src = urlImagen;
      }
    });
  }

  $(document).ready(() => {
    var txtSkin = $("#txtSkin");
    var currentImage = null;
    var debounceTimer = null;

    function cargarImagen(url, callback) {
      if (currentImage) {
        currentImage.onload = currentImage.onerror = null;
      }
      var img = new Image();
      currentImage = img;
      img.onload = function () {
        callback(true);
      };
      img.onerror = function () {
        callback(false);
      };
      img.src = url;
    }

    async function actualizarBackground(nombre) {
      const url = await buscarSkin(nombre);
      $("#skin-preview-1").css("background-image", "url(" + url + ")");
    }

    txtSkin.on("input", function () {
      var nombre = txtSkin.val().trim();
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(function () {
        actualizarBackground(nombre);
      }, 500);
    });

    $(document)
      .off("click", ".skin-img")
      .on("click", ".skin-img", function (e) {
        var urlImagen = $(this).prop("src").replace(/ /g, "%20");
        $("#skin-preview-1").css("background-image", `url(${urlImagen})`);
        $("#txtSkin").val($(this).attr("alt"));
      });

    var nombreInicial = txtSkin.val().trim();
    txtSkin.data("valorAnterior", nombreInicial);
  });

  // =======================
  // 9. SCROLLBAR PRO XTSMASTER
  // =======================
  const previewBtn = document.getElementById("skin-preview-1");
  const skinCarousel = document.getElementById("xts-car-wrapper");

  if (previewBtn && skinCarousel) {
    previewBtn.addEventListener("click", () => {
      const isVisible = skinCarousel.classList.contains("visible");

      if (isVisible) {
        skinCarousel.classList.remove("visible");
      } else {
        skinCarousel.classList.add("visible");
      }
    });
  }

  const el = document.getElementById("xts-car-pro");
  let lastBounce = 0;
  let isBouncing = false;
  // Solo añade el listener si aún no está añadido
  if (el && !el.dataset.listenerAttached) {
    el.addEventListener(
      "wheel",
      (e) => {
        const atTop = el.scrollTop <= 0;
        const atBottom = el.scrollTop + el.clientHeight >= el.scrollHeight - 1;

        if (getComputedStyle(el).display === "none") return;

        if (e.deltaY < 0 && atTop) {
          triggerBounce("top");
        }
        if (e.deltaY > 0 && atBottom) {
          triggerBounce("bottom");
        }
      },
      { passive: true },
    );

    // Limpieza de animación cuando termina
    el.addEventListener("animationend", () => {
      el.classList.remove("bounce", "top", "bottom");
      isBouncing = false;
    });

    el.dataset.listenerAttached = "true";
  }

  function triggerBounce(direction) {
    const now = Date.now();

    if (now - lastBounce < 400 || isBouncing) return;
    if (getComputedStyle(el).display === "none") return;

    isBouncing = true;
    el.classList.remove("bounce", "top", "bottom");
    void el.offsetWidth; // Forzar reflow
    el.classList.add("bounce", direction);
    lastBounce = now;
  }

  // =======================
  // 10. CHAT INPUT Y MENÚ
  // =======================
  // CARGAR HTML DEL CHAT
  $("#bottomContainer_desktop").html(`
<div id="chat-helpx" class="chat-commands">
    <p><strong>Comandos del chat</strong></p>
    <ul>
        <li><kbd onclick="setChatText('-b')">-b</kbd> → Muestra tu oro/bonus solo a ti</li>
        <li><kbd onclick="setChatText('-bg')">-bg</kbd> → Muestra tu oro/bonus a todos</li>
        <li><kbd onclick="setChatText('-bt ')">-bt 25000</kbd> → Convierte 25000 de bonus a oro</li>
        <li><kbd onclick="setChatText('-odulekle100k')">-odulekle100k</kbd> → Añade 100k al premio FFA</li>
        <li><kbd onclick="setChatText('-g ffa-1')">-g ffa-1</kbd> → Va a sala</li>
        <li><kbd onclick="setChatText('-go ffa-2')">-go ffa-2</kbd> → Va a FFA-2 y entra</li>
        <li><kbd onclick="setChatText('-gi ffa-5')">-gi ffa-5</kbd> → Va a FFA-5 como espectador</li>
    </ul>
</div>

<div id="chatInputContainer" class="chat-container">
    <button class="icon-button trash" onclick="chatManager.clear()">
        <i class="fas fa-trash-alt"></i>
    </button>
    <div class="chat-input-wrapper">
        <input type="text" id="chat_textbox" maxlength="100" placeholder="¡Presione Enter para escribir!" autocomplete="off">
        <button class="icon-button help" id="chat-icon-button">
            <i class="fas fa-question-circle"></i>
        </button>
    </div>
    <button class="icon-button emoji" id="emoji-button">
        <i class="fas fa-smile"></i>
    </button>
    <button class="icon-button settings" onclick="chatmenu_onclick()">
        <i class="fas fa-sliders-h"></i>
    </button>
    <div id="chatMenu" class="chat-menu">
        <button id="chatToAll" class="chat-mode-button" data-mode="0" onclick="toggleChatButton(this, CHATMODE_ALL)" title="Todos">
            <i class="fas fa-globe"></i>
        </button>
        <button id="chatToTeam" class="chat-mode-button" data-mode="1" onclick="toggleChatButton(this, CHATMODE_TEAM)" title="Team">
            <i class="fas fa-users"></i>
        </button>
        <button id="chatToClan" class="chat-mode-button" data-mode="2" onclick="toggleChatButton(this, CHATMODE_CLAN)" title="Klan">
            <i class="fas fa-shield-alt"></i>
        </button>
        <button id="chatToAgarZ" class="chat-mode-button" data-mode="3" onclick="toggleChatButton(this, CHATMODE_AGARZ)" title="Gritar! (50.000 Gold)">
            <i class="fas fa-bullhorn"></i>
        </button>
        <button id="chatFilter" class="chat-mode-button" onclick="toggleCheckboxButton(this)" title="Filtro">
            <i class="fas fa-filter"></i>
        </button>
    </div>
    <button class="icon-button danger" style="display:none" title="Report">
        <i class="fas fa-flag"></i>
    </button>
</div>
`);

  // Mostrar/ocultar ayuda
  window.setChatText = function (text) {
    const input = document.getElementById("chat_textbox");
    input.value = text;
    input.focus();
  };

  // Variables globales para controlar el picker
  let emojiPicker = null;
  let emojiPickerVisible = false;

  document.querySelector("#chat-icon-button").addEventListener("click", () => {
    document.querySelector("#chat-helpx").classList.toggle("show");
    if (emojiPickerVisible && emojiPicker) {
      emojiPicker.remove();
      emojiPickerVisible = false;
    }
  });

  // Función para insertar comando
  window.setChatText = function (text) {
    const input = document.getElementById("chat_textbox");
    input.value = text;
    input.focus();
  };
  const loadEmojiMart = () => {
    // Cargar CSS
    $("<link>", {
      rel: "stylesheet",
      href: "https://cdn.jsdelivr.net/npm/emoji-mart@latest/css/emoji-mart.css",
    }).appendTo("head");

    // Cargar script
    $.getScript(
      "https://cdn.jsdelivr.net/npm/emoji-mart@latest/dist/browser.js",
    )
      .done(() => {
        const input = document.querySelector("#chat_textbox");
        const emojiBtn = document.querySelector("#emoji-button");
        if (!input || !emojiBtn || typeof EmojiMart === "undefined") return;

        // Evento de click en el botón de emoji
        emojiBtn.addEventListener("click", () => {
          document.querySelector("#chat-helpx")?.classList.remove("show");

          if (emojiPickerVisible && emojiPicker) {
            emojiPicker.remove();
            emojiPickerVisible = false;
            return;
          }

          if (emojiPicker) emojiPicker.remove();

          emojiPicker = new EmojiMart.Picker({
            theme: "dark",
            set: "apple",
            onEmojiSelect: (emoji) => {
              input.value += emoji.native;
              input.focus();
            },
          });

          document.body.appendChild(emojiPicker);

          // Ubicar dinámicamente
          const rect = emojiBtn.getBoundingClientRect();
          Object.assign(emojiPicker.style, {
            position: "absolute",
            bottom: "40px",
            left: "350px",
            zIndex: 1,
          });

          // 🔒 Prevenir scroll global desde cualquier contenedor con scroll dentro del picker
          setTimeout(() => {
            const shadowRoot = emojiPicker.shadowRoot;
            if (!shadowRoot) return;
            const scroll = shadowRoot.querySelector(".scroll");
            if (!scroll) return;
            scroll.addEventListener(
              "wheel",
              function (e) {
                const delta = e.deltaY;
                const up = delta < 0;
                const scrollTop = this.scrollTop;
                const scrollHeight = this.scrollHeight;
                const offsetHeight = this.offsetHeight;
                const atTop = scrollTop === 0;
                const atBottom = scrollTop + offsetHeight >= scrollHeight - 1;
                if ((up && atTop) || (!up && atBottom)) {
                  e.preventDefault();
                  e.stopPropagation();
                } else {
                  e.stopPropagation();
                }
              },
              { passive: false },
            );
          }, 150);

          emojiPickerVisible = true;
        });

        // Cierre al hacer clic fuera
        document.addEventListener("click", (e) => {
          if (
            emojiPickerVisible &&
            emojiPicker &&
            !emojiPicker.contains(e.target) &&
            !emojiBtn.contains(e.target)
          ) {
            emojiPicker.remove();
            emojiPickerVisible = false;
          }
        });
      })
      .fail(() => console.error("[Emoji] Falló al cargar"));
  };

  loadEmojiMart();

  // =======================
  // 11. CHAT MENÚ: ESTADO Y FUNCIONES
  // =======================
  window.chatmenu_onclick = function () {
    const div = document.querySelector("#chatMenu");
    div.classList.toggle("open");
    localStorage.chatMenu_onOff = div.classList.contains("open") ? "on" : "off";
  };

  window.toggleChatButton = function (btn, mode) {
    const buttons = document.querySelectorAll(".chat-mode-button");
    buttons.forEach((b) => {
      if (b !== btn && b.id !== "chatFilter") {
        b.classList.remove("active");
      }
    });
    btn.classList.add("active");
    localStorage.chatMode_selected = mode;
    setChatMode(mode, SETMODE_CONTROLS | SETMODE_STORAGE);
  };

  window.toggleCheckboxButton = function (btn) {
    btn.classList.toggle("active");
    const isChecked = btn.classList.contains("active");
    document.getElementById("chatFilter").checked = isChecked;
    localStorage.chatFilter_checked = isChecked ? "true" : "false";
  };

  // Restaurar estados al cargar la página
  const div = document.querySelector("#chatMenu");
  if (div) {
    if (localStorage.chatMenu_onOff === "on") {
      div.classList.add("open");
    } else {
      div.classList.remove("open");
    }
  }
  const mode = localStorage.chatMode_selected;
  if (mode) {
    const btn = document.querySelector(
      `.chat-mode-button[data-mode="${mode}"]`,
    );
    if (btn) {
      const buttons = document.querySelectorAll(".chat-mode-button");
      buttons.forEach((b) => {
        if (b !== btn && b.id !== "chatFilter") {
          b.classList.remove("active");
        }
      });
      btn.classList.add("active");
      setChatMode(mode, SETMODE_CONTROLS);
    }
  }
  const chatFilter = document.getElementById("chatFilter");
  const btnFilter = document.querySelector(".chat-mode-button#chatFilter");
  const checked = localStorage.chatFilter_checked === "true";
  if (chatFilter && btnFilter) {
    chatFilter.checked = checked;
    if (checked) btnFilter.classList.add("active");
    else btnFilter.classList.remove("active");
  }
  window.chatFilter = document.querySelector("#chatFilter");

  (() => {
    const scrollTargets = [
      "#xts-car-pro",
      ".menu-xts-tab-content",
      ".list-item",
    ];

    scrollTargets.forEach((sel) => {
      document.querySelectorAll(sel).forEach((el) => {
        el.addEventListener(
          "wheel",
          (e) => {
            if (el.scrollHeight > el.clientHeight) e.stopPropagation();
          },
          { passive: true },
        );
      });
    });

    const obs = new MutationObserver(() => {
      document.querySelectorAll(".choices__list").forEach((el) => {
        if (!el.dataset.scrollLock) {
          el.addEventListener(
            "wheel",
            (e) => {
              if (el.scrollHeight > el.clientHeight) e.stopPropagation();
            },
            { passive: true },
          );
          el.dataset.scrollLock = "true";
        }
      });
    });

    obs.observe(document.body, { childList: true, subtree: true });
  })();

  // =======================
  // SISTEMA DE TEMAS Y PERSONALIZACIÓN
  // =======================
  window.ThemeManager = {
    currentTheme: null,

    themes: {
      default: {
        name: "Cyan Default",
        colors: {
          main: "#0ff",
          secondary: "#ff00ff",
          accent: "#00ff88",
        },
      },
      purple: {
        name: "Purple Dream",
        colors: {
          main: "#9d4edd",
          secondary: "#7209b7",
          accent: "#c77dff",
        },
      },
      green: {
        name: "Matrix Green",
        colors: {
          main: "#00ff00",
          secondary: "#00cc00",
          accent: "#39ff14",
        },
      },
      red: {
        name: "Red Fire",
        colors: {
          main: "#ff0055",
          secondary: "#ff006e",
          accent: "#ff4d6d",
        },
      },
      gold: {
        name: "Golden Luxury",
        colors: {
          main: "#ffd700",
          secondary: "#ffb700",
          accent: "#ffe55c",
        },
      },
      blue: {
        name: "Ocean Blue",
        colors: {
          main: "#00b4d8",
          secondary: "#0077b6",
          accent: "#48cae4",
        },
      },
      custom: {
        name: "Custom",
        colors: {
          main: "#0ff",
          secondary: "#ff00ff",
          accent: "#00ff88",
        },
        bgImage: "", // Añadir propiedad para guardar la URL de la imagen
      },
    },

    init() {
      // Cargar tema guardado SIN animaciones para evitar el flash inicial
      const saved = localStorage.getItem("xts-theme");
      if (saved) {
        try {
          const data = JSON.parse(saved);

          if (data.custom) {
            this.themes.custom.colors = data.custom;
          }
          if (data.bgImage) {
            this.themes.custom.bgImage = data.bgImage; // Guardar en el objeto custom

            this.applyBackgroundImage(data.bgImage);
          }
          // Aplicar tema sin animación en la carga inicial
          this.applyTheme(data.current || "default", true); // true = skipAnimation
        } catch (e) {
          this.applyTheme("default", true); // true = skipAnimation
        }
      } else {
        this.applyTheme("default", true); // true = skipAnimation
      }
    },

    applyTheme(themeName, skipAnimation = false) {
      const theme = this.themes[themeName];
      if (!theme) return;

      this.currentTheme = themeName;
      const colors = theme.colors;

      // Función para convertir hex a RGB
      const hexToRgb = (hex) => {
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result
          ? `${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(
              result[3],
              16,
            )}`
          : "0, 255, 255";
      };

      // Aplicar al CSS con animación suave
      const root = document.documentElement;

      // Solo agregar clase de transición si NO es la carga inicial
      if (!skipAnimation) {
        if (!root.classList.contains("theme-transitioning")) {
          root.classList.add("theme-transitioning");
        }
      }

      // Aplicar colores con animación CSS
      root.style.setProperty("--xts-main-color", colors.main);
      root.style.setProperty("--xts-secondary-color", colors.secondary);
      root.style.setProperty("--xts-accent-color", colors.accent);

      // RGB para sombras con opacidad
      root.style.setProperty("--xts-main-rgb", hexToRgb(colors.main));
      root.style.setProperty("--xts-secondary-rgb", hexToRgb(colors.secondary));
      root.style.setProperty("--xts-accent-rgb", hexToRgb(colors.accent));

      // Efecto de pulso en elementos principales (solo si NO es carga inicial)
      if (!skipAnimation) {
        this.animateThemeChange();
      }

      // Si es el tema custom, aplicar la imagen de fondo guardada
      if (themeName === "custom" && this.themes.custom.bgImage) {
        this.applyBackgroundImage(this.themes.custom.bgImage);
      }

      // Guardar
      this.saveTheme();
    },

    animateThemeChange() {
      // Crear efecto de onda de color
      const elements = document.querySelectorAll(
        ".menu-xts-btn, .theme-btn, .gamer-btn, .menu-xts-modal-header",
      );

      elements.forEach((el, index) => {
        // Animación escalonada
        setTimeout(() => {
          el.style.animation = "none";
          setTimeout(() => {
            el.style.animation = "themeColorPulse 0.3s ease-out";
          }, 10);
        }, index * 15); // Más rápido
      });

      // Limpiar animaciones después
      setTimeout(() => {
        elements.forEach((el) => {
          el.style.animation = "";
        });
      }, 500); // Limpiar más rápido
    },

    applyBackgroundImage(imageUrl) {
      const element = document.querySelector(".xts-btn-div-plus");
      if (element) {
        if (imageUrl && imageUrl.trim() !== "") {
          element.style.backgroundImage = `url(${imageUrl})`;
        } else {
          // Restaurar al fondo por defecto si no hay URL
          element.style.backgroundImage = "";
        }
      }
    },

    setCustomColors(main, secondary, accent, bgImage) {
      this.themes.custom.colors = { main, secondary, accent };
      // Guardar la imagen en el objeto custom (incluso si está vacía)
      this.themes.custom.bgImage = bgImage || "";

      this.applyTheme("custom");

      // Aplicar la imagen solo si existe
      this.applyBackgroundImage(bgImage);
    },

    saveTheme() {
      const data = {
        current: this.currentTheme,
        custom: this.themes.custom.colors,
        bgImage: this.themes.custom.bgImage || "", // Obtener desde el objeto custom
      };
      localStorage.setItem("xts-theme", JSON.stringify(data));
    },

    getCurrentColors() {
      if (!this.currentTheme) return this.themes.default.colors;
      return this.themes[this.currentTheme].colors;
    },
  };

  // ===================== PRE-CARGAR TEMA GUARDADO =====================
  // Este código se ejecuta ANTES de que se renderice el HTML para evitar flash
  (function preloadTheme() {
    try {
      const saved = localStorage.getItem("xts-theme");
      if (saved) {
        const data = JSON.parse(saved);
        const colors = data.custom || {
          main: "#0ff",
          secondary: "#ff00ff",
          accent: "#00ff88",
        };

        // Si hay un tema guardado diferente a custom, usar sus colores
        if (data.current && data.current !== "custom") {
          const themeColors = {
            default: {
              main: "#0ff",
              secondary: "#ff00ff",
              accent: "#00ff88",
            },
            purple: {
              main: "#9d4edd",
              secondary: "#7209b7",
              accent: "#c77dff",
            },
            blue: {
              main: "#0096ff",
              secondary: "#00d4ff",
              accent: "#72deff",
            },
            green: {
              main: "#39ff14",
              secondary: "#00ff41",
              accent: "#7fff00",
            },
            red: {
              main: "#ff0844",
              secondary: "#ff6b9d",
              accent: "#ff1744",
            },
            gold: {
              main: "#ffd700",
              secondary: "#ffed4e",
              accent: "#ffc107",
            },
            ocean: {
              main: "#006994",
              secondary: "#0099cc",
              accent: "#00bcd4",
            },
          };

          if (themeColors[data.current]) {
            Object.assign(colors, themeColors[data.current]);
          }
        }

        // Aplicar colores inmediatamente al root
        const root = document.documentElement;
        root.style.setProperty("--xts-main-color", colors.main);
        root.style.setProperty("--xts-secondary-color", colors.secondary);
        root.style.setProperty("--xts-accent-color", colors.accent);

        // Función para convertir hex a RGB
        const hexToRgb = (hex) => {
          const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
          return result
            ? `${parseInt(result[1], 16)}, ${parseInt(
                result[2],
                16,
              )}, ${parseInt(result[3], 16)}`
            : "0, 255, 255";
        };

        root.style.setProperty("--xts-main-rgb", hexToRgb(colors.main));
        root.style.setProperty(
          "--xts-secondary-rgb",
          hexToRgb(colors.secondary),
        );
        root.style.setProperty("--xts-accent-rgb", hexToRgb(colors.accent));
      }
    } catch (e) {
      console.error("Error pre-cargando tema:", e);
    }
  })();

  // Inicializar el sistema de temas
  ThemeManager.init();

  $("<style>")
    .prop("type", "text/css")
    .html(
      `
@import url("https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600&display=swap");

/* ===================== VARIABLES ===================== */

:root {
  --bg-color: #0a0a0a;
  --text-color: #ffffff;
  --primary-color: #00f0ff;
  --secondary-color: #ff00f0;
  --accent-color: #00ff88;
  --button-bg: linear-gradient(
    45deg,
    var(--primary-color),
    var(--secondary-color)
  );
  --button-shadow: 0 0 15px var(--primary-color),
    0 0 30px var(--secondary-color);

  --xts-main-color: #0ff;
  --xts-secondary-color: #ff00ff;
  --xts-accent-color: #00ff88;
  --xts-bg-dark: #111;
  --xts-bg-modal: #1a1a1a;
  --xts-text-light: #eee;
  --xts-error: #ff4444;
  --xts-error-hover: #cc0000;
  --xts-border-color: #181818;
  --xts-border: 1px solid var(--xts-border-color);
}

/* ===================== TRANSICIONES GLOBALES DE TEMA ===================== */
:root.theme-transitioning * {
  transition: color 0.4s cubic-bezier(0.4, 0, 0.2, 1),
              background-color 0.4s cubic-bezier(0.4, 0, 0.2, 1),
              border-color 0.4s cubic-bezier(0.4, 0, 0.2, 1),
              box-shadow 0.4s cubic-bezier(0.4, 0, 0.2, 1),
              text-shadow 0.4s cubic-bezier(0.4, 0, 0.2, 1),
              filter 0.4s cubic-bezier(0.4, 0, 0.2, 1),
              opacity 0.3s ease !important;
}

/* ===================== ANIMACIONES DE TEMA ===================== */
@keyframes themeColorPulse {
  0% {
    filter: brightness(1) saturate(1);
    opacity: 1;
  }
  50% {
    filter: brightness(1.3) saturate(1.5);
    opacity: 0.9;
  }
  100% {
    filter: brightness(1) saturate(1);
    opacity: 1;
  }
}

@keyframes gradientShift {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

@keyframes themeGlow {
  0%, 100% {
    box-shadow: 0 0 10px rgba(var(--xts-main-rgb), 0.3),
                0 0 20px rgba(var(--xts-main-rgb), 0.2);
  }
  50% {
    box-shadow: 0 0 20px rgba(var(--xts-main-rgb), 0.5),
                0 0 40px rgba(var(--xts-main-rgb), 0.3);
  }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes shimmer {
  0% {
    background-position: -200% center;
  }
  100% {
    background-position: 200% center;
  }
}


/* ===================== RESET & BASE ===================== */
body {
  padding: 0;
  margin: 0;
  overflow: hidden;
}

hr {
  margin: 2px;
}

iframe {
  border: 0px;
  overflow: hidden;
}

/* ===================== CANVAS ===================== */
#canvas {
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  width: 100%;
  height: 100%;
}

/* ===================== CHECKBOX ===================== */
.checkbox label {
  margin-right: 10px;
}

/* ===================== BUTTONS ===================== */
[type="button"]:not(:disabled),
[type="reset"]:not(:disabled),
[type="submit"]:not(:disabled),
button:not(:disabled) {
  cursor: pointer;
  outline: none;
}

/* ===================== PRINCIPAL CARA XTS ===================== */
#helloDialog {
  width: 100%;
  border-radius: 15px;
  padding: 5px 15px 5px 15px;
  top: 50%;
  left: 50%;
  margin-right: -50%;
  position: absolute;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 60px;
}

/* ===================== COMANDO PRINCIPAL-XTS-PRO ===================== */
.xts-container-plus {
  align-items: center;
  width: 625px;
  background: rgb(0 0 0 / 0%);
  height: 100%;
  display: flex;
  flex-direction: row;
  position:relative;
}
.xts-btn-div-plus {
    display: flex;
    background: url(https://i.ibb.co/fd6N7qjy/sssss1gn.png);
    background-size: cover;
    height: 80px;
    transform: skewX(-15deg);
    border: 2.4px solid #4d4d4d;
    backdrop-filter: blur(4px);
    width: 500px;
    border-radius: 0px 12px 12px 0px;
    overflow: hidden;
    background-color: #0000004f;
}
/* ===================== GAMER BUTTON ===================== */
.gamer-btn {
    position: relative;
    color: #e4e4e4;
    font-size: 1.1rem;
    font-weight: 600;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    cursor: pointer;
    width: 100%;
    padding: 0.9rem 1.2rem;
    border: none;
    background: linear-gradient(to bottom, #00000000 0%, #00000000 20%, #000000f0 50%, #4b4b4b 51%, #000000f0 51.2%, #00000000 80%, #00000000 100%);
    box-shadow: inset 0 1px 1px rgba(255, 255, 255, 0.05), 0 0 12px rgb(0 0 0 / 0%);
    transition: all 0.25s ease;
    z-index: 0;
    overflow: hidden;
}

/* ::before para la capa oscura con blur */
.gamer-btn::before {
    content: "";
    position: absolute;
    top: 0; left: 0;
    width: 100%;
    height: 100%;
    background: #000000cc;
    opacity: 0;
    transition: opacity 0.3s ease-in-out;
    z-index: -1;
}

/* Hover activa el fondo desenfocado */
.gamer-btn:hover::before {
    opacity: 1;
}


.gamer-btn i {
  pointer-events: none;
  transform: skewX(15deg);
  transition: color 0.5s ease-in-out;
  z-index: 1;
  position: relative;
  animation: pulseIcon 5s infinite ease-in-out;
}
@keyframes rotateRGB {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
@keyframes pulseIcon {
  0% {
    color: var(--xts-main-color);
    text-shadow: 0 0 5px var(--xts-main-color);
  }
  33% {
    color: var(--xts-secondary-color);
    text-shadow: 0 0 5px var(--xts-secondary-color);
  }
  66% {
    color: var(--xts-accent-color);
    text-shadow: 0 0 5px var(--xts-accent-color);
  }
  100% {
    color: var(--xts-main-color);
    text-shadow: 0 0 5px var(--xts-main-color);
  }
}

/* ===================== SKIN PREVIEW XTS NEW ===================== */
.skin-preview-circle {
  position: relative;
  z-index: 25;
  width: 120px;
  height: 120px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #3b3b3b;
  border-radius: 50%;
  left: 26.5px;
  border: 2px solid #4b4b4b;
}
#skinPreviPro {
  width: 110px;
  height: 110px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  background: #000000b3;
}
#skinPreviPro::before {
  content: "";
  position: absolute;
  width: 200%;
  height: 200%;
  background:conic-gradient(from 0deg, var(--xts-main-color), var(--xts-secondary-color), var(--xts-main-color));
  animation: rotateAura 10s linear infinite;
  z-index: 0;
  border-radius: 50%;
}
#skinPreviPro > * {
  z-index: 1;
  position: relative;
}
@keyframes rotateAura {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}



#skin-count-indicator {
    position: absolute;
    top: -16px;
    right: -10px;
    color: #000000;
    font-family: 'Rajdhani', sans-serif;
    font-size: 14px;
    padding: 3px 6px;
    min-width: 24px;
    height: 24px;
    line-height: 1;
    border-radius: 999px;
    pointer-events: none;
    transition: transform 0.3s ease;
    transform: scale(1);
    display: flex;
    align-items: center;
    justify-content: center;
    border: 2px solid #4b4b4b;
    background:var(--xts-main-color);
    overflow: hidden;
    z-index: 1;
    box-sizing: border-box;
    font-weight: bold;
}
@keyframes popUp {
    0% {
        transform: translateY(6px) scale(0.8);
        opacity: 0.5;
    }
    60% {
        transform: translateY(-4px) scale(1.1);
        opacity: 1;
    }
    100% {
        transform: translateY(0) scale(1);
    }
}

#skin-count-indicator.pop {
    animation: popUp 0.35s ease;
}


@keyframes rotateAura {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}


#skin-preview-1 {
  width: 100px;
  height: 100px;
  background-color: #0000;
  border-radius: 50%;
  background-image: url(https://i.pinimg.com/originals/f4/42/45/f4424545bb27a296c426e93916abf99a.gif);
  animation: rainbow_background 20s infinite;
  background-position-x: left;
  cursor: pointer;
  background-size: cover;
  backface-visibility: hidden;
  transition: background-image 0.4s ease-in-out, opacity 0.3s ease-in-out;
}
@keyframes gradientMove {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

/* ===================== COMANDOS ENTRADA XTS ===================== */
.xts-comand-input {
    position: absolute;
    top: 160px;
    left: 50%;
    transform: translateX(-50%);
    width: 320px;
    max-width: 400px;
    padding: 10px;
    border-radius: 10px;
    border: var(--xts-border);
}

.blur-layer {
    position: absolute;
    inset: 0;
    background: rgba(0, 0, 0, 0.6);
    backdrop-filter: blur(4px);
    z-index: 0;
    border-radius:12px;
}

.content {
    position: relative;
    z-index: 1;
    display: flex;
    flex-direction: column;
    gap: 6px;
}

/*LISTADO DE NICK FAVORITOS*/
.div-list-item{
position: relative;
}
.xts-nick-wrapper {
  position: relative;
  width: 100%;
  margin: auto;
}

.xts-nick-input-group {
  display: flex;
  align-items: center;
  background: #000000ad;
  border-radius: 10px;
  overflow: hidden;
  border: var(--xts-border);
}

.text-xts-plusxyz {
  flex: 1;
  border: none;
  padding: 10px;
  background: transparent;
  color: #fff;
  outline: none;
}

.nick-dropdown-btn {
    background: transparent;
    border: none;
    color: #6d6d6d;
    padding: 0 10px;
    backdrop-filter: none;
    position: absolute;
    right: 0;
    font-size: 12px;
}
.nick-dropdown-btn i {
  transition: transform 0.3s ease;
}

.nick-dropdown-btn.rotated i {
  transform: rotate(180deg);
}

#xts-nick-list {
    display: none;
    background: #141414;
    border-radius: 10px;
    margin-top: 6px;
    max-height: 200px;
    overflow-y: auto;
    border: 1px solid #313131;
    position: absolute;
    width: 100%;
    z-index:23;
}
.no-results {
    text-align: center;
    padding: 4px;
    color: #575757;
    font-size: 13px;
    font-family: 'Poppins';
}
.isim-item {
    padding: 4px;
    color: white;
    font-size: 16px;
    cursor: pointer;
    text-align: center;
    transition: background 0.3s ease;
    border-bottom: 1px solid #2d2d2d;
    font-family: 'Poppins', sans-serif;
    font-size: 13px;
}
.isim-item:hover {
    background: rgba(var(--xts-main-rgb), 0.2);
    color: var(--xts-main-color);
}
.sre-xts-e {
  display: flex;
  gap: 5px;
}

#myTeam {
  width: 25%;
  text-align: center;
}
.text-xts-plusxyz {
  appearance: none;
  background: rgb(20 20 20);
  color: #ffffff;
  font-family: 'Poppins', sans-serif;
  font-size: 14px;
  padding: 4px 12px;
  border-radius: 8px;
  transition: all 0.2s ease-in-out;
  border: 1px solid #292929;
  box-shadow: 0 0 0px 1000px rgb(20 20 20) inset;
}

.text-xts-plusxyz:focus {
  outline: none;
  box-shadow: 0 0 0px 1000px rgba(0, 0, 0, 0.36) inset, 0 0 10px var(--xts-main-color) inset;
  border-color: var(--xts-main-color);
}

/* Autofill Normalizado */
input.text-xts-plusxyz:-webkit-autofill,
input.text-xts-plusxyz:-webkit-autofill:hover,
input.text-xts-plusxyz:-webkit-autofill:focus,
input.text-xts-plusxyz:-webkit-autofill:active {
  -webkit-text-fill-color: #ffffff !important;
  box-shadow: 0 0 0px 1000px rgb(20, 20, 20) inset !important;
  background-color: transparent !important;
  border: 1px solid #292929 !important;
  font-family: 'Poppins', sans-serif !important;
  transition: background-color 0s ease-in-out 0s;
  caret-color: white;
}

input.text-xts-plusxyz:-webkit-autofill:focus {
  -webkit-text-fill-color: #ffffff !important;
  box-shadow: 0 0 0px 1000px rgba(0, 0, 0, 0.36) inset, 0 0 10px var(--xts-main-color) inset !important;
  border: 1px solid var(--xts-main-color) !important;
  caret-color: white;
}

/* Select Options */
.text-xts-plusxyz option {
  background: #111;
  color: var(--xts-main-color);
}

/* Flecha personalizada usando fondo inline SVG */
select.text-xts-plusxyz {
  background-image: url("data:image/svg+xml;charset=UTF-8,<svg fill='%230069ff' viewBox='0 0 24 24' xmlns='http://www.w3.org/2000/svg'><path d='M7 10l5 5 5-5H7z'/></svg>");
  background-repeat: no-repeat;
  background-position: right 10px center;
  background-size: 16px;
  padding-right: 30px;
}

/* ===================== MENU (LOGIN) AJUSTES ===================== */
.menu-xts-container {
  position: relative;
  padding: 10px;
  overflow: visible !important;
}

/* Botonera superior */
.menu-xts-buttons {
    position: absolute;
    top: 0px;
    right: 180px;
    display: flex;
    gap: 12px;
    z-index: 1002;
    overflow: visible !important;
}

/* Estilo de los botones mejorado */
.menu-xts-btn {
    position: relative;
    width: 44px;
    height: 44px;
    background: linear-gradient(145deg, #1a1a1a, #0a0a0a);
    color: var(--xts-main-color);
    border: 1.5px solid rgba(var(--xts-main-rgb), 0.3);
    border-radius: 12px;
    cursor: pointer;
    font-size: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5),
                0 0 20px rgba(var(--xts-main-rgb), 0.1),
                inset 0 1px 0 rgba(255, 255, 255, 0.05);
    overflow: visible;
    background: rgba(20, 20, 20, 0.9);
}

/* Efecto de brillo animado en el fondo */
.menu-xts-btn::before {
    content: '';
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle,
                rgba(var(--xts-main-rgb), 0.15) 0%,
                transparent 60%);
    opacity: 0;
    transition: opacity 0.3s ease, transform 0.3s ease;
    transform: scale(0.5);
    pointer-events: none;
}

.menu-xts-btn:hover::before {
    opacity: 1;
}

/* Estado hover */
.menu-xts-btn:hover {
    background: linear-gradient(145deg, rgba(var(--xts-main-rgb), 0.15), rgba(var(--xts-main-rgb), 0.25));
    border-color: rgba(var(--xts-main-rgb), 0.8);
    box-shadow: 0 8px 25px rgba(var(--xts-main-rgb), 0.3),
                0 0 40px rgba(var(--xts-main-rgb), 0.2),
                inset 0 1px 0 rgba(var(--xts-main-rgb), 0.3);
}

.menu-xts-btn:hover svg,
.menu-xts-btn:hover i {
    color: var(--xts-main-color);
    stroke: var(--xts-main-color);
    filter: drop-shadow(0 0 8px rgba(var(--xts-main-rgb), 0.8));
    transform: scale(1.1);
}

/* Estado activo/click */
.menu-xts-btn:active {
    transform: translateY(-1px) scale(0.98);
    box-shadow: 0 4px 15px rgba(var(--xts-main-rgb), 0.2),
                0 0 20px rgba(var(--xts-main-rgb), 0.1);
    transition: all 0.1s ease;
}

/* Icono dentro del botón */
.menu-xts-btn svg,
.menu-xts-btn i {
    position: relative;
    z-index: 1;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
}

/* Animación de pulso sutil */
@keyframes pulse-subtle {
    0%, 100% {
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5),
                    0 0 20px rgba(var(--xts-main-rgb), 0.1);
    }
    50% {
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5),
                    0 0 25px rgba(var(--xts-main-rgb), 0.15);
    }
}

.menu-xts-btn {
    animation: pulse-subtle 3s ease-in-out infinite;
}

/* Estilos específicos para cada botón */
.menu-xts-btn:nth-child(1) {
    animation-delay: 0s;
}

.menu-xts-btn:nth-child(2) {
    animation-delay: 1s;
}

/* Variante para botón de settings (engranaje) */
.menu-xts-btn.settings-btn:hover svg,
.menu-xts-btn.settings-btn:hover i {
    transform: scale(1.1) rotate(90deg);
}

/* Variante para botón de menu (hamburguesa) */
.menu-xts-btn.menu-btn:hover svg,
.menu-xts-btn.menu-btn:hover i {
    transform: scale(1.1) rotate(-5deg);
}

/* Tooltip para los botones - MOSTRADO ABAJO */
.menu-xts-btn[data-tooltip] {
    position: relative;
}

.menu-xts-btn[data-tooltip]::after {
    content: attr(data-tooltip);
    position: absolute;
    top: calc(100% + 12px);
    left: 50%;
    transform: translateX(-50%) translateY(-8px);
    color: var(--xts-main-color);
    padding: 8px 16px;
    border-radius: 8px;
    font-size: 11px;
    font-weight: 600;
    white-space: nowrap;
    opacity: 0;
    visibility: hidden;
    pointer-events: none;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    z-index: 99999;
    background: rgba(0,0,0,0.8);
    letter-spacing: 0.5px;
}

/* Flecha del tooltip apuntando hacia arriba */
.menu-xts-btn[data-tooltip]::before {
    content: '';
    position: absolute;
    top: calc(100% + 6px);
    left: 50%;
    transform: translateX(-50%);
    width: 0;
    height: 0;
    border-left: 6px solid transparent;
    border-right: 6px solid transparent;
    border-bottom: 6px solid var(--xts-main-color);
    opacity: 0;
    visibility: hidden;
    pointer-events: none;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    z-index: 99999;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.5));
}

/* Estado hover - tooltip visible con animación */
.menu-xts-btn[data-tooltip]:hover::after {
    opacity: 1;
    visibility: visible;
    transform: translateX(-50%) translateY(0);
}

.menu-xts-btn[data-tooltip]:hover::before {
    opacity: 1;
    visibility: visible;
}

/* Responsive */
@media (max-width: 768px) {
    .menu-xts-buttons {
        right: 140px;
        gap: 8px;
    }

    .menu-xts-btn {
        width: 38px;
        height: 38px;
        font-size: 18px;
    }

    .menu-xts-btn[data-tooltip]::after {
        font-size: 10px;
        padding: 6px 12px;
    }
}

/* Asegurar que contenedores padres no oculten el tooltip */
#menuLogin,
.menu-xts-container,
.menu-xts-buttons {
    overflow: visible !important;
}
/* Modal base */
/* Modal base */
.menu-xts-modal {
    display: none;
    position: fixed;
    top: 50%;
    left: 78%;
    transform: translate(-50%, -50%) scale(0.7);
    color: var(--xts-text-light);
    border-radius: 12px;
    z-index: 1001;
    width: 90%;
    max-width: 400px;
    overflow: hidden;
    border: var(--xts-border);
    font-family: 'Rajdhani';
    font-weight: bold;
    opacity: 0;
    transition: all 0.2s ease;
    background: rgb(0 0 0 / 74%);
}
/* Estado activo - modal visible */
.menu-xts-modal.active {
    display: block;
    opacity: 1;
    transform: translate(-50%, -50%) scale(1);
    animation: modalBounceIn 0.5s cubic-bezier(0.34, 1.56, 0.64, 1);
}

/* Estado de salida */
.menu-xts-modal.closing {
    opacity: 0;
    transform: translate(-50%, -50%) scale(0.8);
    animation: modalFadeOut 0.3s ease-out forwards;
}

/* Animación de entrada con rebote */
@keyframes modalBounceIn {
    0% {
        opacity: 0;
        transform: translate(-50%, -50%) scale(0.5) rotateX(20deg);
    }
    50% {
        transform: translate(-50%, -50%) scale(1.05) rotateX(-5deg);
    }
    70% {
        transform: translate(-50%, -50%) scale(0.95) rotateX(2deg);
    }
    100% {
        opacity: 1;
        transform: translate(-50%, -50%) scale(1) rotateX(0deg);
    }
}

/* Animación de salida suave */
@keyframes modalFadeOut {
    0% {
        opacity: 1;
        transform: translate(-50%, -50%) scale(1);
    }
    100% {
        opacity: 0;
        transform: translate(-50%, -50%) scale(0.7) translateY(20px);
    }
}

/* Efecto de brillo en los bordes del modal */
.menu-xts-modal::before {
    content: '';
    position: absolute;
    top: -2px;
    left: -2px;
    right: -2px;
    bottom: -2px;
    background: linear-gradient(45deg, transparent 30%, rgba(var(--xts-main-rgb), 0.3) 50%, transparent 70%);
    border-radius: 12px;
    opacity: 0;
    z-index: -1;
    background-size: 100% 290%;
}

.menu-xts-modal.active::before {
    opacity: 1;
}


/* Animación de shake para errores */
@keyframes modalShake {
    0%, 100% {
        transform: translate(-50%, -50%) scale(1);
    }
    10%, 30%, 50%, 70%, 90% {
        transform: translate(-48%, -50%) scale(1);
    }
    20%, 40%, 60%, 80% {
        transform: translate(-52%, -50%) scale(1);
    }
}

.menu-xts-modal.shake {
    animation: modalShake 0.5s ease;
}

/* Animación para tabs */
.menu-xts-tab-content {
    transition: opacity 0.3s ease, transform 0.3s ease;
}

.menu-xts-tab-content:not(.active) {
    display: none;
}

.menu-xts-tab-content.active {
    animation: tabSlideIn 0.3s ease;
}

@keyframes tabSlideIn {
    from {
        opacity: 0;
        transform: translateX(20px);
    }
    to {
        opacity: 1;
        transform: translateX(0);
    }
}

/* Animación para los tabs */
.menu-xts-tab {
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.menu-xts-tab.active {
    animation: tabActivate 0.3s ease;
}

@keyframes tabActivate {
    0% {
        transform: scale(0.95);
    }
    50% {
        transform: scale(1.05);
    }
    100% {
        transform: scale(1);
    }
}

/* Responsive */
@media (max-width: 768px) {
    .menu-xts-modal {
        left: 50%;
        max-width: 90%;
    }
}
/* Header del modal */
.menu-xts-modal-header {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--xts-main-color);
  padding: 10px 0px;
  justify-content: center;
}
.menu-xts-modal-header span {
  text-transform: uppercase;
  font-family: "Poppins";
  font-weight: bold;
  font-size: 15px;
}
/* Botones de tabs */
.menu-xts-tabs {
  display: flex;
  justify-content: space-around;
}
.menu-xts-tab {
    background: var(--xts-bg-dark);
    color: var(--xts-main-color);
    padding: 8px 14px;
    border: 1px solid var(--xts-main-color);
    transition: all 0.2s ease;
    width: 100%;
    text-transform: uppercase;
    font-weight: bold;
    font-size: 0.88rem;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
}
.menu-xts-tab:hover,
.menu-xts-tab.active {
  background: var(--xts-main-color);
  color: var(--xts-bg-dark);
}
/* Contenido de cada tab */
.menu-xts-tab-content {
  display: none;
}
.menu-xts-tab-content.active {
  display: flex;
  flex-direction: column;
  gap: 10px;
  height: 430px;
  align-items: center;
  padding: 20px;
  overflow: auto;
}
/* Botones de conversión */
.xts-convert-buttons {
    display: flex;
    flex-direction: column;
    gap: 10px;
    width: 100%;
}
.xts-convert-btn {
    padding: 10px;
    background: var(--xts-main-color);
    color: #111;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 14px;
    transition: background 0.2s;
}
.xts-convert-btn:hover {
    background: #ff6b6b;
}
/* Grupo de botones de acción */
.xts-action-btn-group {
    position: relative;
    display: inline-block;
}
/* Dropdown de bonus */
.xts-bonus-dropdown {
    display: none;
    position: absolute;
    top: calc(100% + 8px);
    left: 0;
    right: 0;
    z-index: 100;
    opacity: 0;
    transform: translateY(-10px) scale(0.95);
    transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1),
                transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    pointer-events: none;
}

.xts-bonus-dropdown.xts-show {
    opacity: 1;
    transform: translateY(0) scale(1);
    pointer-events: auto;
}

.xts-bonus-dropdown-content {
    display: flex;
    flex-direction: column;
    gap: 6px;
    background: linear-gradient(135deg, #0a0a0a 0%, #141414 100%);
    border-radius: 12px;
    border: 1px solid rgba(var(--xts-main-rgb), 0.2);
    padding: 8px;
    overflow: hidden;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6),
                0 0 20px rgba(var(--xts-main-rgb), 0.1),
                inset 0 1px 0 rgba(255, 255, 255, 0.05);
    background: rgba(18, 18, 18, 0.9);
}

.xts-bonus-dropdown-content button {
    position: relative;
    padding: 1px 16px;
    font-size: 13px;
    font-weight: 600;
    background: linear-gradient(135deg, #1a1a1a 0%, #0f0f0f 100%);
    border: 1px solid #2a2a2a;
    border-radius: 8px;
    color: #fff;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    overflow: hidden;
    text-align: center;
    letter-spacing: 0.5px;
}

.xts-bonus-dropdown-content button::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg,
                transparent,
                rgba(var(--xts-main-rgb), 0.15),
                transparent);
    transition: left 0.5s ease;
}

.xts-bonus-dropdown-content button:hover::before {
    left: 100%;
}

.xts-bonus-dropdown-content button:hover {
    background: linear-gradient(135deg, #1a3a3a 0%, #0f2a2a 100%);
    border-color: rgba(var(--xts-main-rgb), 0.5);
    color: var(--xts-main-color);
    transform: translateY(-2px) scale(1.02);
    box-shadow: 0 4px 16px rgba(var(--xts-main-rgb), 0.3),
                0 0 20px rgba(var(--xts-main-rgb), 0.15),
                inset 0 1px 0 rgba(var(--xts-main-rgb), 0.2);
}

.xts-bonus-dropdown-content button:active {
    transform: translateY(0) scale(0.98);
    transition: all 0.1s ease;
}

/* Efecto de brillo en los bordes al hover */
.xts-bonus-dropdown-content button::after {
    content: '';
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle,
                rgba(0, 255, 255, 0.1) 0%,
                transparent 70%);
    opacity: 0;
    transition: opacity 0.3s ease;
    pointer-events: none;
}

.xts-bonus-dropdown-content button:hover::after {
    opacity: 1;
}

/* Estilo para el primer botón (Todo) */
.xts-bonus-dropdown-content button:first-child {
    background: linear-gradient(135deg, #1a2a1a 0%, #0f1f0f 100%);
    border-color: rgba(0, 255, 100, 0.3);
}

.xts-bonus-dropdown-content button:first-child:hover {
    background: linear-gradient(135deg, #2a4a2a 0%, #1f3a1f 100%);
    border-color: rgba(0, 255, 100, 0.6);
    color: #0f6;
    box-shadow: 0 4px 16px rgba(0, 255, 100, 0.3),
                0 0 20px rgba(0, 255, 100, 0.15);
}

/* Animación de entrada escalonada para los botones */
.xts-bonus-dropdown.xts-show .xts-bonus-dropdown-content button {
    animation: slideInButton 0.3s cubic-bezier(0.4, 0, 0.2, 1) backwards;
}

.xts-bonus-dropdown.xts-show .xts-bonus-dropdown-content button:nth-child(1) {
    animation-delay: 0.05s;
}

.xts-bonus-dropdown.xts-show .xts-bonus-dropdown-content button:nth-child(2) {
    animation-delay: 0.1s;
}

.xts-bonus-dropdown.xts-show .xts-bonus-dropdown-content button:nth-child(3) {
    animation-delay: 0.15s;
}

.xts-bonus-dropdown.xts-show .xts-bonus-dropdown-content button:nth-child(4) {
    animation-delay: 0.2s;
}

@keyframes slideInButton {
    from {
        opacity: 0;
        transform: translateX(-20px);
    }
    to {
        opacity: 1;
        transform: translateX(0);
    }
}

/* Responsive adjustments */
@media (max-width: 768px) {
    .xts-bonus-dropdown-content button {
        padding: 10px 12px;
        font-size: 12px;
    }
}
/* AJUSTES PRO  NORMAL */

#yesno_settings {
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: 5px;
}




.prospanxts {
    font-size: 13px;
    text-transform: uppercase;
}
input:-webkit-autofill,
input:-webkit-autofill:hover,
input:-webkit-autofill:focus,
input:-webkit-autofill:active {
  background-clip: text;
  -webkit-text-fill-color: #fff;
  transition: background-color 5000s ease-in-out 0s;
}
input:-webkit-autofill {
  -webkit-text-fill-color: white !important;
}
/* Botón de login */
.menu-xts-login-btn {
    width: 100%;
    padding: 5px 20px;
    background: #111111;
    color: #ffffff;
    border: none;
    border-radius: 6px;
    font-size: 13px;
    cursor: pointer;
    transition: background 0.2s ease;
    position: relative;
    border: 1px solid #3f3f3f;
    text-transform: uppercase;
    font-weight: bold;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
}
.menu-xts-login-btn:hover {
  background: #00ccff;
  color:black;
}
.loading {
  pointer-events: none;
  color: transparent;
  background: black;
  border: 1px solid #3f3f3f;
}
.loading::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: 15px;
  height: 15px;
  border: 2px solid #fff;
  border-top-color: transparent;
  border-radius: 50%;
  transform: translate(-50%, -50%);
  animation: spinner 0.7s linear infinite;
  box-shadow: 0 0 6px #fff;
  z-index: 1;
}

@keyframes spinner {
  to {
    transform: translate(-50%, -50%) rotate(360deg);
  }
}

/* Lista de "Más opciones" */

.button-proxts-infox {
    padding: 5px 20px;
    background: var(--xts-bg-dark);
    border-radius: 6px;
    color: var(--xts-text-light);
    display: flex;
    gap: 15px;
    cursor: pointer;
    transition: background 0.2s ease;
    font-size: 13px;
    border: 1px solid #3f3f3f;
    width: 100%;
    text-decoration: none;
    flex-direction: row;
    align-items: center;
    font-weight: bold;
    text-transform: uppercase;
}
.button-proxts-infox:hover {
  background: var(--xts-main-color);
  color: var(--xts-bg-dark);
}
.button-proxts-infox i {
    font-size: 13px;
}
/* Botón cerrar */
.menu-xts-close {
    padding: 8px 12px;
    background: var(--xts-main-color);
    color: #000000;
    border: none;
    transition: background 0.2s ease;
    width: 100%;
    font-family: "Poppins";
    font-size: 13px;
    font-weight: bold;
    text-transform: uppercase;
}
.menu-xts-close:hover {
    background: #121212;
    color: white;
}

/* ===================== THEME CUSTOMIZATION - MINIMALISTA ===================== */
.settings-section {
  width: 100%;
  margin-bottom: 20px;
  animation: fadeInUp 0.5s ease-out;
}

.section-title {
  font-size: 12px;
  font-weight: 600;
  color: var(--xts-main-color);
  margin-bottom: 10px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  display: flex;
  align-items: center;
  gap: 6px;
  opacity: 0.9;
}

.section-title i {
  font-size: 11px;
}

.theme-grid-mini {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 6px;
  margin-bottom: 12px;
}

.theme-btn-mini {
  background: rgba(255, 255, 255, 0.03);
  border: 1.5px solid rgba(255, 255, 255, 0.1);
  border-radius: 6px;
  padding: 8px 4px;
  cursor: pointer;
  transition: all 0.25s ease;
  position: relative;
  overflow: hidden;
}

.theme-btn-mini::before {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(var(--xts-main-rgb), 0.1);
  opacity: 0;
  transition: opacity 0.3s ease;
}

.theme-btn-mini:hover {
  border-color: var(--xts-main-color);
  transform: translateY(-1px);
}

.theme-btn-mini:hover::before {
  opacity: 1;
}

.theme-btn-mini.active {
  border-color: var(--xts-main-color);
  background: rgba(var(--xts-main-rgb), 0.15);
  box-shadow: 0 0 10px rgba(var(--xts-main-rgb), 0.3);
}

.theme-dots {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 3px;
}

.theme-dots span {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);
}

.custom-section-mini {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 6px;
  padding: 8px;
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.color-row {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr auto;
  gap: 6px;
  margin-bottom: 6px;
}

.color-row input[type="color"] {
  width: 100%;
  height: 32px;
  border: 1.5px solid rgba(255, 255, 255, 0.15);
  border-radius: 4px;
  background: transparent;
  cursor: pointer;
  transition: all 0.2s ease;
}

.color-row input[type="color"]:hover {
  border-color: var(--xts-main-color);
  transform: scale(1.05);
}

.btn-apply-mini {
  background: var(--xts-main-color);
  color: #000;
  border: none;
  border-radius: 4px;
  width: 32px;
  height: 32px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-apply-mini:hover {
  transform: scale(1.1);
  box-shadow: 0 0 10px rgba(var(--xts-main-rgb), 0.5);
}

.btn-apply-mini:active {
  transform: scale(0.95);
}

.input-mini {
  width: 100%;
  padding: 6px 8px;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 4px;
  color: #fff;
  font-size: 11px;
  font-family: 'Poppins', sans-serif;
  transition: all 0.2s ease;
}

.input-mini:focus {
  outline: none;
  border-color: var(--xts-main-color);
  box-shadow: 0 0 8px rgba(var(--xts-main-rgb), 0.2);
  background: rgba(0, 0, 0, 0.4);
}

.input-mini::placeholder {
  color: #555;
  font-size: 10px;
}

/* Eliminar estilos antiguos que ya no se usan */
  cursor: pointer;
  transition: all 0.3s ease;
  font-family: 'Poppins', sans-serif;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  position: relative;
  overflow: hidden;
}

/*MENU -LOGIN PROFILE*/
.xts-banner{
    margin: 10px 0px;
}

.xts-login-container{
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: 10px;
    align-items: center;
}

.formlogin-xts{
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: 20px;
    align-items: center;
}
.xts-login-msg {
    padding: 6px 10px;
    font-size: 13px;
    font-family: 'Poppins', sans-serif;
    border-radius: 8px;
    color: #f55;
    display: none;
    text-align: center;
    transition: all 0.3s ease;
    background: #313131;
    position: absolute;
}
.menu-xts-actions {
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: 10px;
}
.xts-input-group{
    display: flex;
    flex-direction: column;
    gap: 10px;
    width: 100%;
}
.menu-xts-profile {
    width: 100%;
    display: flex;
    align-items: flex-start;
    gap: 10px;
    flex-direction: column;
    color: #fff;
    font-family: 'Segoe UI', sans-serif;
}

/* ===================== NUEVO PERFIL MODERNO ===================== */
.xts-profile-modern {
    width: 100%;
    color: #fff;
    font-family: 'Rajdhani';
    position: relative;
}
@keyframes gradientFlow {
    0%, 100% { opacity: 0.8; }
    50% { opacity: 1; }
}

/* === HEADER DEL PERFIL === */
.xts-profile-header {
    display: flex;
    align-items: center;
    gap: 20px;
    margin-bottom: 25px;
    position: relative;
    z-index: 2;
}

.xts-user-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.xts-username {
    font-size: 20px;
    font-weight: 700;
    color: #fff;
    margin: 0;
    background: var(--xts-main-color);
    /* -webkit-background-clip: text; */
    -webkit-text-fill-color: transparent;
    background-clip: text;
}

.xts-user-id {
    display: flex;
    align-items: center;
    gap: 8px;
    border-radius: 12px;
}
.xts-id-label {
    font-size: 12px;
    color: #aaa;
    font-weight: 600;
}

.xts-id-value {
    font-size: 14px;
    color: var(--xts-main-color);
    font-weight: bold;
}

.xts-copy-btn {
    background: none;
    border: none;
    color: var(--xts-main-color);
    cursor: pointer;
    padding: 4px;
    border-radius: 6px;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
}

.xts-copy-btn:hover {
    background: rgba(var(--xts-main-rgb), 0.2);
    transform: scale(1.1);
}

/* === ESTADÍSTICAS === */
.xts-stats-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
    margin-bottom: 25px;
}

.xts-stat-card {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 15px;
    padding: 15px;
    display: flex;
    align-items: center;
    gap: 12px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    transition: all 0.3s ease;
    position: relative;
    overflow: hidden;
}

.xts-stat-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.1), transparent);
    transition: left 0.6s ease;
}

.xts-stat-card:hover::before {
    left: 100%;
}

.xts-stat-card:hover {
    transform: translateY(-2px);
    border-color: rgba(var(--xts-main-rgb), 0.5);
    box-shadow: 0 5px 20px rgba(var(--xts-main-rgb), 0.2);
}

.xts-stat-icon {
    width: 40px;
    height: 40px;
    border-radius: 12px;
    background: linear-gradient(135deg, var(--xts-main-color), #0099cc);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #000;
    font-size: 18px;
    flex-shrink: 0;
}

.xts-stat-info {
    display: flex;
    flex-direction: column;
    gap: 2px;
}

.xts-stat-label {
    font-size: 12px;
    color: #aaa;
    font-weight: 600;
}

.xts-stat-value {
    font-size: 16px;
    color: #fff;
    font-weight: 700;
    font-family: 'Courier New', monospace;
}

/* === ACCIONES MODERNAS === */
.xts-actions-modern {
    display: flex;
    flex-direction: column;
    gap: 12px;
    margin-bottom: 20px;
}
.xts-action-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
}

.xts-action-btn {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 12px;
    padding: 7px 8px;
    display: flex;
    align-items: center;
    gap: 10px;
    text-decoration: none;
    color: #fff;
    border: 1px solid rgba(255, 255, 255, 0.1);
    transition: all 0.3s ease;
    position: relative;
    overflow: hidden;
    cursor: pointer;
    width: 100%;
}

.xts-action-btn::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(135deg, transparent, rgba(255, 255, 255, 0.1));
    opacity: 0;
    transition: opacity 0.3s ease;
}

.xts-action-btn:hover::before {
    opacity: 1;
}

.xts-action-btn:hover {
    background: rgba(var(--xts-main-rgb), 0.2);
    color: var(--xts-main-color);
    box-shadow: 0 0 8px rgba(var(--xts-main-rgb), 0.3);
}
.xts-btn-icon {
    width: 36px;
    height: 36px;
    border-radius: 10px;
    background: transparent;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--xts-main-color);
    font-size: 16px;
    flex-shrink: 0;
    transition: all 0.3s ease;
}
.xts-btn-content {
    display: flex;
    flex-direction: column;
    gap: 2px;
    flex: 1;
    align-items: flex-start;
}

.xts-btn-title {
    font-size: 13px;
    font-weight: 600;
    text-transform: uppercase;
}

.xts-btn-subtitle {
    font-size: 11px;
    color: #aaa;
    font-weight: bold;
     text-transform: uppercase;
}

/* === LOGOUT SECTION === */
.xts-logout-section {
    padding-top: 20px;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.xts-logout-btn {
    width: 100%;
    font-weight: 600;
    font-size: 13px;
    justify-content: center;
    transition: all 0.3s ease;
    position: relative;
    overflow: hidden;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 12px;
    padding: 7px 8px;
    display: flex;
    gap: 10px;
    text-decoration: none;
    color: #fff;
    border: 1px solid rgba(255, 255, 255, 0.1);
    align-items: center;
    text-transform: uppercase;
}
.xts-logout-btn:hover {
    background: rgba(var(--xts-main-rgb), 0.2);
    color: var(--xts-main-color);
    box-shadow: 0 0 8px rgba(var(--xts-main-rgb), 0.3);
}

.xts-logout-ripple {
    position: absolute;
    top: 50%;
    left: 50%;
    width: 0;
    height: 0;
    background: rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    transform: translate(-50%, -50%);
    transition: width 0.3s ease, height 0.3s ease;
}

.xts-logout-btn:active .xts-logout-ripple {
    width: 200px;
    height: 200px;
}

/* === AVATARES LEGACY (mantenemos para compatibilidad) === */
.menu-xts-avatar{
    width: 100%;
    border-radius: 50%;
}
.menu-xts-avatar img{
    width: 100px;
    border-radius: 50%;
}
.xts-conte-avatar{
    width: 110px;
    height: 110px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
    background: #000000b3;
}
.xts-conte-avatar::before {
    content: "";
    position: absolute;
    width: 200%;
    height: 200%;
    background: conic-gradient(from 0deg, var(--xts-main-color), var(--xts-secondary-color), var(--xts-accent-color), var(--xts-main-color));
    animation: rotateAura 4s linear infinite;
    z-index: 0;
    border-radius: 50%;
}
#xts-avatar img {
    opacity: 1;
    display: block;
    background-size: cover;
    backface-visibility: hidden;
    z-index: 1;
}

.menu-xts-info{
    width: 100%;
}
.menu-xts-info h5 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #00f2ff;
}

.menu-xts-info span {
    font-size: 15px;
    color: #ccc;
    display: flex;
    align-items: center;
}

.btn-junte-2 {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 12px;
    width: 100%;
}
.button-proxts-infox {
    flex: 1 1 calc(50% - 4px);
    box-sizing: border-box;
}



/* ===================== MODALES ===================== */
#overlays {
    display: none;
    position: absolute;
    inset: 0;
    background: #00000042;
    z-index: 200;
    user-select: none;
}
#idMobileDownload {
  position: absolute;
  width: 156px;
  right: -156px;
  top: 495px;
  background-color: #ffffff;
  padding: 1px;
}
#idPartnerKafeler {
  position: absolute;
  width: 250px;
  right: -250px;
  top: 550px;
  background: rgba(0, 0, 0, 0.5);
  padding: 1px;
}
#enterPriceConfirmDialog {
  z-index: 301;
  background-color: #ffffff;
  margin: 10px auto;
  border-radius: 15px;
  padding: 25px;
  position: absolute;
  top: 50%;
  left: 50%;
  display: none;
  transform: translate(-50%, -50%);
  font-size: 20px;
}
.myDialog {
  z-index: 302;
  background-color: #ffffff;
  margin: 10px auto;
  border-radius: 15px;
  padding: 25px;
  position: absolute;
  top: 50%;
  left: 50%;
  display: none;
  transform: translate(-50%, -50%);
  font-size: 20px;
  border: 5px solid #ff0000;
}
#finalList td {
  padding: 5px;
  font-family: fantasy;
}
#finalLeaderboardDialog {
  z-index: 303;
  background-color: #ffffff;
  margin: 10px auto;
  border-radius: 15px;
  padding: 25px;
  position: absolute;
  top: 50%;
  left: 50%;
  display: none;
  transform: translate(-50%, -50%);
  font-size: 20px;
  border: 5px solid #000000;
  box-shadow: inset 0px 0px 15px 0px;
}
#idAdminPanel {
  position: absolute;
  width: 350px;
  right: -360px;
  top: 0px;
  color: #111111;
  background-color: #00ff00;
  padding: 5px;
}
.talkButton:active {
  background-color: #aa0000;
  color: #ffffff;
}

/* ===================== CHAT MENU XTS ===================== */
#chatMenu {
  max-width: 0;
  opacity: 0;
  visibility: hidden;
  transition: max-width 0.3s ease, margin 0.3s ease, opacity 0.3s ease;
  flex-direction: row;
  gap: 6px;
  margin: 0;
  display: flex;
}
#chatMenu.open {
  max-width: 100%;
  opacity: 1;
  visibility: visible;
  margin: 0px 10px;
}
.bottomContainer {
    position: absolute;
    bottom: 0;
    left: 0;
    z-index: 10;
    max-width: 900px;
    background: rgb(20 20 20 / 0%);
    backdrop-filter: blur(4px);
    display: flex;
    align-items: center;
    color: #fff;
    transition: all 0.3s ease-in-out;
}
.chat-container {
    display: flex;
    align-items: center;
    font-family: "Segoe UI", sans-serif;
    box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.4);
    overflow: hidden;
    border-top-right-radius: 12px;
        background: #0000005c;
}
.chat-input-wrapper {
  display: flex;
  align-items: center;
  position: relative;
}
#chat_textbox {
  background: #222;
  border: none;
  color: #fff;
  width: 280px;
  transition: background 0.3s;
  border: none;
  height: 35px;
  padding: 0px 10px;
}
#chat_textbox:focus {
  background: #333;
  outline: none;
}
.icon-button {
  background: #1a1a1a;
  color: white;
  border: none;
  width: 35px;
  height: 35px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 15.5px;
  cursor: pointer;
  transition: background 0.3s ease-in-out, box-shadow 0.3s ease-in-out;
}
/* === HOVERS PERSONALIZADOS POR TIPO DE ICONO === */
.icon-button:hover {
  background: #2c2c2c;
}
.icon-button.trash:hover {
  background: #e74c3c;
  box-shadow: 0 0 8px #e74c3c;
}
.icon-button.help:hover {
  background: #3498db;
  box-shadow: 0 0 8px #3498db;
}
.icon-button.emoji:hover {
  background: #f1c40f;
  box-shadow: 0 0 8px #f1c40f;
  color: #222;
}
.icon-button.settings:hover {
  background: #9b59b6;
  box-shadow: 0 0 8px #9b59b6;
}
.icon-button.report:hover {
  background: #ff0055;
  box-shadow: 0 0 8px #ff0055;
}
/* Emojis internos */
.emoji-list .icon-button:hover {
  background: var(--xts-main-color);
  box-shadow: 0 0 8px rgba(var(--xts-main-rgb), 1);
  color: #000;
}
.chat-commands {
    display: none;
    position: absolute;
    bottom: 40px;
    left: 350px;
    background: #1a1a1a;
    color: #eee;
    padding: 10px 15px;
    border-radius: 10px;
    font-size: 14px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
    z-index: 999;
    width: 335px;
}
.chat-commands.show {
    display: block;
}
.chat-commands ul {
    list-style: none;
    padding: 0;
    margin: 0;
    font-family: 'Rajdhani', sans-serif;
    font-weight: bold;
    font-size: 13.5px;
}
.chat-commands li {
    margin: 10px 0;
    display: flex;
    gap: 5px;
}
.chat-commands kbd {
    background: #333;
    padding: 2px 6px;
    border-radius: 5px;
    font-size: 13px;
    font-family: monospace;
    cursor: pointer;
    width: 105px;
    display: flex;
    justify-content: center;
}

.emoji-list {
  display: none;
  gap: 6px;
  flex-wrap: wrap;
  padding: 10px;
  background: #1a1a1a;
  border-radius: 10px;
  position: absolute;
  top: 60px;
  z-index: 100;
}
.chat-mode-button {
  background: #373737;
  color: #ccc;
  border: none;
  padding: 7px;
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.25s ease-in-out;
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: none;
  outline: none;
}
.chat-mode-button:hover {
  background: #2a2a2a;
  color: #fff;
  transform: scale(1.1);
}
/* -- ESTILOS ACTIVOS PERSONALIZADOS -- */
#chatToAll.active {
  box-shadow: 0 0 10px #3498db;
  background: #3498db;
  color: white;
}
#chatToTeam.active {
  box-shadow: 0 0 10px #ffe000;
  background: #ffe000;
  color: #000000;
}
#chatToClan.active {
  box-shadow: 0 0 10px #27ff00;
  background: #27ff00;
  color: #000000;
}
#chatToAgarZ.active {
  box-shadow: 0 0 10px #00f3ff;
  background: #00f3ff;
  color: #222;
}
#chatFilter.active {
  box-shadow: 0 0 10px #ff9900;
  background: #ff9900;
  color: #222;
}

/* ===================== CARRUSEL MASTER ===================== */
#xts-car-wrapper {
    width: 120px !important;
    position: absolute !important;
    opacity: 0 !important;
    pointer-events: none !important;
    transform: translateX(10px) scale(0.2) !important;
    transition: opacity 0.4s ease, transform 0.4s ease, left 0.4s ease !important;
    z-index: -1 !important;
}

#xts-car-wrapper.visible {
    opacity: 1 !important;
    pointer-events: auto !important;
    transform: translateX(-80px) scale(1) !important;
}

/* ===================== CARRUSEL INTERNO ===================== */
#xts-car-pro {
    height: 330px;
    overflow: auto;
    margin: auto;
    background: #18171700;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    padding: 0 20px;
}

/* Ocultar scroll nativo */
#xts-car-pro::-webkit-scrollbar {
    width: 0 !important;
    height: 0 !important;
}

/* ===================== SKIN ITEM ===================== */
.img-div-pro {
    scroll-snap-align: center;
    border-radius: 50%;
    cursor: pointer;
    margin: 6px 0;
    width: 70px;
    height: 70px;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    transition: all 0.3s ease;
    box-shadow: 0 0 0 0.3rem rgba(191, 191, 191, 0.27);
}

.skin-inactive {
    opacity: 0.4;
    box-shadow: 0 0 0 0.3rem rgb(159, 0, 0) !important;
    pointer-events: none;
    cursor: not-allowed;
}

.skin-img {
    object-fit: cover;
    border-radius: 50%;
}

/* ===================== ANIMACIÓN BOUNCE ===================== */
@keyframes bounce {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-15px); }
}

#xts-car-pro.bounce {
    animation: bounce 0.5s ease;
    animation-fill-mode: none;
    will-change: transform;
}


/* ===================== UTILS ===================== */


*::-webkit-scrollbar {
  width: 3px !important;
}

*::-webkit-scrollbar-thumb {
  background-color: #666 !important;
  border-radius: 0 !important;
  border: none !important;
}

*::-webkit-scrollbar-track {
  background: #3b3b3bd6 !important;
}


.dificil {
    width: 100%;
}
.dificil a {
  display: block;
  text-decoration: none;
  color: white;
  padding: 6px 10px;
  border-radius: 5px;
  transition: background 0.3s ease, color 0.3s ease;
  width: 100%;
  background: rgba(255, 255, 255, 0.05);
  font-size: 13px;
      text-transform: uppercase;
}

.dificil a:hover {
  background: rgba(var(--xts-main-rgb), 0.2);
  color: var(--xts-main-color);
  box-shadow: 0 0 8px rgba(var(--xts-main-rgb), 0.3);
}

.gold-cost {
  font-size: 12px;
  opacity: 0.8;
}
.modern-button {
  background: #4a90e2;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: background 0.3s;
}
.modern-button:hover {
  background: #357ab8;
}
.danger {
  background: #c71300;
}
.danger:hover {
  background: #c0392b;
}
.report-button {
  margin-left: auto;
}

`,
    )
    .appendTo("head");
})(window.jQuery);

(function () {
  "use strict";

  $(document).on("keydown", function (e) {
    if ($(e.target).is("input, textarea")) return;

    if (typeof e.key === "string" && e.key.toLowerCase() === "p") {
      const wrapper = document.getElementById("xts-shadow-wrapper");
      if (!wrapper) return;

      const host = wrapper.shadowRoot.querySelector("#time-master");
      if (!host) return;

      if (host.classList.contains("oculto")) {
        host.style.display = "flex";
        requestAnimationFrame(() => host.classList.remove("oculto"));
      } else {
        host.classList.add("oculto");
        setTimeout(() => (host.style.display = "none"), 400);
      }
    }
  });

  $(document).ready(function () {
    const CACHE_KEY = "tablaDatos";
    const INTERVALO_SOLICITUD = 7000;
    let timeoutActualizacion = null;
    let tiemposActuales = [];
    let filtro = { min: 1, max: 10 };

    // Shadow host
    const wrapper = document.createElement("div");
    wrapper.id = "xts-shadow-wrapper";
    const shadow = wrapper.attachShadow({ mode: "open" });
    document.body.appendChild(wrapper);

    // === Tooltip flotante global ===
    const globalTooltip = document.createElement("div");
    globalTooltip.id = "xts-global-tooltip";
    globalTooltip.innerHTML = `<div class="xts-bubble">Tooltip</div><div class="xts-arrow"></div>`;
    globalTooltip.style.cssText = `
  position: fixed;
  pointer-events: none;
  opacity: 0;
  z-index: 10000;
  transition: opacity 0.2s ease;
`;
    document.body.appendChild(globalTooltip);

    // Añade el estilo desde JS
    const tooltipStyle = document.createElement("style");
    tooltipStyle.textContent = `
#xts-global-tooltip .xts-bubble {
    background: rgba(var(--xts-main-rgb), 0.12);
    color: var(--xts-main-color);
    padding: 6px 10px;
    border-radius: 8px;
    font-size: 12px;
    font-weight: 600;
    white-space: nowrap;
    backdrop-filter: blur(3px);
    border: 1px solid rgba(var(--xts-main-rgb), 0.3);
    box-shadow: 0 0 12px rgba(var(--xts-main-rgb), 0.3);
    position: relative;
}
#xts-global-tooltip .xts-arrow {
  position: absolute;
  top: 50%;
  right: -6px;
  transform: translateY(-50%);
  width: 0;
  height: 0;
  border-top: 6px solid transparent;
  border-bottom: 6px solid transparent;
  border-left: 6px solid rgba(var(--xts-main-rgb), 0.3);
}
`;
    document.head.appendChild(tooltipStyle);

    const style = document.createElement("style");
    style.textContent = `
@import url('https://fonts.googleapis.com/css2?family=Rajdhani:wght@400;500;600;700&display=swap');

* {
    font-size: 13px;
    font-family: 'Rajdhani', sans-serif;
    box-sizing: border-box;
    font-weight: bold;
}

#time-master {
    position: fixed;
    top: 50vh;
    right: .5vw;
    display: flex
;
    flex-direction: column;
    align-items: stretch;
    border-radius: 10px;
    z-index: 9999;
    transition: opacity 0.4s ease, transform 0.3s ease;
    background: rgba(0, 0, 0, 0.8);
    border: 1px solid rgb(145 145 145 / 20%);
    width: auto;
    min-width: 100px;
    max-width: 180px;
    overflow: hidden;
    background: rgb(23 23 23 / 80%);
    font-weight: 600;
    color: #eee;
}
#time-master.oculto {
    opacity: 0;
    pointer-events: none;
    transform: translateX(10px);
}
.header {
    width: 100%;
    display: flex;
    justify-content: center;
}
#toggle-range {
    position: relative;
    width: 100%;
    font-weight: bold;
    font-size: 13px;
    padding: 3px 0;
    background: var(--xts-main-color);
    color: #000;
    border: none;
    cursor: pointer;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    transition: background 0.2s ease, color 0.2s ease;
}
#toggle-range:hover {
    background: #00e0ff;
}
#toggle-range.loading {
    pointer-events: none;
    color: transparent;
    background: #000;
}
#toggle-range.loading::after {
    content: "";
    position: absolute;
    top: 50%;
    left: 50%;
    width: 14px;
    height: 14px;
    border: 2px solid #fff;
    border-top-color: transparent;
    border-radius: 50%;
    transform: translate(-50%, -50%);
    animation: spinner 0.6s linear infinite;
    box-shadow: 0 0 4px #fff;
}
@keyframes spinner {
    to {
        transform: translate(-50%, -50%) rotate(360deg);
    }
}
#time-list {
    max-height: 222px;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    scrollbar-width: none;
    width: 100%;
}
#time-list::-webkit-scrollbar {
    width: 0;
    height: 0;
}
.animated-button {
    display: flex;
    justify-content: center;
    align-items: center;
    font-weight: 500;
    font-size: 13px;
    color: #eee;
    width: 100%;
    padding: 5px 4px;
    background: transparent;
    border: none;
    transition: background 0.2s ease, color 0.2s ease;
    border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}
.animated-button:hover {
    background: rgba(var(--xts-main-rgb), 0.08);
    color: var(--xts-main-color);
}
.eoxps-xts {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    gap: 6px;
}
`;

    const container = document.createElement("div");
    container.id = "time-master";
    container.innerHTML = `
        <div class="header">
            <button id="toggle-range" title="Cambiar rango">${filtro.min}-${filtro.max}</button>
        </div>
        <div id="time-list"></div>
    `;

    shadow.appendChild(style);
    shadow.appendChild(container);

    const scrollTarget = shadow.querySelector("#time-list");
    if (scrollTarget) {
      scrollTarget.addEventListener(
        "wheel",
        function (event) {
          if (this.scrollHeight > this.clientHeight) {
            event.stopPropagation();
          }
        },
        { passive: true },
      );
    }

    const toggleBtn = shadow.querySelector("#toggle-range");
    toggleBtn.addEventListener("click", async () => {
      toggleBtn.classList.add("loading");
      filtro = filtro.min === 1 ? { min: 50, max: 59 } : { min: 1, max: 10 };
      toggleBtn.textContent = `${filtro.min}-${filtro.max}`;
      await obtenerTiempos();
      toggleBtn.classList.remove("loading");
    });

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
          if (total >= filtro.min && total <= filtro.max) {
            const texto = fila.querySelector("td")?.innerText || "";
            tiempos.push({ texto, tiempo: total });
          }
        }

        tiempos.sort((a, b) => a.tiempo - b.tiempo);
        const top12 = tiempos.slice(0, 12).map((obj) => ({
          texto: obj.texto,
          tiempo: obj.tiempo.toFixed(2),
        }));

        localStorage.setItem(CACHE_KEY, JSON.stringify(top12));
        tiemposActuales = top12;
        actualizarLista(top12);
      } catch (err) {
        console.error("Error al obtener tiempos:", err);
      }
    }

    function actualizarLista(tiempos) {
      const lista = shadow.querySelector("#time-list");

      // Verifica si los datos han cambiado para evitar reconstrucciones innecesarias
      const actual = JSON.stringify(tiempos.map((t) => t.texto + t.tiempo));
      if (lista.dataset.lastData === actual) return;
      lista.dataset.lastData = actual;

      lista.innerHTML = "";

      tiempos.forEach((obj, idx) => {
        const tiempoFmt = formatearTiempo(obj.tiempo);
        const btn = document.createElement("button");
        btn.className = "animated-button";
        btn.innerHTML = `
            <span class="eoxps-xts">
               ${obj.texto}
            </span>
        `;

        btn.addEventListener("mouseenter", (e) => {
          const bubble = globalTooltip.querySelector(".xts-bubble");
          bubble.textContent = tiempoFmt;
          globalTooltip.style.opacity = "1";
          const rect = btn.getBoundingClientRect();
          globalTooltip.style.top = `${rect.top + window.scrollY}px`;
          globalTooltip.style.left = `${
            rect.left + window.scrollX - globalTooltip.offsetWidth - 12
          }px`;
        });

        btn.addEventListener("mousemove", (e) => {
          const rect = btn.getBoundingClientRect();
          globalTooltip.style.top = `${rect.top + window.scrollY}px`;
          globalTooltip.style.left = `${
            rect.left + window.scrollX - globalTooltip.offsetWidth - 12
          }px`;
        });

        btn.addEventListener("mouseleave", () => {
          globalTooltip.style.opacity = "0";
        });

        btn.addEventListener("click", () => {
          entrarJuego(obj.texto);
          btn.blur();
        });

        lista.appendChild(btn);
      });
    }

    function formatearTiempo(decimal) {
      const min = Math.floor(decimal);
      const sec = Math.round((decimal - min) * 60);
      return `${min}:${sec.toString().padStart(2, "0")}`;
    }

    function entrarJuego(salaTexto) {
      const select = document.getElementById("gamemode");
      const inst =
        select.choicesInstance ||
        select._choices ||
        Choices?.instances?.find((i) => i.passedElement?.element === select);
      const autoplay = typeof presionandoH !== "undefined" && presionandoH;
      if (autoplay) simularDetener();

      let value;
      for (const opt of select.options) {
        if (opt.textContent.includes(salaTexto)) {
          value = opt.value;
          break;
        }
      }

      if (!value) return console.warn("❌ Sala no encontrada:", salaTexto);

      try {
        inst?.setChoiceByValue?.(value);
        select.value = value;
        select.dispatchEvent(new Event("change"));
      } catch {}

      setTimeout(() => {
        $("#playBtn").trigger("click");
        if (autoplay) setTimeout(() => iniciarAutoplay(), 100);
      }, 700);
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

Cell.prototype.updatePos = function () {
  var _0x220aec = a0_0x59a8c2;
  const speedFactor = 4;
  const now = Date.now();
  const elapsedTime = now - updateNodes2_last;
  let _0x3b361e;

  // Cálculo del factor de interpolación (actualizado)
  if (options[_0x220aec(0x143)]("quickSplit") === true) {
    _0x3b361e = elapsedTime / updateNodes2_span;
  } else {
    _0x3b361e = (timestamp - this[_0x220aec(0x25a)]) / 125 / speedFactor;
  }

  // Limitar entre 0 y 1
  _0x3b361e = Math.max(0, Math.min(1, _0x3b361e));

  // Suavizado (ease-out quadratic)
  function easeOutQuad(t) {
    return t * (2 - t);
  }
  const eased = easeOutQuad(_0x3b361e);

  // Interpolación de posición y tamaño
  this["x_draw"] =
    this[_0x220aec(0x2d3)] +
    (this[_0x220aec(0x2a3)] - this[_0x220aec(0x2d3)]) * eased;
  this["y_draw"] =
    this[_0x220aec(0x19e)] +
    (this[_0x220aec(0x2cf)] - this[_0x220aec(0x19e)]) * eased;
  this["size_draw"] =
    this[_0x220aec(0x108)] +
    (this[_0x220aec(0x3b9)] - this[_0x220aec(0x108)]) * eased;

  // Debug visual
  if (debug_pos === 1) {
    this["tailDbg"][_0x220aec(0x202)]({
      x: this[_0x220aec(0x28c)],
      y: this[_0x220aec(0x405)],
      r: eased,
      s: elapsedTime,
      ns: updateNodes2_span,
    });
  }

  // Limitar historial
  if (this[_0x220aec(0x191)][_0x220aec(0x439)] > 1000) {
    this[_0x220aec(0x191)][_0x220aec(0x365)]();
  }
};

//ui
// ─── FORMAT VALUE MASTER ──────────────────────────────────────
function formatValue(value) {
  return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

// ─── DRAW TEXT WITH SPACING ──────────────────────────────────
function drawTextWithSpacing(ctx, text, x, y, letterSpacing) {
  var letters = text.split("");
  var currentX = x;
  letters.forEach(function (letter) {
    ctx.fillText(letter, currentX, y);
    currentX += ctx.measureText(letter).width + letterSpacing;
  });
}

// ─── ROUND RECT ──────────────────────────────────────────────
function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}
// ─── BORDE COLOR DEL JUEGO V.1 PLUS XTS ──────────────────────
(function () {
  let rotationAngle = 0;
  let glowIntensity = 0.8;
  let glowDirection = 1;
  const MAX_LINE_WIDTH = 400;
  const MIN_LINE_WIDTH = 300;
  function createRGBGamerGradient(ctx, x1, y1, x2, y2) {
    const gradient = ctx.createLinearGradient(x1, y1, x2, y2);
    gradient.addColorStop(0.0, "#00ffff");
    gradient.addColorStop(0.25, "#ff00ff");
    gradient.addColorStop(0.5, "#00ff88");
    gradient.addColorStop(0.75, "#0069ff");
    gradient.addColorStop(1.0, "#00ffff");
    return gradient;
  }
  function drawGlowBorder(ctx, left, top, right, bottom, scale) {
    const centerX = (left + right) / 2;
    const centerY = (top + bottom) / 2;
    const maxRadius = Math.max(right - left, bottom - top) / 2;
    const cosA = Math.cos(rotationAngle);
    const sinA = Math.sin(rotationAngle);
    const offset = sinA * 0.5;
    const x1 = centerX + maxRadius * cosA + offset;
    const y1 = centerY + maxRadius * sinA + offset;
    const x2 = centerX - maxRadius * cosA - offset;
    const y2 = centerY - maxRadius * sinA - offset;
    const gradient = createRGBGamerGradient(ctx, x1, y1, x2, y2);
    const lineWidth = Math.max(
      Math.min(70 / scale, MAX_LINE_WIDTH),
      MIN_LINE_WIDTH,
    );
    ctx.lineJoin = "round";
    ctx.lineCap = "round";
    // 1. Glow RGB (sin blur filter ni shadowBlur)
    ctx.globalAlpha = 0.4;
    ctx.lineWidth = lineWidth * 1.4;
    ctx.strokeStyle = gradient;
    ctx.beginPath();
    ctx.rect(left, top, right - left, bottom - top);
    ctx.stroke();
    // 2. Borde principal
    ctx.globalAlpha = 1;
    ctx.lineWidth = lineWidth;
    ctx.strokeStyle = gradient;
    ctx.beginPath();
    ctx.rect(left, top, right - left, bottom - top);
    ctx.stroke();
    // 3. Reflejo blanco interior
    ctx.globalAlpha = 0.07;
    ctx.lineWidth = lineWidth * 0.5;
    ctx.strokeStyle = "#ffffff";
    ctx.stroke();
  }
  window.drawBorder = function () {
    if (renderMode === RENDERMODE_CTX) {
      drawGlowBorder(
        ctx,
        leftPos,
        topPos,
        rightPos,
        bottomPos,
        cameraManager.scale,
      );
    } else if (renderMode === RENDERMODE_GL) {
      prog_background.draw();
    }
    glowIntensity += 0.005 * glowDirection;
    if (glowIntensity >= 0.7 || glowIntensity <= 0.4) glowDirection *= -1;
    rotationAngle += 0.002;
  };
})();
// ─── BORDE COLOR DEL JUEGO V.1 PLUS XTS ──────────────────────

// Dibujar tiempo de sala y propietario del récord con fondo degradado visible
window.drawTimerAndRecord = function (y, fontSize, padding) {
  try {
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

let top1msg = "";
let masatotal = "";

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
    masatotal = "skor ffa: 0";
    return null;
  }

  const totalMasa = jugadores.reduce((sum, id) => sum + masaPorJugador[id], 0);
  masatotal = `skor ffa: ${formatValue(totalMasa)}`;

  jugadores.sort((a, b) => masaPorJugador[b] - masaPorJugador[a]);
  const [topID] = jugadores;
  const topScore = masaPorJugador[topID];

  const topCell = celdasPorJugador[topID].reduce((a, b) =>
    (parseFloat(a.getScore()) || 0) > (parseFloat(b.getScore()) || 0) ? a : b,
  );

  const nombre = topCell.name || "Sin nombre";
  const cantidadPartes = celdasPorJugador[topID].length;

  top1msg = `Player: ${nombre}  |  Skor: ${formatValue(
    topScore,
  )}  |  Partes: ${cantidadPartes}`;
  celdasPorJugador[topID].forEach((c) => (c.isTop = true));

  return {
    pID: topID,
    name: nombre,
    score: topScore,
    partes: cantidadPartes,
    topCell,
  };
}

function initCheckboxStorage(checkboxId, storageKey) {
  const checkbox = document.getElementById(checkboxId);
  if (!checkbox) return;

  const savedValue = localStorage.getItem(storageKey);
  if (savedValue !== null) {
    checkbox.checked = savedValue === "true";
  }

  checkbox.addEventListener("change", () => {
    localStorage.setItem(storageKey, checkbox.checked);
  });
}

initCheckboxStorage("mostrar-top-1", "Mostrartop1");
initCheckboxStorage("mostrar-skor-sala", "mostrarTotalSala");

const TP_KEY = "Mostrartop1";
const LS_KEY = "mostrarTotalSala";

var topMessage8 = "";

// dibujar los top messages

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
      const fontsize = 15;
      obtenerJugadorConMasMasa();
      const showTotal = localStorage.getItem(LS_KEY) === "true";
      const showTop1 = localStorage.getItem(TP_KEY) === "true";
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
      if (showTop1 && top1msg.trim()) {
        baseMsgs.push({
          text: top1msg,
          colorFunc: (ctx, x, y, width) => {
            // Naranja dorado dinámico
            const t = Date.now() * 0.005;
            const h = 35 + Math.sin(t) * 10; // Oscila entre naranja y dorado
            const s = 100;
            const l = 60 + Math.cos(t * 0.7) * 15; // Oscilación de brillo
            return `hsl(${h}, ${s}%, ${l}%)`;
          },
          position: "top",
        });
      }

      if (showTotal && masatotal.trim()) {
        baseMsgs.push({
          text: masatotal,
          colorFunc: (ctx, x, y, width) => {
            // Rojo magenta neón dinámico
            const t = Date.now() * 0.004;
            const h = 330 + Math.sin(t) * 15; // Magenta - Fucsia
            const s = 100;
            const l = 60 + Math.cos(t * 0.8) * 15;
            return `hsl(${h}, ${s}%, ${l}%)`;
          },
          position: "top",
        });
      }

      if (autoplayxts) {
        baseMsgs.push({
          text: "Respawn Activado",
          colorFunc: (ctx, x, y, width) => {
            const l = 60 + Math.sin(Date.now() * 0.003) * 20;
            return `hsl(180, 100%, ${l}%)`; // Azul eléctrico
          },
          position: "top",
        });
      }

      if (makroxts) {
        baseMsgs.push({
          text: "Macro activado",
          colorFunc: (ctx, x, y, width) => {
            const l = 60 + Math.sin(Date.now() * 0.003) * 20;
            return `hsl(300, 100%, ${l}%)`; // Rosa violeta
          },
          position: "top",
        });
      }

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

// ─── GRADIENTES PARA HUD ─────────────────────────────────────
function getSilverGradient(ctx, x3, y3, width) {
  try {
    const t = Date.now() * 0.002;
    const startX = Math.max(0, x3 - 50);
    const endX = Math.min(ctx.canvas.width, x3 + width + 50);
    const g = ctx.createLinearGradient(startX, y3, endX, y3);
    const base = 200 + Math.sin(t) * 20;
    const light = Math.min(255, base + 35);
    const dark = Math.max(150, base - 50);
    g.addColorStop(0, `rgb(${light}, ${light}, ${light})`);
    g.addColorStop(0.5, `rgb(${base},  ${base},  ${base})`);
    g.addColorStop(1, `rgb(${dark},  ${dark},  ${dark})`);
    return g;
  } catch {
    return "#CCC";
  }
}
function getRedGradient(ctx, x3, y3, width) {
  try {
    const t = Date.now() * 0.002;
    const startX = Math.max(0, x3 - 50);
    const endX = Math.min(ctx.canvas.width, x3 + width + 50);
    const gradient = ctx.createLinearGradient(startX, y3, endX, y3);
    const base = 180 + Math.sin(t) * 20;
    const darker = Math.max(120, base - 40);
    const brighter = Math.min(220, base + 20);
    gradient.addColorStop(
      0,
      `rgb(${brighter},  ${Math.floor(brighter * 0.3)},  ${Math.floor(
        brighter * 0.3,
      )})`,
    );
    gradient.addColorStop(
      0.5,
      `rgb(${base},       ${Math.floor(base * 0.2)},     ${Math.floor(
        base * 0.2,
      )})`,
    );
    gradient.addColorStop(
      1,
      `rgb(${darker},     ${Math.floor(darker * 0.1)},   ${Math.floor(
        darker * 0.1,
      )})`,
    );
    return gradient;
  } catch (error) {
    console.error("Error en getRedGradient:", error);
    return "#F88";
  }
}
function getGoldGradient(ctx, x3, y3, width) {
  try {
    const t = Date.now() * 0.002;
    const startX = Math.max(0, x3 - 50);
    const endX = Math.min(ctx.canvas.width, x3 + width + 50);
    const gradient = ctx.createLinearGradient(startX, y3, endX, y3);
    const red = 255;
    const green = Math.max(180, 215 + Math.sin(t) * 30);
    const blue = Math.max(0, 0 + Math.sin(t + Math.PI / 2) * 30);
    gradient.addColorStop(0, `rgb(${red}, ${green}, ${blue})`);
    gradient.addColorStop(
      0.5,
      `rgb(${red}, ${Math.max(150, green - 20)}, ${Math.max(0, blue - 20)})`,
    );
    gradient.addColorStop(
      1,
      `rgb(${red}, ${Math.max(180, green + 10)}, ${Math.max(0, blue + 20)})`,
    );
    return gradient;
  } catch (error) {
    console.error("Error en getGoldGradient:", error);
    return "#FFD700";
  }
}
function getGoodColor() {
  try {
    const t = Date.now() * 0.004;
    const r = Math.floor(50 + Math.sin(t) * 50);
    const g = Math.floor(200 + Math.cos(t * 1.5) * 55);
    const b = Math.floor(50 + Math.sin(t * 1.3) * 50);
    return `rgb(${r},${g},${b})`;
  } catch {
    return "rgb(0, 255, 0)";
  }
}
function getBadColor() {
  try {
    const t = Date.now() * 0.004;
    const r = Math.floor(200 + Math.sin(t) * 55);
    const g = Math.floor(50 + Math.cos(t * 1.5) * 30);
    const b = Math.floor(50 + Math.sin(t * 1.3) * 30);
    return `rgb(${r},${g},${b})`;
  } catch {
    return "rgb(255, 0, 0)";
  }
}

function getGainGradient(ctx, x3, y3, width) {
  try {
    const t = Date.now() * 0.002;
    const startX = Math.max(0, x3 - 50);
    const endX = Math.min(ctx.canvas.width, x3 + width + 50);
    const gradient = ctx.createLinearGradient(startX, y3, endX, y3);
    const r = Math.floor(127 + 128 * Math.sin(t));
    const g = Math.floor(127 + 128 * Math.sin(t + 2));
    const b = Math.floor(127 + 128 * Math.sin(t + 4));
    const color1 = `rgb(${r}, ${g}, ${b})`;
    const color2 = `rgb(${b}, ${r}, ${g})`;
    const color3 = `rgb(${g}, ${b}, ${r})`;
    gradient.addColorStop(0, color1);
    gradient.addColorStop(0.5, color2);
    gradient.addColorStop(1, color3);
    return gradient;
  } catch (err) {
    console.error("Error en getGainGradient:", err);
    return "#f0f";
  }
}

window.drawEnterCloseTime = function (x, y) {
  if (enterCloseTimePacket == null) return;

  var fontSize = 14;
  var text = trans[364] + ": " + secToTime(enterCloseTimePacket.time);

  switch (renderMode) {
    case RENDERMODE_CTX:
      ctx.fillStyle = "#f5f500";
      ctx.font = `bold 14.5px 'Rajdhani', sans-serif`;
      ctx.fillText(text, x, y);
      break;

    case RENDERMODE_GL:
      prog_font.drawUI(
        x,
        y,
        ColorManager.Current_RGB_GL.textColor,
        1,
        fontSize,
        text,
      );
      break;
  }
};

window.drawGoldToPrize = function (x, y) {
  if (goldToPrizeTime > 0) {
    var fontSize = 14;
    var text = trans[328] + " " + secToTime(goldToPrizeTime);
    switch (renderMode) {
      case RENDERMODE_CTX:
        ctx["fillStyle"] = "#f5f500";
        ctx.font = `bold 14.5px 'Rajdhani', sans-serif`;
        ctx.fillText(text, x, y);
        break;
      case RENDERMODE_GL:
        prog_font.drawText(
          x,
          y,
          ColorManager.Current_RGB_GL.GoldToPrize,
          1,
          fontSize,
          text,
        );
        break;
    }
  }
};

function drawAutoBigTime(x, y) {
  // Si no hay tiempo de auto big activo, no dibujar nada
  if (autoBigTime <= 0) {
    return;
  }

  var fontSize = 20;

  // Construir el texto: traducción + tiempo formateado
  // trans[0x149] probablemente contiene algo como "Auto Big:" o "Agrandamiento automático:"
  var text = trans[0x149] + " " + secToTime(autoBigTime);

  // Renderizar según el modo de renderizado
  switch (renderMode) {
    case RENDERMODE_CTX:
      // Modo Canvas 2D
      ctx.fillStyle = "#f5f500"; // Color amarillo
      ctx.font = `bold 14.5px 'Rajdhani', sans-serif`;
      ctx.fillText(text, x, y);
      break;

    case RENDERMODE_GL:
      // Modo WebGL
      prog_font.draw(
        x, // Posición X
        y, // Posición Y
        ColorManager.Current.AutoBig, // Color desde el gestor de colores
        1, // Opacidad (alpha)
        fontSize, // Tamaño de fuente
        text, // Texto a dibujar
      );
      break;
  }
}

// Zona suavizada almacenada fuera de drawSafeZone
window.smoothZone = {
  x: 0,
  y: 0,
  r: 0,
  rInner: 0,
  rOuter: 0,
  x2: 0,
  y2: 0,
  r2: 0,
};

window.drawSafeZone = function () {
  if (!safeZonePacket) return;

  const now = Date.now();
  const t = now * 0.002;
  const pulse = 0.5 + 0.5 * Math.sin(t * 2);
  const lerpFactor = 0.1;

  function lerp(a, b, f) {
    return a + (b - a) * f;
  }

  const target =
    szpVer === 2
      ? {
          x: safeZonePacket.x_cur || safeZonePacket.x,
          y: safeZonePacket.y_cur || safeZonePacket.y,
          r: safeZonePacket.r_cur,
          rInner: safeZonePacket.r_to,
          rOuter: safeZonePacket.r_cur,
          x2: safeZonePacket.x_to,
          y2: safeZonePacket.y_to,
          r2: safeZonePacket.r_to,
        }
      : {
          x: safeZonePacket.x,
          y: safeZonePacket.y,
          r: safeZonePacket.r_cur,
          rInner: safeZonePacket.r_min,
          rOuter: safeZonePacket.r_max,
          x2: safeZonePacket.x,
          y2: safeZonePacket.y,
          r2: safeZonePacket.r_min,
        };

  for (const key in window.smoothZone) {
    window.smoothZone[key] = lerp(
      window.smoothZone[key],
      target[key] || 0,
      lerpFactor,
    );
  }

  const s = window.smoothZone;

  function drawGradientZone(cx, cy, r, rInner, rOuter) {
    // 🎨 Fondo degradado
    ctx.save();
    const gradient = ctx.createLinearGradient(
      leftPos,
      topPos,
      rightPos,
      bottomPos,
    );
    gradient.addColorStop(0, "#ff0055");
    gradient.addColorStop(0.5 + 0.2 * Math.sin(t * 0.5), "#00ffea");
    gradient.addColorStop(1, "#7d00ff");
    ctx.fillStyle = gradient;
    ctx.globalAlpha = 0.5;

    ctx.beginPath();
    ctx.rect(leftPos, topPos, rightPos - leftPos, bottomPos - topPos);
    ctx.closePath();
    ctx.beginPath();
    ctx.rect(leftPos, topPos, rightPos - leftPos, bottomPos - topPos);
    ctx.arc(cx, cy, rOuter, 0, 2 * Math.PI, true);
    ctx.fill("evenodd");
    ctx.restore();

    // 💎 Borde externo
    ctx.save();
    ctx.globalAlpha = 0.9;
    ctx.lineWidth = 50;
    ctx.shadowBlur = 25 + 10 * pulse;
    ctx.shadowColor = "#00f6ff";
    ctx.strokeStyle = "#00f6ff";
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
    ctx.stroke();
    ctx.restore();

    // 🌟 Borde interno con dash
    ctx.save();
    ctx.lineWidth = 20;
    ctx.shadowBlur = 10 + 5 * Math.sin(t);
    ctx.shadowColor = "#39ff14";
    ctx.strokeStyle = `hsl(${(t * 80) % 360}, 100%, 60%)`;
    ctx.setLineDash([80, 80]);
    ctx.beginPath();
    ctx.arc(cx, cy, rInner, 0, 2 * Math.PI);
    ctx.stroke();
    ctx.restore();

    // 🧭 Línea giratoria tipo radar
    ctx.save();
    const angle = t * 1.5;
    const dx = Math.cos(angle) * r * 0.05;
    const dy = Math.sin(angle) * r * 0.05;
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx + dx, cy + dy);
    ctx.lineWidth = 30;
    ctx.globalAlpha = 1;
    ctx.strokeStyle = `hsl(${(t * 80) % 360}, 100%, 60%)`;
    ctx.setLineDash([]);
    ctx.shadowBlur = 0;
    ctx.stroke();
    ctx.restore();

    // ✖️ Cruces internas
    ctx.save();
    ctx.globalAlpha = 0.15;
    ctx.strokeStyle = "#00ffff";
    ctx.lineWidth = 1;
    const d = r * 1.4;
    ctx.beginPath();
    ctx.moveTo(cx - d, cy - d);
    ctx.lineTo(cx + d, cy + d);
    ctx.moveTo(cx + d, cy - d);
    ctx.lineTo(cx - d, cy + d);
    ctx.stroke();
    ctx.restore();
  }

  drawGradientZone(s.x, s.y, s.r, s.rInner, s.rOuter);
};

window.drawEnterPrice = function (_0x34f22d, _0x5853d6) {
  return;
};
// ─── FUNCION IMPORTANTE PARA EL DRAWHUD ──────────────────────
window.drawMoverList = function () {
  for (let mover of textMoverList) {
    mover.checkLife();
    mover.draw();
  }
};

// Variables globales
let dashOffset = 0;
const dashSpeed = 0.5;
const pulseSpeed = 0.003;
const pingPeriod = 2000;
const pingCount = 5;

// Efecto de ping radial
function drawPingEffect(cx, cy) {
  const now = performance.now();
  for (let i = 0; i < pingCount; i++) {
    const phase =
      ((now - i * (pingPeriod / pingCount)) % pingPeriod) / pingPeriod;
    const radius = phase * 50;
    const alpha = 1 - phase;
    if (radius <= 0) continue;
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
    ctx.strokeStyle = `rgba(255,255,255,${alpha * 0.6})`;
    ctx.lineWidth = 1.2;
    ctx.stroke();
    ctx.restore();
  }
}

// Dibuja el minimapa
function drawMap(mapX, mapY, mapWidth, mapHeight) {
  if (demo !== 0) return;

  const rectSize = 8;
  const gridSize = 20;

  dashOffset = (dashOffset + dashSpeed) % (gridSize * 2);
  const t = performance.now();
  const mainPulse = 0.5 + 0.5 * Math.sin(t * pulseSpeed);
  const clanPulse = 0.6 + 0.4 * Math.sin(t * (pulseSpeed * 0.7));
  const hue = (t * 0.05) % 360;

  // 🎨 Fondo base tipo gamer dark RGB plano (sin bordes redondeados)
  ctx.save();
  ctx.fillStyle = "rgba(0, 0, 0, 0.35)";

  ctx.fillRect(mapX, mapY, mapWidth, mapHeight);
  ctx.restore();

  // 🧩 Cuadrícula animada
  ctx.save();
  ctx.strokeStyle = `rgba(255,255,255,0.05)`;
  ctx.lineWidth = 0.6;
  ctx.setLineDash([4, 4]);
  ctx.lineDashOffset = -dashOffset;
  for (let i = 0; i <= mapWidth; i += gridSize) {
    ctx.beginPath();
    ctx.moveTo(mapX + i, mapY);
    ctx.lineTo(mapX + i, mapY + mapHeight);
    ctx.stroke();
  }
  for (let i = 0; i <= mapHeight; i += gridSize) {
    ctx.beginPath();
    ctx.moveTo(mapX, mapY + i);
    ctx.lineTo(mapX + mapWidth, mapY + i);
    ctx.stroke();
  }
  ctx.restore();

  // 🧿 Jugadores del clan y equipo
  function drawPlayers(players, color, pulse) {
    const size = rectSize * 0.8;
    const r = size / 2;
    players.forEach((p) => {
      let x = mapX + (p.x / rightPos) * mapWidth - r;
      let y = mapY + (p.y / bottomPos) * mapHeight - r;
      x = Math.max(mapX, Math.min(x, mapX + mapWidth - size));
      y = Math.max(mapY, Math.min(y, mapY + mapHeight - size));
      ctx.save();
      ctx.globalAlpha = pulse;
      ctx.shadowColor = color;
      ctx.shadowBlur = 8;
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.arc(x + r, y + r, r * 1.2, 0, 2 * Math.PI);
      ctx.fill();
      ctx.restore();
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.arc(x + r, y + r, r, 0, 2 * Math.PI);
      ctx.fill();
    });
  }

  drawPlayers(
    clanMapPlayers,
    ColorManager.Current.Name_SameClanOnMap,
    clanPulse,
  );
  drawPlayers(teamMapPlayers, ColorManager.Current.Name_SameTeamOnMap, 1);

  // 🟢 Jugador principal con glow RGB
  const mainSize = rectSize * 0.8;
  const mr = mainSize / 2;
  let mx = mapX + (cameraManager.translate_x / rightPos) * mapWidth - mr;
  let my = mapY + (cameraManager.translate_y / bottomPos) * mapHeight - mr;
  mx = Math.max(mapX, Math.min(mx, mapX + mapWidth - mainSize));
  my = Math.max(mapY, Math.min(my, mapY + mapHeight - mainSize));

  ctx.save();
  ctx.globalAlpha = 0.3 * mainPulse;
  ctx.shadowColor = `hsl(${hue}, 100%, 70%)`;
  ctx.shadowBlur = 20;
  ctx.fillStyle = "white";
  ctx.beginPath();
  ctx.arc(mx + mr, my + mr, mr * (1 + mainPulse * 0.5), 0, 2 * Math.PI);
  ctx.fill();
  ctx.restore();

  ctx.fillStyle = "white";
  ctx.beginPath();
  ctx.arc(mx + mr, my + mr, mr, 0, 2 * Math.PI);
  ctx.fill();

  // 📡 Ping (clip duro rectangular)
  ctx.save();
  ctx.beginPath();
  ctx.rect(mapX, mapY, mapWidth, mapHeight);
  ctx.clip();
  drawPingEffect(mx + mr, my + mr);
  ctx.restore();

  // 💠 Borde interior visual (más delgado y limpio)
  ctx.save();
  ctx.strokeStyle = `rgba(255, 255, 255, 0.15)`;
  ctx.lineWidth = 1.2;
  ctx.setLineDash([]);
  ctx.strokeRect(mapX + 0.5, mapY + 0.5, mapWidth - 1, mapHeight - 1);
  ctx.restore();

  // 💎 Borde externo con glow RGB dinámico
  ctx.save();
  ctx.strokeStyle = `hsl(${(hue + 180) % 360}, 100%, 60%)`;
  ctx.lineWidth = 2;
  ctx.shadowColor = ctx.strokeStyle;
  ctx.shadowBlur = 8;
  ctx.strokeRect(mapX, mapY, mapWidth, mapHeight);
  ctx.restore();
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

  originalHandleWsMessage(messageBuffer);
};

window.bonusxt = 0;

let fetchInterval = 500;
let maxInterval = 5000;
let retryCount = 0;
const maxRetries = 5;

async function updateBonusFromWeb() {
  const url = `https://agarz.com/es/home/${playerUserId}`;
  try {
    const resp = await fetch(url, { credentials: "include" });

    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    const text = await resp.text();
    const re = /<td[^>]*>\s*Bonus:\s*<\/td>\s*<td[^>]*>\s*([\d.]+)/i;
    const m = text.match(re);
    if (m) {
      bonusxt = m[1];
    } else {
      bonusxt = "0";
    }

    retryCount = 0;
    fetchInterval = 500;
  } catch (err) {
    retryCount++;
    bonusxt = "0";
    if (retryCount <= maxRetries) {
      fetchInterval = Math.min(fetchInterval * 2, maxInterval);
    } else {
      clearInterval(bonusInterval);
    }
  }
}

// Usamos función que se ajusta dinámicamente al intervalo actual
let bonusInterval;
function startBonusLoop() {
  updateBonusFromWeb().finally(() => {
    bonusInterval = setTimeout(startBonusLoop, fetchInterval);
  });
}

// Iniciar loop
startBonusLoop();

var autoplayxts = false;
var makroxts = false;

function hexToRgb(hex) {
  hex = hex.replace("#", "");
  if (hex.length === 3)
    hex = hex
      .split("")
      .map((c) => c + c)
      .join("");
  const bigint = parseInt(hex, 16);
  const r = (bigint >> 16) & 255;
  const g = (bigint >> 8) & 255;
  const b = bigint & 255;
  return `${r},${g},${b}`;
}

window.drawHUD = function (x, y, lineHeight = 27) {
  const fontSize = 14.5;
  const letterSpacing = 0;
  const textFont = `bold ${fontSize}px 'Rajdhani', sans-serif`;
  const whiteColor = "#FFF";
  const greenColor = "#0f0";
  const t = Date.now() / 200;

  const gradients = {
    silver: (xi, yi) => getSilverGradient(ctx, xi, yi, 200),
    gold: (xi, yi) => getGoldGradient(ctx, xi, yi, 200),
    gain: (xi, yi) => getGainGradient(ctx, xi, yi, 200),
    red: (xi, yi) => getRedGradient(ctx, xi, yi, 200),
    green: () => greenColor,
  };

  const playerCount = cellManager.playerCellList?.length ?? 0;
  const masa = formatValue(userScoreCurrent ?? 0);
  const masaMax = formatValue(userScoreMax ?? 0);

  // PING BARS
  {
    const yi = y;
    const label = "RED:";
    ctx.globalAlpha = 1;
    ctx.font = textFont;
    ctx.fillStyle = whiteColor;
    ctx.textBaseline = "alphabetic";
    drawTextWithSpacing(ctx, label, x, yi, letterSpacing);

    const m = ctx.measureText(label);
    const ascent = m.actualBoundingBoxAscent || fontSize;
    const baseX = x + m.width + 12;
    const barCount = 4,
      gap = 2,
      barW = 3;
    const maxH = ascent * 1.2;
    const pingVal = ping_last;
    const active =
      pingVal <= 230 ? 4 : pingVal <= 250 ? 3 : pingVal <= 500 ? 2 : 1;

    ctx.font = `normal ${fontSize - 3}px 'Poppins', sans-serif`;
    ctx.fillText(
      `${pingVal}ms`,
      baseX + (barCount * (barW + gap + 7) - gap) / 2,
      yi - 1,
    );

    for (let i = 0; i < barCount; i++) {
      const h = maxH * ((i + 1) / barCount);
      const xi = baseX + i * (barW + gap);
      const yb = yi + fontSize / 20 - h;
      ctx.globalAlpha = i < active ? 1 : 0.2;
      ctx.fillStyle = i < active ? greenColor : "#444";
      ctx.fillRect(xi, yb, barW, h);
    }
    ctx.globalAlpha = 1;
  }

  // HUD text content
  const lines = [
    [{ text: `USER: ${playerUserId}`, type: "silver" }],
    [
      { text: `GOLD:  ${formatValue(gold)}`, type: "gold" },
      { text: `  |  `, type: "silver" },
      { text: `BONUS:  ${bonusxt}`, type: "gold" },
    ],
    [{ text: `PRIZE: ${formatValue(winPrize)}`, type: "gold" }],
    [
      { text: `MASA: ${masa}`, type: "silver" },
      { text: `  |  `, type: "silver" },
      { text: `MAX: ${masaMax}`, type: "silver" },
    ],
    [{ text: `PARTES: ${playerCount}/${playerMaxCells}`, type: "silver" }],
  ];

  ctx.font = textFont;
  ctx.textBaseline = "middle";

  lines.forEach((segments, i) => {
    let cursorX = x;
    const yi = y + (i + 1) * lineHeight;

    segments.forEach((seg) => {
      ctx.fillStyle =
        seg.color || gradients[seg.type]?.(cursorX, yi) || whiteColor;
      drawTextWithSpacing(ctx, seg.text, cursorX, yi, letterSpacing);
      cursorX += ctx.measureText(seg.text).width + letterSpacing * 4;
    });
  });

  // GOLD DIFF animation
  if (goldDiff !== 0) {
    const yi = y + 2 * lineHeight;
    const baseX = x + 6;
    const prizeW = ctx.measureText(` PRIZE: ${formatValue(winPrize)}`).width;
    const goldX0 = baseX + prizeW;
    const diff = (goldDiff > 0 ? "+" : "") + goldDiff;
    const diffW = ctx.measureText(diff).width;
    const dx =
      goldX0 +
      ctx.measureText(` GOLD:  ${formatValue(gold)}`).width -
      diffW -
      90;

    ctx.font = textFont;
    ctx.textShadow = "2px 2px 4px rgba(0,0,0,0.3)";
    const animGrad =
      goldDiff > 0 ? gradients.gold(dx, yi) : gradients.red(dx, yi);
    ctx.fillStyle = animGrad;
    drawTextWithSpacing(ctx, diff, dx, yi, letterSpacing);

    const angle = -Math.PI / 4 - (Math.random() * Math.PI) / 2;
    const mult = goldDiff > 0 ? 1 : -1;
    const offX = Math.cos(angle) * 100 * mult;
    const offY = Math.sin(angle) * 100 * mult;
    new textMoverx2(
      diff,
      dx,
      yi,
      offX,
      offY,
      2000,
      animGrad,
      goldDiff > 0 ? ColorManager.Current_RGB_GL.Gold : { r: 255, g: 0, b: 0 },
    );

    goldDiff = 0;
  }
};

// ─── TEXT MOVER ANIMATION ───────────────────────────────────
class textMoverx2 {
  constructor(
    text,
    startX,
    startY,
    velocityX,
    velocityY,
    timeOfLife,
    color,
    colorGL,
  ) {
    this.text = text;
    this.xs = startX;
    this.ys = startY;
    this.x = startX;
    this.y = startY;
    this.vx = velocityX;
    this.vy = velocityY;
    this.timeOfLife = timeOfLife;
    this.color = color;
    this.colorGL = colorGL;
    this.startTime = new Date().getTime();
    textMoverList.push(this);
  }
  getAge() {
    return new Date().getTime() - this.startTime;
  }
  checkLife() {
    if (this.getAge() >= this.timeOfLife) {
      const index = textMoverList.indexOf(this);
      if (index > -1) {
        textMoverList.splice(index, 1);
      }
    }
  }
  draw() {
    const age = this.getAge();
    const percentageLife = age / this.timeOfLife;
    const opacity = Math.max(0, 1 - percentageLife);
    const easedProgress = Math.sin((percentageLife * Math.PI) / 2);
    this.x = this.xs + this.vx * easedProgress;
    this.y = this.ys + this.vy * easedProgress;
    const rotationAngle = easedProgress * Math.PI * 0.5;
    const fontSize = 15 + 5 * easedProgress;
    if (age < this.timeOfLife) {
      switch (renderMode) {
        case RENDERMODE_CTX:
          ctx.globalAlpha = opacity;
          ctx.font = `bold ${fontSize}px 'Poppins', sans-serif`;
          ctx.fillStyle = this.color;
          ctx.setTransform(1, 0, 0, 1, this.x, this.y);
          ctx.rotate(rotationAngle);
          ctx.fillText(this.text, 0, 0);
          ctx.setTransform(1, 0, 0, 1, 0, 0);
          break;
        case RENDERMODE_GL:
          prog_font.drawUI(
            this.x,
            this.y,
            this.colorGL,
            opacity,
            fontSize,
            this.text,
          );
          break;
      }
    }
  }
}

// FUNCION DECOLOR DE BLOCK MOUSE

window.drawLockMouse = function () {
  if (!(isLockMouse === 1 && playMode === PLAYMODE_PLAY)) return;

  const t = performance.now();
  const pulse = Math.sin(t * 0.005) * 10 + 10; // más pulso
  const radius = 100 + pulse; // círculo más grande

  // Obtener colores del tema actual
  const colors = ThemeManager.getCurrentColors();

  // Convertir hex a rgba para usar con opacidad
  const mainRgb = hexToRgb(colors.main);
  const secondaryRgb = hexToRgb(colors.secondary);
  const accentRgb = hexToRgb(colors.accent);

  switch (renderMode) {
    case RENDERMODE_CTX:
      ctx.save();
      ctx.globalAlpha = 1;

      // Círculo pulsante mejorado
      const grd = ctx.createRadialGradient(
        lockMouseX,
        lockMouseY,
        0,
        lockMouseX,
        lockMouseY,
        radius,
      );
      grd.addColorStop(0, "#ffffffee");
      grd.addColorStop(0.4, `rgba(${mainRgb}, 0.73)`);
      grd.addColorStop(0.7, `rgba(${secondaryRgb}, 0.67)`);
      grd.addColorStop(1, `rgba(${accentRgb}, 0.33)`);

      ctx.fillStyle = grd;
      ctx.beginPath();
      ctx.arc(lockMouseX, lockMouseY, radius, 0, Math.PI * 2);
      ctx.fill();

      // Centro brillante mejorado
      ctx.shadowColor = colors.main;
      ctx.shadowBlur = 40;
      ctx.fillStyle = "#ffffff";
      ctx.beginPath();
      ctx.arc(lockMouseX, lockMouseY, 8, 0, Math.PI * 2); // más grande
      ctx.fill();

      // Líneas hacia células (más gruesas y visibles)
      ctx.shadowBlur = 0;
      ctx.lineWidth = 10; // más grueso
      ctx.strokeStyle = colors.main;
      ctx.beginPath();
      for (let cell of cellManager.playerCellList) {
        ctx.moveTo(cell.x_draw, cell.y_draw);
        ctx.lineTo(lockMouseX, lockMouseY);
      }
      ctx.stroke();

      ctx.restore();
      break;

    case RENDERMODE_GL:
      return;
  }
};

// ─── FUNCION HABITACION INFO ────────────────────────────────
window.drawRoomInfo = function (offset) {
  if (!options.get("showInfo")) return;

  try {
    let text;
    let textWidth;
    let yOffset = mainCanvas.height - 86 - 200;

    switch (renderMode) {
      case RENDERMODE_CTX:
        ctx.globalAlpha = 0.8;
        ctx.fillStyle = "white";
        ctx.font = "bold 14.5px 'Rajdhani', sans-serif";
        ctx.textTransform = "uppercase";

        yOffset += 27;
        text = "FPS: " + Math.round(fpsManager.fps);
        textWidth = ctx.measureText(text).width;
        ctx.fillText(text, mainCanvas.width - textWidth - offset, yOffset);

        yOffset += 27;
        text = trans[269].toUpperCase() + ": " + playerMaxMass.dotFormat();
        textWidth = ctx.measureText(text).width;
        ctx.fillText(text, mainCanvas.width - textWidth - offset, yOffset);

        yOffset += 27;
        text = trans[273].toUpperCase() + ": " + observerCount;
        textWidth = ctx.measureText(text).width;
        ctx.fillText(text, mainCanvas.width - textWidth - offset, yOffset);

        yOffset += 27;
        text = (
          "RECUENTO: " +
          premiumPlayerCount +
          "/" +
          premiumPlayerMinForBoost
        ).toUpperCase();
        textWidth = ctx.measureText(text).width;
        ctx.fillText(text, mainCanvas.width - textWidth - offset, yOffset);

        break;

      case RENDERMODE_GL:
        return;
    }
  } catch (error) {}
};
// ─── CHAT MANAGER CONFIG ────────────────────────────────────
chatManager.CHAT_FONTSIZE = 14;
chatManager.CHAT_FONT = "bold 14px 'Rajdhani', sans-serif";
chatManager.CHAT_FONT_BOLD = "bold 14px 'Rajdhani', sans-serif";
chatManager.BG_ALPHA = 0.25;
ColorManager.Current.Chat_BG = "rgba(15, 15, 25, 0.4)";
ColorManager.Current.Chat_Default = "#00f0ff";
ColorManager.Current.Chat_Text = "#ffffff";

// ─── COLOR DE FONDO ─────────────────────────────────────────
const colorFondo = "black";
const originalFillRect = CanvasRenderingContext2D.prototype.fillRect;
CanvasRenderingContext2D.prototype.fillRect = function (x, y, ancho, alto) {
  if (
    x === 0 &&
    y === 0 &&
    ancho === this.canvas.width &&
    alto === this.canvas.height
  ) {
    this.fillStyle = colorFondo;
  }
  return originalFillRect.call(this, x, y, ancho, alto);
};

// ─── COLORES DINÁMICOS ──────────────────────────────────────
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

// ─── LEADERBOARD ────────────────────────────────────────────
const prevYMap = {};
const prevScaleMap = {};
function drawLeaderboard() {
  // — 1) Datos base o de replay
  let lbData = leaderBoard;
  if (
    [DRAWMODE_REPLAY_PLAY, DRAWMODE_REPLAY_STOP].includes(cellManager.drawMode)
  ) {
    const rd = cellManager.getReplayItem();
    if (rd && rd.leaderBoard) lbData = rd.leaderBoard;
  }

  // — 2) Constantes
  const fontSize = isMobile ? 12 : 13;
  const lastFontSize = fontSize * 1.3;
  const maxEntries = isMobile ? Math.min(5, lbData.length) : lbData.length;
  const padding = 10;
  const lineSpacing = 1.3;
  const smoothFact = 0.15;
  const baseW = fontSize * 13;
  const panelW = baseW + padding * 2;
  const startX = mainCanvas.width - panelW;
  const startY = isMobile
    ? mainCanvas.width > mainCanvas.height
      ? 0
      : 150
    : 0;
  if (renderMode !== RENDERMODE_CTX) return;

  // — 3) Construir líneas
  const lines = [];
  // seguimos dejando el último ganador con gradiente si quieres
  lines.push({
    text: (lastWinner || "AgarZ").trim(),
    font: lastFontSize,
    gradient: true,
    id: "__winner",
  });
  // ➕ Línea espaciadora visual
  lines.push({
    text: "", // línea vacía
    font: fontSize * 0.8, // más pequeña, solo para dejar espacio
    id: "__spacer",
  });

  for (let i = 0; i < maxEntries; i++) {
    const e = lbData[i];
    if (!e) continue;

    const name = e.name?.trim() || "AgarZ";
    // siempre número + punto + nombre
    const txt = `${i + 1}. ${name}`;

    lines.push({
      text: txt,
      font: fontSize,
      id: e.id,
      targetScale: 1,
      // ¡no gradient! queda undefined → se usará color normal o de jugador
    });
  }

  if (leaderboardIndex >= maxEntries && playMode === PLAYMODE_PLAY) {
    let meName = playerName;
    if (!meName) {
      const meEntry = leaderBoard.find((e) => e.id === playerId);
      meName = meEntry?.name?.trim();
    }
    lines.push({
      text: `${leaderboardIndex + 1}. ${meName}`,
      font: fontSize,
      id: playerId,
      pulse: true,
      targetScale: 1.1,
    });
  }

  const contentH = lines.reduce((h, l) => h + l.font * lineSpacing, 0);
  const panelH = contentH + padding * 2;
  ctx.save();
  ctx.fillStyle = "rgba(0,0,0,0.4)";
  ctx.shadowColor = "rgba(0,0,0,0.6)";
  ctx.shadowBlur = 8;
  roundRect(ctx, startX, startY, panelW, panelH, 8);
  ctx.fill();
  ctx.restore();

  let cursorY = startY + padding;
  for (const line of lines) {
    const targetY = cursorY + line.font;
    const oldY = prevYMap[line.id] ?? targetY;
    const animY = oldY + (targetY - oldY) * smoothFact;
    prevYMap[line.id] = animY;
    const tScale = line.targetScale || 1;
    const oldS = prevScaleMap[line.id] ?? 1;
    const animS = oldS + (tScale - oldS) * smoothFact;
    prevScaleMap[line.id] = animS;
    if (line.pulse) {
      ctx.globalAlpha = 0.6 + 0.4 * Math.sin(Date.now() / 200);
    }

    let fillStyle;
    if (line.gradient) {
      fillStyle = getDynamicColor();
    } else if (line.id === playerId) {
      fillStyle = ColorManager.Current.Leaderboard_Player;
    } else {
      fillStyle = ColorManager.Current.Leaderboard_Default;
      const extraInfo = getLeaderboardExt?.(line.id);
      if (extraInfo) {
        if (extraInfo.sameTeam === 1) {
          fillStyle = ColorManager.Current.Name_SameTeamOnList;
        } else if (extraInfo.sameClan === 1) {
          fillStyle = ColorManager.Current.Name_SameClanOnList;
        }
      }
    }

    // Aquí el ctx.save() abarca también la sombra, para aislarla
    ctx.save();
    ctx.font = `bold ${line.font}px Rajdhani, sans‑serif`;
    ctx.fillStyle = fillStyle;
    if (line.gradient) {
      ctx.shadowColor = getDynamicShadowColor();
      ctx.font = `${line.font}px fantasy, sans‑serif`;
      ctx.shadowBlur = 10;
    } else {
      ctx.shadowColor = "transparent";
      ctx.shadowBlur = 0;
    }

    const textW = ctx.measureText(line.text).width;
    const xCenter = startX + (panelW - textW) / 2;
    ctx.translate(xCenter, animY);
    ctx.scale(animS, animS);
    ctx.fillText(line.text, 0, 0);
    ctx.restore();

    ctx.globalAlpha = 1;
    cursorY += line.font * lineSpacing;
  }
}

// ─── PRINCIPAL LLAMADOR DE TODO ─────────────────────────────

window.drawGameScene = function () {
  var _0x2a30d7 = a0_0x59a8c2;
  mainCanvas[_0x2a30d7(257)] = window[_0x2a30d7(669)];
  mainCanvas[_0x2a30d7(574)] = window[_0x2a30d7(770)];
  webgl[_0x2a30d7(1181)][_0x2a30d7(257)] = window[_0x2a30d7(669)];
  webgl[_0x2a30d7(1181)][_0x2a30d7(574)] = window[_0x2a30d7(770)];
  webgl[_0x2a30d7(515)]();
  drawClear();
  viewArea = cellManager[_0x2a30d7(641)]();
  var _0x7f2a68 = Date[_0x2a30d7(1008)]() - lastSendMouseMove;
  _0x7f2a68 > 50 &&
    cellManager[_0x2a30d7(375)] == DRAWMODE_NORMAL &&
    ((lastSendMouseMove = Date[_0x2a30d7(1008)]()), sendMouseMove());
  timestamp = Date[_0x2a30d7(1008)]();
  cellManager[_0x2a30d7(477)]();
  fpsManager[_0x2a30d7(353)]();
  cellManager.sort();
  cameraManager[_0x2a30d7(1210)]();
  ctx.save();
  ctx[_0x2a30d7(269)](
    mainCanvas[_0x2a30d7(257)] / 2,
    mainCanvas[_0x2a30d7(574)] / 2,
  );
  cameraManager[_0x2a30d7(791)]();
  ctx[_0x2a30d7(740)](
    cameraManager[_0x2a30d7(740)],
    cameraManager[_0x2a30d7(740)],
  );
  ctx[_0x2a30d7(269)](
    -cameraManager[_0x2a30d7(647)],
    -cameraManager[_0x2a30d7(616)],
  );
  drawBorder();
  webgl[_0x2a30d7(420)]();
  cellManager.drawAuto(ctx);
  drawMovePoint();
  drawLockMouse();
  drawSafeZone();
  renderMode == RENDERMODE_CTX && ctx[_0x2a30d7(1205)]();
  if (demo == 1) {
    return;
  }
  microphone[_0x2a30d7(950)](ctx);
  demo == 0 && drawLeaderboard();
  tutorial_zoom[_0x2a30d7(1178)](ctx);
  drawTimerAndRecord(0, 20, 2);
  isMobile
    ? (drawTopMessage(), drawUserId(0, 200))
    : (drawTopMessage(), drawHUD(10, 20));
  isMobile
    ? mainCanvas[_0x2a30d7(257)] > mainCanvas[_0x2a30d7(574)]
      ? (playMode == PLAYMODE_PLAY && drawGoldInfo(0, 90),
        drawAutoBigTime(0, 70),
        drawEnterCloseTime(0, 50))
      : (playMode == PLAYMODE_PLAY && drawGoldToPrize(0, 330),
        drawAutoBigTime(0, 350),
        drawEnterCloseTime(0, 370))
    : (playMode == PLAYMODE_PLAY && drawGoldToPrize(10, 320),
      drawAutoBigTime(10, 340),
      drawEnterCloseTime(10, 345));
  drawMoverList();
  drawAdminInfo(110, 340);
  drawEnterPrice(10, 360);
  isMobile
    ? (drawScore(0, mainCanvas.height - 85, 12), drawRoomInfo(0))
    : drawRoomInfo(10);
  if (isMobile) {
    if (sb.chatShow.isShow) {
      var _0x495aef = $(DIV_CHAT_MOBILE),
        _0x5e8f2f = _0x495aef[_0x32e12f(944)]();
      chatManager[_0x32e12f(912)](0, 105, 0);
    } else {
      chatManager.draw(0, 5, 2);
    }
  } else {
    let mapX = mainCanvas.width - 150 - 10;
    let mapY = mainCanvas.height - 150 - 10;
    drawMap(mapX, mapY, 150, 150);
    chatManager.draw(10, 50, 10);
  }
  if (isMobile) {
    mainCanvas[_0x2a30d7(257)] > mainCanvas.height
      ? (sb[_0x2a30d7(1044)].setPosition(0, 110),
        sb[_0x2a30d7(381)][_0x2a30d7(488)](55, 110),
        sb[_0x2a30d7(438)][_0x2a30d7(488)](110, 110),
        sb[_0x2a30d7(549)][_0x2a30d7(488)](0, 160),
        sb[_0x2a30d7(948)][_0x2a30d7(488)](55, 160),
        sb[_0x2a30d7(952)].setPosition(0, 210),
        sb[_0x2a30d7(313)][_0x2a30d7(488)](55, 210))
      : (sb.mainMenu.setPosition(0, 210),
        sb[_0x2a30d7(381)][_0x2a30d7(488)](55, 210),
        sb[_0x2a30d7(438)].setPosition(110, 210),
        sb[_0x2a30d7(549)][_0x2a30d7(488)](0, 360),
        sb[_0x2a30d7(948)].setPosition(55, 360),
        sb[_0x2a30d7(952)].setPosition(0, 420),
        sb[_0x2a30d7(313)][_0x2a30d7(488)](55, 420));
    if (playMode == PLAYMODE_PLAY) {
      for (var _0x311929 in sb) {
        sb[_0x311929][_0x2a30d7(1178)]();
      }
    } else {
      sb[_0x2a30d7(1044)][_0x2a30d7(1178)]();
      sb.zoomIn.draw();
      sb[_0x2a30d7(438)][_0x2a30d7(1178)]();
      sb[_0x2a30d7(1147)][_0x2a30d7(1178)]();
    }
  }
};

//FUNCIONES NECESARIAS

// === Variables globales ===
var presionandoH = false,
  cPressed = false,
  aPressed = false,
  sPressed = false,
  zPressed = false,
  xPressed = false;
var spaceIntervalId = null,
  isGoldUsing = false,
  pendingMessages = [];

document.addEventListener("keydown", function (e) {
  if (!e.key) return;

  if ($("input:focus").length) return;

  const key = e.key.toLowerCase(); // 🔥 convierte a minúscula

  switch (key) {
    case "h":
      presionandoH ? detenerAutoplay() : iniciarAutoplay();
      break;
    case "escape":
      const dialog = document.getElementById("finalLeaderboardDialog");
      if (dialog) dialog.style.display = "none";
      break;
    case "c":
      if (!isTypingText() && !$(DIV_MAIN_MENU).is(":visible"))
        toggleMacroC(!cPressed);
      break;
    case "g":
      if (!isTypingText() && !$(DIV_MAIN_MENU).is(":visible")) reaparecer();
      break;
    case "f":
      if (!isTypingText() && !$(DIV_MAIN_MENU).is(":visible")) {
        setTimeout(() => doubleSplit(), 100);
      }
      break;
    case "q":
      if (!isTypingText() && !$(DIV_MAIN_MENU).is(":visible")) {
        fireUltraBurst();
      }
      break;
  }
});

// === Eventos de UI ===
$("#gamemode").on("change", function () {
  if (presionandoH) {
    simularDetener();
    setTimeout(iniciarAutoplay, 200);
  }
});

// === Funciones de Autoplay (H) ===
function simularDetener() {
  presionandoH = false;
}
function detenerAutoplay() {
  presionandoH = false;
  autoplayxts = false;
}

function iniciarAutoplay() {
  presionandoH = true;
  autoplayxts = true;
  onClickPlay();
}

// === Funciones de Macro C ===
function toggleMacroC(activate) {
  if (activate) {
    if (cPressed) return;
    cPressed = true;
    if (!aPressed) {
      aPressed = true;
      sendUint8(OPCODE_C2S_USEGOLD_SMALL_ONCE);
    }
    if (!sPressed) {
      sPressed = true;
      sendUint8(OPCODE_C2S_USEGOLD_BIG_ONCE);
    }
    if (!zPressed) {
      zPressed = true;
      sendUint8(OPCODE_C2S_USEGOLD_SMALL_START);
      sendUint8(OPCODE_C2S_USEGOLD_SMALL_START);
    }
    if (!xPressed) {
      xPressed = true;
      sendUint8(OPCODE_C2S_USEGOLD_BIG_START);
    }
    isGoldUsing = true;
    makroxts = true;
  } else {
    if (!cPressed) return;
    cPressed = false;
    aPressed = false;
    sPressed = false;
    if (zPressed) {
      sendUint8(OPCODE_C2S_USEGOLD_SMALL_END);
      zPressed = false;
    }
    if (xPressed) {
      sendUint8(OPCODE_C2S_USEGOLD_BIG_END);
      xPressed = false;
    }
    isGoldUsing = false;
    makroxts = false;
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

function doubleSplit() {
  setTimeout(() => {
    dispatchKey(32);
    setTimeout(() => {
      dispatchKey(32);
    }, 80);
  }, 0);
}

function fireUltraBurst() {
  for (let i = 0; i < 100; i++) {
    setTimeout(() => {
      dispatchKey(32);
    }, i * 5);
  }
}

// === Función de Reaparecer (G) ===
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

// === WebSocket Send Mejorado ===
window.wsSend = function (messageObj) {
  const payload = messageObj.buffer;
  if (!ws)
    return console.error(
      "wsSend falló: instancia de WebSocket no inicializada.",
    );
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
};
window.sendStart = function () {
  if (clientVersion === serverVersion) {
    sendLang();

    const token = localStorage.userToken;
    if (token != null && token.length === 32) {
      // — token válido: enviamos y salimos
      const packet = prepareData(1 + token.length * 2);
      packet.setUint8(0, OPCODE_C2S_SET_TOKEN);
      let offset = 1;
      for (let i = 0; i < token.length; i++) {
        packet.setUint16(offset, token.charCodeAt(i), true);
        offset += 2;
      }
      wsSend(packet);
      return;
    }

    // — sin token, elegimos PLAY o SPECTATE según el estado o la tecla H
    if (presionandoH) {
      // jugador quiere entrar jugando
      playMode = PLAYMODE_PLAY; // ← lo añadimos
      sendUint8(OPCODE_C2S_PLAY_AS_GUEST_REQUEST);
    } else if (playMode === PLAYMODE_SPECTATE) {
      // jugador quiere entrar en modo espectador
      playMode = PLAYMODE_SPECTATE; // ← lo añadimos
      spectatorId = -1;
      spectatorPlayer = null;
      if (isAdminSafe()) {
        sendAdminSpectate();
      } else {
        sendUint8(OPCODE_C2S_SPECTATE_REQUEST);
      }
    } else {
      // caso por defecto: sin token, sin H y no estabas ya en SPECTATE
      playMode = PLAYMODE_PLAY; // ← y aquí también
      sendUint8(OPCODE_C2S_PLAY_AS_GUEST_REQUEST);
    }
  } else if (serverVersion !== 0) {
    const errorMsg = trans[0x10a];
    showGeneralError(errorMsg, `C:${clientVersion} vs S:${serverVersion}`);
  }
};

const css = `
#controlPanel {
    position: fixed;
    bottom: 30px;
    left: 10px;
    padding: 18px;
    display: flex;
    flex-direction: column;
    color: var(--xts-text-light);
    background: var(--xts-card-background);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border-radius: 16px;
    z-index: 1001;
    width: 90%;
    max-width: 170px;
    font-family: 'Poppins', sans-serif;
    overflow: hidden;
    border: var(--xts-border);
    margin-bottom: 550px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3),
                0 0 0 1px rgba(255, 255, 255, 0.05) inset,
                0 0 20px rgba(var(--xts-main-rgb), 0.15);
    transition: opacity 0.4s ease, transform 0.3s ease;
}

#controlPanel.oculto {
    opacity: 0;
    pointer-events: none;
    transform: translateX(-20px);
}


.control-container {
    z-index: 1;
    position: relative;
    display: flex;
    flex-direction: column;
    gap: 14px;
}

/* Título */
.card-title {
    font-size: 18px;
    font-weight: 700;
    margin-bottom: 1rem;
    text-align: center;
    color: var(--xts-main-color);
    text-shadow: 0 0 10px var(--xts-main-color),
                 0 0 20px rgba(var(--xts-main-rgb), 0.4);
    letter-spacing: 1px;
}

/* Slider etiquetas */
.label-xts-pro {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    font-size: 11px;
    text-transform: uppercase;
    color: var(--xts-text-light, #e0e0e0);
    font-weight: 600;
    letter-spacing: 0.5px;
    margin-bottom: 6px;
}

/* Sliders */
.custom-range {
    appearance: none;
    width: 100%;
    height: 4px;
    border-radius: 8px;
    background: linear-gradient(90deg,
                                var(--xts-border-color, #2a2a2a) 0%,
                                var(--xts-border-color, #2a2a2a) 100%);
    transition: all 0.2s ease;
    outline: none;
    cursor: pointer;
    position: relative;
}

.custom-range:hover {
    height: 5px;
}

.custom-range::-webkit-slider-thumb {
    appearance: none;
    width: 16px;
    height: 16px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--xts-main-color) 0%, var(--xts-secondary-color, #00d4ff) 100%);
    border: 2px solid rgba(255, 255, 255, 0.9);
    box-shadow: 0 0 0 3px rgba(var(--xts-main-rgb), 0.2),
                0 2px 8px rgba(0, 0, 0, 0.3),
                0 0 12px rgba(var(--xts-main-rgb), 0.4);
    cursor: pointer;
    transition: all 0.2s ease;
}

.custom-range::-webkit-slider-thumb:hover {
    transform: scale(1.15);
    box-shadow: 0 0 0 4px rgba(var(--xts-main-rgb), 0.3),
                0 3px 12px rgba(0, 0, 0, 0.4),
                0 0 18px rgba(var(--xts-main-rgb), 0.6);
}

.custom-range::-webkit-slider-thumb:active {
    transform: scale(1.05);
}

.custom-range::-moz-range-thumb {
    width: 16px;
    height: 16px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--xts-main-color) 0%, var(--xts-secondary-color, #00d4ff) 100%);
    border: 2px solid rgba(255, 255, 255, 0.9);
    box-shadow: 0 0 0 3px rgba(var(--xts-main-rgb), 0.2),
                0 2px 8px rgba(0, 0, 0, 0.3),
                0 0 12px rgba(var(--xts-main-rgb), 0.4);
    cursor: pointer;
    transition: all 0.2s ease;
}

.custom-range::-moz-range-thumb:hover {
    transform: scale(1.15);
    box-shadow: 0 0 0 4px rgba(var(--xts-main-rgb), 0.3),
                0 3px 12px rgba(0, 0, 0, 0.4),
                0 0 18px rgba(var(--xts-main-rgb), 0.6);
}

/* Contenedor botones */
.d-flex {
    display: flex;
    gap: 8px;
    justify-content: center;
    margin-top: 4px;
}

/* Botones base */
.chat-mode-button {
    background: var(--xts-card-background);
    border: 1px solid var(--xts-border-color, rgba(255, 255, 255, 0.1));
    color: var(--xts-text-light, #e0e0e0);
    padding: 10px;
    border-radius: 10px;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    font-size: 14px;
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2),
                0 0 0 1px rgba(255, 255, 255, 0.03) inset;
    backdrop-filter: blur(8px);
    -webkit-backdrop-filter: blur(8px);
}

.chat-mode-button:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3),
                0 0 0 1px rgba(255, 255, 255, 0.05) inset,
                0 0 16px rgba(var(--xts-main-rgb), 0.3);
    border-color: var(--xts-main-color);
}

.chat-mode-button:active {
    transform: translateY(0);
}

/* Activo Team */
#teamButton.active {
    background: linear-gradient(135deg, #ffea00 0%, #ffd700 100%);
    color: #000;
    border-color: #ffea00;
    box-shadow: 0 4px 16px rgba(255, 234, 0, 0.4),
                0 0 20px rgba(255, 234, 0, 0.3),
                0 0 0 1px rgba(255, 255, 255, 0.2) inset;
    font-weight: 600;
}

#teamButton.active:hover {
    box-shadow: 0 6px 20px rgba(255, 234, 0, 0.5),
                0 0 25px rgba(255, 234, 0, 0.4);
}

/* Activo Clan */
#clanButton.active {
    background: linear-gradient(135deg, #00e676 0%, #00c853 100%);
    color: #000;
    border-color: #00e676;
    box-shadow: 0 4px 16px rgba(0, 230, 118, 0.4),
                0 0 20px rgba(0, 230, 118, 0.3),
                0 0 0 1px rgba(255, 255, 255, 0.2) inset;
    font-weight: 600;
}

#clanButton.active:hover {
    box-shadow: 0 6px 20px rgba(0, 230, 118, 0.5),
                0 0 25px rgba(0, 230, 118, 0.4);
}

/* Select Me hover */
#selectMeButton:hover {
    background: linear-gradient(135deg, #f00 0%, #c00 100%);
    color: #fff;
    border-color: #f00;
    box-shadow: 0 4px 16px rgba(255, 0, 0, 0.4),
                0 0 20px rgba(255, 0, 0, 0.3);
}

/* Badge */
.badge {
    font-size: 10px;
    font-weight: 600;
    padding: 4px 8px;
    border-radius: 6px;
    user-select: none;
    background: linear-gradient(135deg, var(--xts-main-color) 0%, var(--xts-secondary-color, #00d4ff) 100%);
    color: #000;
    box-shadow: 0 0 8px rgba(var(--xts-main-rgb), 0.3),
                0 2px 4px rgba(0, 0, 0, 0.2);
    letter-spacing: 0.3px;
    min-width: 38px;
    text-align: center;
}

`;

const style = document.createElement("style");
style.textContent = css;
document.documentElement.appendChild(style);

const controlPanel = document.createElement("div");
controlPanel.id = "controlPanel";
controlPanel.className = "oculto";
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
  e.style.background = `linear-gradient(90deg, var(--xts-main-color) ${v}%, #333 ${v}%)`;
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
    if (playMode !== PLAYMODE_SPECTATE) return;
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
              if (
                (info?.uid === record_uid || info?.userId === record_uid) &&
                record_uid !== 0
              ) {
                ctx.drawImage(
                  crownImage,
                  this.x_draw - this.size_draw * 0.5,
                  this.y_draw - this.size_draw * 2,
                  this.size_draw,
                  this.size_draw,
                );
              }
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

              if (
                (info?.uid === record_uid || info?.userId === record_uid) &&
                record_uid !== 0
              ) {
                ctx.drawImage(
                  crownImage,
                  this.x_draw - this.size_draw * 0.5,
                  this.y_draw - this.size_draw * 2,
                  this.size_draw,
                  this.size_draw,
                );
              }
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

    if (controlPanelVisible) {
      controlPanel.classList.remove("oculto");
    } else {
      controlPanel.classList.add("oculto");
    }
  } catch (error) {}
}

document.addEventListener("keydown", function (event) {
  try {
    if (
      (event.key === "O" || event.key === "o") &&
      document.activeElement.tagName !== "INPUT" &&
      document.activeElement.tagName !== "TEXTAREA"
    )
      setTimeout(toggleDrawOptions, 0);
  } catch (error) {
    console.error("Error handling keydown event: ", error);
  }
});

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

        // 2.5. Verificar si es compañero de equipo (teammate)
        const esTeammate =
          enemigo.pID && getLeaderboardExt?.(enemigo.pID)?.sameTeam === 1;

        // 3. Calcular distancia enemigo → virus
        const dx = virus.x_draw - enemigo.x_draw;
        const dy = virus.y_draw - enemigo.y_draw;
        const distVirusEnemigo = Math.hypot(dx, dy);

        // 4. Radio de amenaza: teammates pueden estar MUY cerca, enemigos más lejos
        const radioAmenaza = esTeammate
          ? 10 + enemigoSize * 0.005
          : 80 + enemigoSize * 0.02;

        // 5. Verificar si enemigo está cerca del virus
        if (distVirusEnemigo < radioAmenaza) {
          console.warn(
            `[AUTO-VIRUS] ❌ ${esTeammate ? "TEAM" : "Virus"}: ${
              esTeammate ? "compañero" : "enemigo"
            } (${enemigoSize.toFixed(0)}) a ${distVirusEnemigo.toFixed(
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

          // Radio de seguridad: teammates MUY cerca permitido, enemigos más lejos
          const radioSeguridad = esTeammate
            ? 100 + enemigoSize * 0.01 // Teammates: 100-240px (MUY cerca)
            : 1200 + enemigoSize * 0.08; // Enemigos: 1200-2284px

          if (distAMi < radioSeguridad) {
            console.warn(
              `[AUTO-VIRUS] ❌ ${esTeammate ? "TEAM" : "TU"}: ${
                esTeammate ? "compañero" : "enemigo"
              } (${enemigoSize.toFixed(0)}) a ${distAMi.toFixed(
                0,
              )}px de TI (seguridad=${radioSeguridad.toFixed(0)})`,
            );
            esAmenazado = true;
            break;
          }
        }

        if (esAmenazado) break;
      }
      if (esAmenazado) break;
    }

    if (esAmenazado) continue;
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

      // Verificación unificada del grupo
      if (!grupo || !Array.isArray(grupo) || grupo.length === 0) {
        topMessage8 = "Auto-bot activado (sin virus)";
        sendUint8(OPCODE_C2S_EMITFOOD_STOP);
        simulateKeyRelease(" ");
        isLockMouse = 0;
        return;
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
          return; // Continuar en la siguiente iteración sin detener el bot
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
        return; // Continuar en la siguiente iteración
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
