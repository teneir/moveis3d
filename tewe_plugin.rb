require 'sketchup.rb'
#require 'moveis3d/cutlistutl.rb'
#require 'moveis3d/layout.rb'
#require 'moveis3d/boards.rb'
#require 'moveis3d/parts.rb'
#require 'moveis3d/drivers.rb'
#require 'moveis3d/gui.rb'
#require 'moveis3d/display.rb'
#require 'moveis3d/renderers.rb'
#require 'moveis3d/list_components.rb'
require 'moveis3d/rotacionar.rb'
# require 'moveis3d/ruby/tewe_plano_de_corte.rb'

module Moveis3D
  module Plugin
    def self.show_dialog
      @dialog = UI::HtmlDialog.new(
        dialog_title: "Moveis3D",
        scrollable: true,
        resizable: true,
        width: 400,
        height: 700,
        resizable: true,
        style: UI::HtmlDialog::STYLE_UTILITY
        )

      @dialog.set_url("https://moveis3d.com/plugin_moveis3d/html/tewe_index.php")


      # Define o tamanho do diálogo (largura x altura)
      dialog_width = 500
      dialog_height = 1200
      @dialog.set_size(dialog_width, dialog_height)

      # Define a posição do diálogo (valores fixos ou relativos)
      left = 0  # Distância da borda esquerda da tela
      top = -30   # Distância da borda superior da tela
      @dialog.set_position(left, top)

      # Adiciona o callback para fechar o diálogo
      @dialog.add_action_callback("close_dialog") do |_context|
        @dialog.close
      end

      # Add callback for Plano de Corte button
      @dialog.add_action_callback("open_plano_corte") do |_context|
        # Close the current dialog
        @dialog.close
        # Show the component list dialog
        Moveis3D.show_component_list
      end
      # Adiciona o callback para abrir a ferramenta EditComponent
      @dialog.add_action_callback("open_edit_component") do |_context|
        @dialog.close
        EditComponentDialog.show_dialog
      end

      # Adiciona o callback para importar o arquivo SKP
      @dialog.add_action_callback("importSkpFromUrl") do |_, skp_url, file_name, file_extension|
        puts "URL recebida: #{skp_url}"
        puts "Extensão recebida: #{file_extension}"
        puts "Extensão recebida: #{file_name}"
        begin
          model = Sketchup.active_model  # Obtém o modelo ativo
          materials = model.materials    # Acessa a coleção de materiais do modelo

          if file_extension.downcase == 'skp'
            # Faz o download do arquivo .skp da URL recebida
            filename = File.join(Sketchup.temp_dir, file_name)
            download_file(skp_url, filename)

            # Inicia uma operação para manter o processo "desfazer" limpo
            model.start_operation("Importar Entidades SKP", true)

            # Importa o arquivo como uma definição temporária de componente
            temp_def = model.definitions.load(filename)

            if temp_def
              # Copia todas as entidades da definição temporária para o modelo atual
              temp_def.entities.each do |entity|
                # Adiciona cada entidade diretamente ao modelo ativo
                if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
                  model.entities.add_instance(entity.definition, entity.transformation)
                elsif entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge)
                  model.entities.add_face(entity.vertices.map(&:position)) if entity.is_a?(Sketchup::Face)
                end
              end

              # Remove a definição temporária para limpar o modelo
              model.definitions.remove(temp_def)

              model.commit_operation  # Finaliza a operação
              UI.messagebox("Arquivo SKP importado com sucesso no modelo atual!")
            else
              UI.messagebox("Erro ao carregar o arquivo SKP como definição temporária.")
            end

            puts "arquivo: #{filename}"
            @dialog.close

          elsif file_extension.downcase == 'jpg'
            # Baixar a imagem associada ao arquivo SKM, usando a URL
            image_filename = File.join(Sketchup.temp_dir, file_name)
            download_file(skp_url, image_filename)

            # Cria um material novo e o adiciona à coleção de materiais
            material_name = file_name.sub(File.extname(file_name), '')  # Remove a extensão para nome do material
            material = materials.add(material_name)
            # Aplica a textura ao material usando o arquivo de imagem
            material.texture = image_filename

            # Agora definimos o tamanho da textura em metros
            texture = material.texture
            if texture
              # Define a largura e altura da textura em metros (não milímetros)
              # texture.width = 1830 / 1000.0  # 1830mm convertido para metros
              # texture.height = 2750 / 1000.0  # 2750mm convertido para metros

              UI.messagebox("Textura carregada com sucesso e com tamanho ajustado!")
            else
              UI.messagebox("Erro ao carregar a textura.")
            end

            @dialog.close

          elsif file_extension.downcase == 'skm' # Nova lógica para SKM
            # 1. Baixa o arquivo SKM para a pasta temporária
            temp_filename = File.join(Sketchup.temp_dir, file_name)
            download_file(skp_url, temp_filename)

            # 2. Obtém o caminho da pasta de materiais
            materials_dir = Sketchup.find_support_file("Materials")

            # 3. Verifica se a pasta "moveis3d" existe dentro da pasta de materiais
            moveis3d_dir = File.join(materials_dir, "moveis3d")
            unless File.directory?(moveis3d_dir)
              # Se não existir, cria a pasta
              Dir.mkdir(moveis3d_dir)
              puts "Pasta 'moveis3d' criada em: #{moveis3d_dir}"
            end

            # 4. Constrói o caminho de destino na pasta "moveis3d"
            dest_filename = File.join(moveis3d_dir, file_name)

            # 5. Copia o arquivo da pasta temporária para a pasta "moveis3d"
            begin
              FileUtils.cp(temp_filename, dest_filename) # Usa FileUtils para copiar
              UI.messagebox("Material SKM salvo na pasta 'moveis3d' com sucesso!")

              # 6. Carrega o material salvo no SketchUp
              material_name = File.basename(file_name, ".skm") # Remove a extensão para o nome do material
              material = model.materials.load(dest_filename) # Carrega o material

              if material
                UI.messagebox("Material '#{material_name}' carregado com sucesso!")
              else
                UI.messagebox("Erro ao carregar o material '#{material_name}'.")
              end

            rescue => e
              UI.messagebox("Erro ao copiar ou carregar o material SKM: #{e.message}")
            end
          end
        end
      end


      @dialog.show
    end

    # Método para fazer o download do arquivo SKP
    def self.download_file(url, destination)
      require 'open-uri'
      URI.open(url) do |file|
        File.open(destination, "wb") do |output|
          output.write(file.read)
        end
      end
    end
  end
end
