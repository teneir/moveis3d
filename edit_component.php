<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Editar Componente</title>
    <style>
        /* Estilos gerais */
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #ccccc9;
            color: #333;
            margin: 0;
            padding: 0;
            background-image: url('');
            background-size: cover;
            background-position: center;
            background-repeat: no-repeat;
        }

        /* Container principal */
        .container {
            padding: 20px;
        }

        /* Estilo dos campos de entrada */
        input, select, textarea {
            width: calc(100% - 30px);
            margin-bottom: 15px;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
            color: #555;
            display: inline-block;
        }

        /* Estilo dos botões */
        .button-group {
            display: flex;
            gap: 10px;
            margin-top: 15px;
        }

        button {
            flex: 1;
            padding: 10px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            transition: background-color 0.3s ease;
        }

        .save-button {
            background-color: #0074D9;
            color: white;
        }

        .save-button:hover {
            background-color: #0056A4;
        }

        .close-button {
            background-color: #d9534f;
            color: white;
        }

        .close-button:hover {
            background-color: #b52b27;
        }

        /* Estilo dos labels */
        label {
            display: block;
            font-weight: bold;
            margin-bottom: 5px;
            color: #555;
        }

        /* Estilo da imagem */
        img {
            width: 100%;
            max-height: 300px;
            object-fit: contain;
            border: 1px solid #ddd;
            border-radius: 4px;
            margin-bottom: 20px;
            background-color: white;
        }

        /* Ícones de informação */
        .info-icon {
            display: inline-block;
            margin-left: 10px;
            cursor: pointer;
            color: #0074D9;
            font-size: 14px;
            position: relative;
            background-color: #fff;
            border: 1px solid #0074D9;
            border-radius: 50%;
            width: 20px;
            height: 20px;
            text-align: center;
            line-height: 20px;
        }

        /* Ajuste para alinhar ícones ao lado dos campos */
        .input-group {
            display: flex;
            align-items: center;
        }

        .input-group input,
        .input-group textarea,
        .input-group select {
            flex: 1;
            margin-right: 10px;
        }

        /* Estilo da div de mensagem */
        .message-box {
            display: none;
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background-color: #fff;
            border: 2px solid #0074D9;
            border-radius: 4px;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            z-index: 1000;
            max-width: 80%;
            text-align: center;
        }

        .message-box.visible {
            display: block;
        }

        /* Novo estilo para mensagens de erro */
        .error-message {
            background-color: #ffebee;
            color: #c62828;
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
            border-left: 4px solid #c62828;
        }

        /* Estilo para campos inválidos */
        .invalid {
            border-color: #c62828 !important;
        }

        /* Estilo para o status */
        .status-bar {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            padding: 5px 10px;
            background-color: #f5f5f5;
            border-top: 1px solid #ddd;
            font-size: 12px;
            color: #666;
            display: flex;
            justify-content: space-between;
        }
    </style>
</head>
<body>
    <div class="container">
        <img id="component-image" src="" alt="Imagem do Componente">

        <form id="component-form">
            <!-- Campo Nome -->
            <label for="component-name">Nome</label>
            <div class="input-group">
                <input type="text" id="component-name" required>
                <span class="info-icon" data-message="Defina o nome da peça do móvel.">ℹ️</span>
            </div>

            <!-- Campo Informação Adicional -->
            <label for="component-description">Informação Adicional sobre a Peça</label>
            <div class="input-group">
                <textarea id="component-description"></textarea>
                <span class="info-icon" data-message="Informação adicional com orientação sobre o corte para enviar à marcenaria.">ℹ️</span>
            </div>

            <!-- Campo Material -->
            <label for="component-material">Material</label>
            <div class="input-group">
                <select id="component-material" required></select>
                <span class="info-icon" data-message="Escolha a cor da chapa de MDF.">ℹ️</span>
            </div>

            <!-- Grupo de botões -->
            <div class="button-group">
                <button type="submit" class="save-button">Salvar</button>
                <button type="button" class="close-button">Fechar</button>
            </div>
        </form>
    </div>

    <!-- Div de mensagem -->
    <div id="message-box" class="message-box"></div>

    <!-- Barra de status -->
    <div class="status-bar">
        <span id="timestamp"></span>
        <span id="username"></span>
    </div>

    <script>
        // Controle de contexto (iframe ou não)
        const isInIframe = window.parent !== window;
        let currentData = null;

        // Função para carregar dados do componente
        function loadComponentData(data) {
            console.log("Recebendo dados do componente:", data);
            currentData = data;

            // Preenche os campos do formulário
            document.getElementById("component-name").value = data.name || "";
            document.getElementById("component-description").value = data.description || "";
            
            // Carrega a imagem se existir
            if (data.image) {
                document.getElementById("component-image").src = data.image;
            }

            // Preenche o seletor de materiais
            const materialSelect = document.getElementById("component-material");
            materialSelect.innerHTML = '';
            
            if (data.available_materials && data.available_materials.length > 0) {
                data.available_materials.forEach(material => {
                    const option = document.createElement("option");
                    option.value = material;
                    option.textContent = material;
                    if (material === data.selected_material) {
                        option.selected = true;
                    }
                    materialSelect.appendChild(option);
                });
            }

            // Atualiza informações de status
            document.getElementById("timestamp").textContent = `Última atualização: ${data.timestamp || 'N/A'}`;
            document.getElementById("username").textContent = `Usuário: ${data.user || 'Desconhecido'}`;

            // Foca no campo de nome
            focusNameField();
        }

        // Função para focar no campo de nome
        function focusNameField() {
            const nameField = document.getElementById("component-name");
            nameField.focus();
            nameField.select();
        }

        // Validação do formulário
        function validateForm() {
            const form = document.getElementById("component-form");
            const requiredFields = form.querySelectorAll("[required]");
            let isValid = true;

            requiredFields.forEach(field => {
                field.classList.remove("invalid");
                if (!field.value.trim()) {
                    field.classList.add("invalid");
                    isValid = false;
                }
            });

            if (!isValid) {
                showMessage("Preencha todos os campos obrigatórios", true);
            }

            return isValid;
        }

        // Função para enviar comandos para o Ruby
        function sendToRuby(command, data = {}) {
            if (isInIframe) {
                // Se estiver em iframe, usa postMessage
                window.parent.postMessage({
                    action: 'ruby_command',
                    command: command,
                    data: data
                }, '*');
            } else {
                // Se não estiver em iframe, usa o método tradicional
                window.location = `skp:${command}@${JSON.stringify(data)}`;
            }
        }

        // Função para salvar alterações
        function saveChanges(event) {
            if (event) event.preventDefault();
            
            if (!validateForm()) return;

            const data = {
                name: document.getElementById("component-name").value.trim(),
                description: document.getElementById("component-description").value.trim(),
                material: document.getElementById("component-material").value
            };

            sendToRuby("update_component", data);
        }

        // Função para fechar o diálogo
        function closeDialog() {
            sendToRuby("close_dialog");
        }

        // Exibe mensagens para o usuário
        function showMessage(message, isError = false) {
            const messageBox = document.getElementById('message-box');
            messageBox.textContent = message;
            messageBox.className = `message-box ${isError ? 'error-message' : ''}`;
            messageBox.classList.add('visible');

            setTimeout(() => {
                messageBox.classList.remove('visible');
            }, 5000);
        }

        // Inicialização quando o DOM estiver pronto
        document.addEventListener('DOMContentLoaded', () => {
            // Configura os eventos do formulário
            const form = document.getElementById('component-form');
            form.addEventListener('submit', saveChanges);
            
            // Configura o botão de fechar
            document.querySelector('.close-button').addEventListener('click', closeDialog);

            // Configura os ícones de informação
            document.querySelectorAll('.info-icon').forEach(icon => {
                icon.addEventListener('click', function() {
                    showMessage(this.dataset.message);
                });
            });

            // Configura atalhos de teclado
            document.addEventListener('keydown', (event) => {
                if (event.key === 'Enter' && (event.ctrlKey || !isInIframe)) {
                    saveChanges(event);
                } else if (event.key === 'Escape') {
                    closeDialog();
                }
            });

            // Se estiver em iframe, notifica que está pronto
            if (isInIframe) {
                window.parent.postMessage({ action: 'iframe_ready' }, '*');
            } else {
                // Se não estiver em iframe, solicita os dados do componente
                setTimeout(() => {
                    sendToRuby("get_component_info");
                }, 100);
            }
        });

        // Listener para mensagens do pai (quando em iframe)
        window.addEventListener('message', (event) => {
            if (event.data.action === 'component_data') {
                loadComponentData(event.data.data);
            } else if (event.data.action === 'show_message') {
                showMessage(event.data.message, event.data.isError);
            }
        });
    </script>
</body>
</html>
