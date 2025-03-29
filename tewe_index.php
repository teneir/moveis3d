<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Moveis3D</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }
    #main-content {
      width: 100vw;
      height: 100vh;
      display: flex;
      flex-direction: row;
      background-color: #547d9e;
    }
    iframe {
      flex-grow: 1;
      border: none;
    }
    #sidebar {
      width: 60px;
      background-color: #2c3e50;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding-top: 20px;
    }
    #sidebar ul {
      list-style: none;
      padding: 0;
      margin: 0;
      width: 100%;
    }
    #sidebar li {
      width: 100%;
      text-align: center;
      margin-bottom: 20px;
    }
    #sidebar a {
      color: #ecf0f1;
      text-decoration: none;
      font-size: 24px;
      display: block;
      padding: 10px;
      transition: background-color 0.3s, color 0.3s;
    }
    #sidebar a:hover {
      background-color: #34495e;
      color: #1abc9c;
    }
    #sidebar a.close-button {
      color: #e74c3c;
    }

    #sidebar a.close-button:hover {
      background-color: #34495e;
      color: #ff6b6b;
    }
    #button-container {
      position: absolute;
      top: 10px;
      right: 10px;
    }
    button {
      margin: 5px;
      padding: 10px 15px;
      font-size: 14px;
      cursor: pointer;
      background-color: #3498db;
      color: white;
      border: none;
      border-radius: 5px;
      transition: background-color 0.3s;
    }
    button:hover {
      background-color: #2980b9;
    }
  </style>
</head>
<body>
  <div id="main-content">
    <nav id="sidebar">
      <ul>
        <li>
          <a href="https://moveis3d.com/modelsskp" target="iframe-content" title="Modelos SKP">
            <i class="fas fa-cube"></i>
          </a>
        </li>
        <li>
          <a href="#" id="plano_corte" onclick="openPlanoCorte()" title="Plano de Corte">
            <i class="fas fa-cut"></i>
          </a>
        </li>
        <li>
          <a href="#" id="editar_componente" onclick="openEditComponent()" title="Editar Componente">
            <i class="fas fa-edit"></i>
          </a>
        </li>
        <li>
          <a href="welcome.html" target="iframe-content" title="Início">
            <i class="fas fa-home"></i>
          </a>
        </li>
        <li>
          <a href="#" onclick="closeDialog()" class="close-button" title="Fechar">
            <i class="fas fa-times"></i>
          </a>
        </li>
      </ul>
    </nav>

    <iframe name="iframe-content" src="welcome.php"></iframe>
  </div>

  <script>
    function closeDialog() {
      window.location = 'skp:close_dialog@';
    }

    function openPlanoCorte() {
      window.location = 'skp:open_plano_corte@true';
    }

     function openEditComponent() {
        // Carrega o edit_component.php no iframe
        window.frames['iframe-content'].location.href = 'edit_component.php';
        
        // Inicializa a comunicação com o Ruby
        window.frames['iframe-content'].postMessage({
            action: 'init_edit_component'
        }, '*');
    }
  </script>
  <script>
    // Adicione este listener para mensagens do iframe
    window.addEventListener('message', function(event) {
        const iframe = document.querySelector('iframe[name="iframe-content"]');
        
        if (event.data.action === 'ruby_command' && event.source === iframe.contentWindow) {
            // Encaminha o comando para o Ruby
            window.location = 'skp:' + event.data.command + '@' + JSON.stringify(event.data.data);
        }
        
        if (event.data.action === 'iframe_ready' && event.source === iframe.contentWindow) {
            // Notifica o Ruby que o iframe está pronto
            window.location = 'skp:iframe_message@ready';
        }
    });

    // Função para enviar dados para o iframe
    function sendToIframe(data) {
        const iframe = document.querySelector('iframe[name="iframe-content"]');
        iframe.contentWindow.postMessage({
            action: 'load_component_data',
            data: data
        }, '*');
    }
</script>
</body>
</html>
