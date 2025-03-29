module Moveis3D
    class EditComponentDialog
        HIDDEN_TITLEBAR_POSITION = [0, -30]

        def self.show_dialog
            if defined?(@instance) && @instance&.dialog&.visible?
                @instance.dialog.bring_to_front
            else
                @instance = new
                @instance.show
            end
        end

        attr_reader :dialog

        def initialize
            create_dialog unless @dialog
            setup_callbacks
            setup_selection_observer
        end

        def show
            return unless @dialog

            if @dialog.visible?
                @dialog.set_position(*HIDDEN_TITLEBAR_POSITION)
            else
                @dialog.show
                @dialog.set_position(*HIDDEN_TITLEBAR_POSITION)
            end

            @dialog.bring_to_front
            focus_name_field
            send_component_info
        end

        private

        def create_dialog
            @dialog = UI::HtmlDialog.new(
                dialog_title: "Editar Componente",
                preferences_key: "editar_componente",
                width: 400,
                height: 700,
                resizable: true,
                style: UI::HtmlDialog::STYLE_UTILITY
            )
            @dialog.set_file(File.join(__dir__, "edit_component.html"))
        end

        def setup_callbacks
            @dialog.add_action_callback("get_component_info") { |_| send_component_info }
            @dialog.add_action_callback("update_component") { |_, data| update_component_data(data) }
            @dialog.add_action_callback("close_dialog") { |_| cleanup_and_close }
        end

        def setup_selection_observer
            @selection_observer = SelectionObserver.new(self)
            Sketchup.active_model.selection.add_observer(@selection_observer)
        end

        def cleanup_and_close
            if @selection_observer
                Sketchup.active_model.selection.remove_observer(@selection_observer)
                @selection_observer = nil
            end
            @dialog.close if @dialog
            self.class.remove_instance
        end

        def self.remove_instance
            @instance = nil
        end

        def focus_name_field
        @dialog.execute_script(<<~JS)
        setTimeout(() => {
        window.focus();
        document.getElementById('component-name').focus();
        document.getElementById('component-name').select();
        }, 100);
        JS
        end

        def update_dialog
            if !valid_component_selected?
                @dialog.execute_script("showMessage('Selecione um componente para editar')")
            elsif has_nested_components?
                @dialog.execute_script("showMessage('O componente selecionado possui componentes aninhados')")
            else
                send_component_info
            end
        end

        def valid_component_selected?
            selection = Sketchup.active_model.selection.first
            selection.is_a?(Sketchup::ComponentInstance)
        end

        def has_nested_components?
            selection = Sketchup.active_model.selection.first
            return false unless selection.is_a?(Sketchup::ComponentInstance)
            !selection.definition.entities.grep(Sketchup::ComponentInstance).empty?
        end

        def send_component_info
            return unless valid_component_selected?

            selection = Sketchup.active_model.selection.first
            definition = selection.definition

            begin
                thumbnail_path = generate_thumbnail(selection)

                data = {
                    name: definition.name,
                    description: definition.description,
                    face_materials: get_component_face_materials(selection),
                    selected_material: get_component_face_materials(selection).first || "",
                    available_materials: get_model_materials,
                    image: thumbnail_path ? "file://#{thumbnail_path}?#{Time.now.to_i}" : "",
                    timestamp: Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"),
                    user: Sketchup.active_model.get_attribute('UserInfo', 'user_name', 'Unknown')
                }

                @dialog.execute_script("loadComponentData(#{data.to_json})")
            rescue => e
                puts "Erro ao enviar informações do componente: #{e.message}"
                puts e.backtrace
                @dialog.execute_script("showMessage('Erro ao carregar informações do componente')")
            end
        end

        def get_component_face_materials(component)
            faces = component.definition.entities.grep(Sketchup::Face)
            faces.sort_by { |face| -face.area }[0..1].map do |face|
                material = face.material || face.back_material
                material&.display_name
            end.compact.uniq
        end

        def get_model_materials
            Sketchup.active_model.materials.map(&:display_name)
        end

        def update_component_data(data)
            return unless valid_component_selected?

            model = Sketchup.active_model
            model.start_operation('Atualizar Componente', true)

            begin
                selection = model.selection.first
                definition = selection.definition

                update_component_properties(definition, data)
                apply_material_to_faces(selection, data["material"]) if data["material"]

                model.commit_operation
                cleanup_and_close
            rescue => e
                model.abort_operation
                puts "Erro ao atualizar componente: #{e.message}"
                puts e.backtrace
                @dialog.execute_script("showMessage('Erro ao atualizar componente')")
            end
        end

        def update_component_properties(definition, data)
            definition.name = data["name"] if data["name"] && data["name"] != definition.name
            definition.description = data["description"] if data["description"]
        end

        def apply_material_to_faces(component, material_name)
            model = Sketchup.active_model
            material = model.materials[material_name] || model.materials.add(material_name)

            component.definition.entities.grep(Sketchup::Face)
            .sort_by { |face| -face.area }[0..1]
            .each { |face| face.material = material }
        end

        def generate_thumbnail(component)
            return unless component.is_a?(Sketchup::ComponentInstance)

            model = Sketchup.active_model
            view = model.active_view
            camera = view.camera
            return unless view && camera

            temp_path = File.join(Dir.tmpdir, "component_thumbnail_#{Time.now.to_i}.png")

            model.start_operation('Gerar Thumbnail', true)
            begin
                original_state = save_view_state(view, camera)
                hidden_entities = hide_other_entities(model, component)
                setup_camera_for_component(camera, component)

                view.refresh
                sleep(0.1)
                view.write_image(temp_path, 600, 600, false)

                temp_path
            rescue => e
                puts "Erro ao gerar thumbnail: #{e.message}"
                puts e.backtrace
                nil
            ensure
                restore_view_state(original_state, view, camera)
                show_hidden_entities(hidden_entities)
                model.commit_operation
            end
        end

        def save_view_state(view, camera)
            {
                camera_eye: camera.eye.clone,
                camera_target: camera.target.clone,
                camera_up: camera.up.clone,
                perspective: camera.perspective?,
                fov: camera.perspective? ? camera.fov : nil
            }
        end

        def hide_other_entities(model, component)
            hidden_entities = model.active_entities.select do |e|
                e.is_a?(Sketchup::ComponentInstance) && e != component && !e.hidden?
            end
            hidden_entities.each { |e| e.hidden = true }
            hidden_entities
        end

        def setup_camera_for_component(camera, component)
            bounds = component.bounds
            center = bounds.center
            size = bounds.diagonal
            distance = size * 1.2

            eye = Geom::Point3d.new(
                center.x + distance,
                center.y + distance,
                center.z + distance
            )

            camera.set(eye, center, Z_AXIS)
            camera.perspective = true
            camera.fov = 30.0
        end

        def restore_view_state(state, view, camera)
            return unless state
            camera.set(state[:camera_eye], state[:camera_target], state[:camera_up])
            camera.perspective = state[:perspective]
            camera.fov = state[:fov] if state[:perspective] && state[:fov]
            view.refresh
        end

        def show_hidden_entities(entities)
            entities&.each { |e| e.hidden = false }
        end

        class SelectionObserver
            def initialize(edit_dialog)
                @edit_dialog = edit_dialog
            end

            def onSelectionBulkChange(_selection)
                @edit_dialog.update_dialog
            end
        end
    end
end
