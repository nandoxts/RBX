<?php

/**
 * Divisor de Archivos de Audio
 * Sube archivos de audio largos y los divide en segmentos de 5 minutos
 */

// Configuración
$upload_dir = __DIR__ . '/audio_uploads/';
$output_dir = __DIR__ . '/audio_output/';
$segment_duration = 300; // 5 minutos en segundos

// Detectar FFmpeg
function findFFmpeg()
{
    // Intentar comando directo primero
    exec('ffmpeg -version 2>&1', $output, $return);
    if ($return === 0) {
        return 'ffmpeg';
    }

    // Buscar en ubicaciones comunes de Windows
    $possible_paths = [
        'C:\\ffmpeg\\bin\\ffmpeg.exe',
        'C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe',
        'C:\\Program Files (x86)\\ffmpeg\\bin\\ffmpeg.exe',
    ];

    // Buscar en AppData del usuario actual
    $username = getenv('USERNAME') ?: getenv('USER');
    if ($username) {
        $possible_paths[] = "C:\\Users\\{$username}\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\\ffmpeg-8.0.1-full_build\\bin\\ffmpeg.exe";
        $possible_paths[] = "C:\\Users\\{$username}\\AppData\\Local\\Microsoft\\WinGet\\Links\\ffmpeg.exe";
    }

    foreach ($possible_paths as $path) {
        if (file_exists($path)) {
            return $path;
        }
    }

    return null;
}

$ffmpeg_path = findFFmpeg();

// Crear directorios si no existen
if (!file_exists($upload_dir)) mkdir($upload_dir, 0777, true);
if (!file_exists($output_dir)) mkdir($output_dir, 0777, true);

$message = '';
$error = '';
$output_files = [];

// Procesar subida de archivo
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['audio_file'])) {
    $file = $_FILES['audio_file'];

    // Validar archivo
    if ($file['error'] === UPLOAD_ERR_OK) {
        $allowed_types = ['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav', 'audio/ogg', 'audio/mp4', 'audio/x-m4a'];
        $file_ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

        if (in_array($file['type'], $allowed_types) || in_array($file_ext, ['mp3', 'wav', 'ogg', 'm4a', 'aac'])) {
            // Obtener nombre base personalizado del usuario
            $custom_name = isset($_POST['base_name']) && !empty($_POST['base_name'])
                ? $_POST['base_name']
                : 'Audio';

            // Sanitizar nombre base personalizado
            $safe_basename = preg_replace('/[^a-zA-Z0-9_-]/', '_', $custom_name);
            $safe_basename = preg_replace('/_+/', '_', $safe_basename);
            $safe_basename = substr($safe_basename, 0, 30);
            $safe_basename = trim($safe_basename, '_');

            // Nombre temporal para subida
            $temp_filename = uniqid() . '_temp.' . $file_ext;
            $filepath = $upload_dir . $temp_filename;

            if (move_uploaded_file($file['tmp_name'], $filepath)) {
                // Verificar que FFmpeg esté disponible
                if (!$ffmpeg_path) {
                    $error = "FFmpeg no está instalado o no se pudo encontrar. Por favor, reinicia tu terminal o verifica la instalación.";
                    unlink($filepath);
                } else {
                    // Usar nombre base personalizado para archivos de salida
                    $output_pattern = $output_dir . $safe_basename . '_%03d.' . $file_ext;

                    // Normalizar rutas para Windows
                    $filepath = str_replace('/', '\\', $filepath);
                    $output_pattern = str_replace('/', '\\', $output_pattern);

                    // Comando FFmpeg para dividir el audio sin procesar (copia directa)
                    // -map 0:a = solo audio
                    // -c copy = copiar sin recodificar (mantiene calidad 100% original)
                    $cmd = "\"{$ffmpeg_path}\" -i \"{$filepath}\" -f segment -segment_time {$segment_duration} -map 0:a -c copy \"{$output_pattern}\" 2>&1";

                    exec($cmd, $output, $return_var);

                    if ($return_var === 0) {
                        // Listar archivos generados
                        $pattern = $safe_basename . '_*.' . $file_ext;
                        $output_files = glob($output_dir . $pattern);

                        $message = "¡Audio dividido exitosamente! Se generaron " . count($output_files) . " segmentos de 5 minutos.<br>"
                            . "✨ <strong>Calidad:</strong> 100% original (sin pérdida)";

                        // Eliminar archivo original después de procesar
                        unlink($filepath);
                    } else {
                        $error = "Error al procesar el audio.<br><strong>Comando:</strong> " . htmlspecialchars($cmd) . "<br><strong>Salida:</strong><pre style='text-align:left;max-height:200px;overflow:auto;'>" . htmlspecialchars(implode("\n", $output)) . "</pre>";
                        // No eliminar el archivo para poder debuggear si es necesario
                    }
                }
            } else {
                $error = "Error al subir el archivo.";
            }
        } else {
            $error = "Tipo de archivo no permitido. Solo archivos de audio (MP3, WAV, OGG, M4A, AAC).";
        }
    } else {
        $error = "Error en la subida del archivo: " . $file['error'];
    }
}

// Listar archivos procesados anteriormente
$all_output_files = glob($output_dir . '*');
?>
<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Divisor de Audio - 5 Minutos</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }

        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 40px;
            max-width: 800px;
            width: 100%;
        }

        h1 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 2em;
            text-align: center;
        }

        .subtitle {
            color: #666;
            text-align: center;
            margin-bottom: 30px;
            font-size: 0.9em;
        }

        .upload-area {
            border: 3px dashed #667eea;
            border-radius: 15px;
            padding: 40px;
            text-align: center;
            margin-bottom: 30px;
            transition: all 0.3s ease;
            cursor: pointer;
            background: #f8f9ff;
        }

        .upload-area:hover {
            border-color: #764ba2;
            background: #f0f1ff;
        }

        .upload-area.dragover {
            background: #e8e9ff;
            border-color: #764ba2;
        }

        input[type="file"] {
            display: none;
        }

        .file-label {
            display: block;
            color: #667eea;
            font-size: 1.2em;
            margin-bottom: 10px;
            font-weight: 600;
        }

        .file-info {
            color: #999;
            font-size: 0.9em;
        }

        .btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 15px 40px;
            border-radius: 50px;
            font-size: 1.1em;
            cursor: pointer;
            transition: transform 0.2s;
            width: 100%;
            font-weight: 600;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.4);
        }

        .btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .message {
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-weight: 500;
        }

        .success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }

        .error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }

        .output-files {
            margin-top: 30px;
        }

        .output-files h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.3em;
        }

        .file-list {
            list-style: none;
        }

        .file-item {
            background: #f8f9ff;
            padding: 12px 15px;
            margin-bottom: 10px;
            border-radius: 8px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .file-item:hover {
            background: #e8e9ff;
        }

        .file-name {
            color: #333;
            font-weight: 500;
        }

        .download-btn {
            background: #667eea;
            color: white;
            padding: 8px 20px;
            border-radius: 20px;
            text-decoration: none;
            font-size: 0.9em;
            transition: background 0.3s;
        }

        .download-btn:hover {
            background: #764ba2;
        }

        .icon {
            font-size: 3em;
            margin-bottom: 15px;
        }

        .selected-file {
            color: #667eea;
            font-weight: 600;
            margin: 15px 0;
        }

        .progress {
            display: none;
            margin-top: 20px;
        }

        .progress-bar {
            width: 100%;
            height: 30px;
            background: #f0f0f0;
            border-radius: 15px;
            overflow: hidden;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            width: 0%;
            transition: width 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
        }

        .ffmpeg-status {
            padding: 10px 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 0.85em;
            text-align: center;
        }

        .ffmpeg-ok {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }

        .ffmpeg-warning {
            background: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }
    </style>
</head>

<body>
    <div class="container">
        <h1>🎵 Divisor de Audio</h1>
        <p class="subtitle">Sube tu archivo de audio y divídelo automáticamente en segmentos de 5 minutos</p>

        <?php if ($ffmpeg_path): ?>
            <div class="ffmpeg-status ffmpeg-ok">
                ✓ FFmpeg detectado correctamente
            </div>
        <?php else: ?>
            <div class="ffmpeg-status ffmpeg-warning">
                ⚠ FFmpeg no detectado. Reinicia tu terminal/servidor web o instala FFmpeg.
            </div>
        <?php endif; ?>

        <?php if ($message): ?>
            <div class="message success"><?php echo $message; ?></div>
        <?php endif; ?>

        <?php if ($error): ?>
            <div class="message error"><?php echo $error; ?></div>
        <?php endif; ?>

        <form method="POST" enctype="multipart/form-data" id="uploadForm">
            <div class="name-input-wrapper" style="margin-bottom: 20px;">
                <label for="base_name" style="display: block; color: #667eea; font-weight: 600; margin-bottom: 8px; font-size: 1.05em;">📝 Nombre base para los archivos:</label>
                <input
                    type="text"
                    name="base_name"
                    id="base_name"
                    placeholder="Ej: DEMBOW, MIX_2025, REGGAETON_PARTY..."
                    value="<?php echo isset($_POST['base_name']) ? htmlspecialchars($_POST['base_name']) : ''; ?>"
                    style="width: 100%; padding: 12px 15px; border: 2px solid #667eea; border-radius: 10px; font-size: 1em; font-weight: 500; color: #333; outline: none; transition: all 0.3s;"
                    onfocus="this.style.borderColor='#764ba2'; this.style.boxShadow='0 0 0 3px rgba(102, 126, 234, 0.1)'"
                    onblur="this.style.borderColor='#667eea'; this.style.boxShadow='none'">
                <p style="color: #999; font-size: 0.85em; margin-top: 5px;">Los archivos se numerarán: <strong id="previewName">DEMBOW_001.mp3, DEMBOW_002.mp3...</strong></p>
            </div>

            <div class="upload-area" id="uploadArea" onclick="document.getElementById('audio_file').click()">
                <div class="icon">🎧</div>
                <label class="file-label">Haz clic o arrastra tu archivo de audio aquí</label>
                <p class="file-info">Formatos soportados: MP3, WAV, OGG, M4A, AAC</p>
                <p class="file-info">Duración recomendada: 1-2 horas</p>
                <p class="file-info">✨ Calidad 100% original preservada</p>
                <input type="file" name="audio_file" id="audio_file" accept="audio/*" required>
                <div class="selected-file" id="selectedFile"></div>
            </div>

            <button type="submit" class="btn" id="submitBtn">
                ✂️ Subir y Dividir Audio
            </button>

            <div class="progress" id="progress">
                <div class="progress-bar">
                    <div class="progress-fill" id="progressFill">Procesando...</div>
                </div>
            </div>
        </form>

        <?php if (count($output_files) > 0): ?>
            <div class="output-files">
                <h2>📁 Archivos Generados</h2>
                <ul class="file-list">
                    <?php foreach ($output_files as $file): ?>
                        <li class="file-item">
                            <span class="file-name"><?php echo basename($file); ?></span>
                            <a href="audio_output/<?php echo basename($file); ?>" class="download-btn" download>⬇ Descargar</a>
                        </li>
                    <?php endforeach; ?>
                </ul>
            </div>
        <?php endif; ?>

        <?php if (count($all_output_files) > count($output_files) && count($output_files) == 0): ?>
            <div class="output-files">
                <h2>📁 Archivos Procesados Anteriormente</h2>
                <ul class="file-list">
                    <?php foreach (array_slice($all_output_files, 0, 20) as $file): ?>
                        <li class="file-item">
                            <span class="file-name"><?php echo basename($file); ?></span>
                            <a href="audio_output/<?php echo basename($file); ?>" class="download-btn" download>⬇ Descargar</a>
                        </li>
                    <?php endforeach; ?>
                </ul>
                <?php if (count($all_output_files) > 20): ?>
                    <p style="text-align: center; color: #999; margin-top: 10px;">
                        Y <?php echo count($all_output_files) - 20; ?> archivos más...
                    </p>
                <?php endif; ?>
            </div>
        <?php endif; ?>
    </div>

    <script>
        // Manejo de archivo seleccionado
        const fileInput = document.getElementById('audio_file');
        const selectedFileDiv = document.getElementById('selectedFile');
        const uploadArea = document.getElementById('uploadArea');
        const uploadForm = document.getElementById('uploadForm');
        const submitBtn = document.getElementById('submitBtn');
        const progress = document.getElementById('progress');
        const baseNameInput = document.getElementById('base_name');
        const previewName = document.getElementById('previewName');

        // Actualizar preview del nombre
        baseNameInput.addEventListener('input', function() {
            let name = this.value.trim() || 'Audio';
            name = name.replace(/[^a-zA-Z0-9_-]/g, '_').replace(/_+/g, '_');
            const ext = fileInput.files.length > 0 ? fileInput.files[0].name.split('.').pop() : 'mp3';
            previewName.textContent = name + '_001.' + ext + ', ' + name + '_002.' + ext + '...';
        });

        fileInput.addEventListener('change', function(e) {
            if (this.files.length > 0) {
                const file = this.files[0];
                const sizeMB = (file.size / (1024 * 1024)).toFixed(2);
                selectedFileDiv.textContent = `✓ ${file.name} (${sizeMB} MB)`;
            }
        });

        // Drag and drop
        uploadArea.addEventListener('dragover', function(e) {
            e.preventDefault();
            this.classList.add('dragover');
        });

        uploadArea.addEventListener('dragleave', function(e) {
            e.preventDefault();
            this.classList.remove('dragover');
        });

        uploadArea.addEventListener('drop', function(e) {
            e.preventDefault();
            this.classList.remove('dragover');

            const files = e.dataTransfer.files;
            if (files.length > 0) {
                fileInput.files = files;
                const file = files[0];
                const sizeMB = (file.size / (1024 * 1024)).toFixed(2);
                selectedFileDiv.textContent = `✓ ${file.name} (${sizeMB} MB)`;
            }
        });

        // Mostrar progreso al enviar
        uploadForm.addEventListener('submit', function() {
            submitBtn.disabled = true;
            submitBtn.textContent = '⏳ Procesando audio...';
            progress.style.display = 'block';

            // Simular progreso (ya que el proceso real es en el servidor)
            let width = 0;
            const interval = setInterval(function() {
                if (width >= 90) {
                    clearInterval(interval);
                } else {
                    width += 10;
                    document.getElementById('progressFill').style.width = width + '%';
                }
            }, 1000);
        });
    </script>
</body>

</html>