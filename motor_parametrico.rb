module Moveis3D
    module MotorParametrico
        # Função que avalia a fórmula de forma robusta e sensível a maiúsculas/minúsculas
        def self.avaliar_regra(regra_str, contexto)
            expressao = regra_str.to_s.strip
            expressao_substituida = expressao.gsub(/PAI\.[\w\s]+/) do |variavel|
                chave_contexto = variavel.strip
                contexto[chave_contexto] || 0
            end
            begin
                return eval(expressao_substituida)
            rescue SyntaxError, StandardError => e
                puts "Erro ao avaliar a expressão '#{expressao_substituida}': #{e.message}"
                return 0
            end
        end

        def self.atualizar_modulo(componente_pai)
            SKETCHUP_CONSOLE.clear
            puts "--- INICIANDO ATUALIZAÇÃO PARAMÉTRICA (MÉTODO ROBUSTO) ---"

            model = componente_pai.model
            model.start_operation('Atualizar Módulo por Regras', true)

            begin
                dict_pai = componente_pai.attribute_dictionary("moveis3d_parametros")
                unless dict_pai
                    UI.messagebox("O componente principal não possui o dicionário 'moveis3d_parametros'.")
                    model.abort_operation
                    return
                end

                contexto = {}
                dict_pai.each_pair do |key, value|
                    contexto["PAI.#{key.strip}"] = value.to_f
                end

                puts "Contexto do Pai: #{contexto.inspect}"
                puts "-----------------------------------------"

                componente_pai.definition.entities.each do |filho|
                    next unless filho.is_a?(Sketchup::ComponentInstance)

                    # PASSO 1: TORNA A INSTÂNCIA DO FILHO ÚNICA
                    # Isso cria uma nova definição para esta peça, isolando-a de outras.
                    filho = filho.make_unique

                    dict_filho = filho.attribute_dictionary("moveis3d_parametros")
                    next unless dict_filho

                    puts "\nAnalisando Filho: '#{filho.definition.name}'"

                    # Agora lemos os bounds da NOVA definição, que está sempre em escala 1:1
                    bounds = filho.definition.bounds

                    # PASSO 2: CALCULA AS NOVAS DIMENSÕES E POSIÇÃO
                    pos_x = dict_filho['posicao_x'] ? avaliar_regra(dict_filho['posicao_x'], contexto).mm : filho.transformation.origin.x
                    pos_y = dict_filho['posicao_y'] ? avaliar_regra(dict_filho['posicao_y'], contexto).mm : filho.transformation.origin.y
                    pos_z = dict_filho['posicao_z'] ? avaliar_regra(dict_filho['posicao_z'], contexto).mm : filho.transformation.origin.z

                    dim_x = dict_filho['Largura_x'] ? avaliar_regra(dict_filho['Largura_x'], contexto).mm : bounds.width
                    dim_y = dict_filho['profundidade_y'] ? avaliar_regra(dict_filho['profundidade_y'], contexto).mm : bounds.depth
                    dim_z = dict_filho['Altura_z'] ? avaliar_regra(dict_filho['Altura_z'], contexto).mm : bounds.height

                    # PASSO 3: CALCULA OS FATORES DE ESCALA A PARTIR DA DEFINIÇÃO ORIGINAL (NÃO ESCALADA)
                    escala_x = (bounds.width > 0) ? (dim_x / bounds.width) : 1
                    escala_y = (bounds.depth > 0) ? (dim_y / bounds.depth) : 1
                    escala_z = (bounds.height > 0) ? (dim_z / bounds.height) : 1

                    puts "  Valores Calculados (mm):"
                    puts "    Posição: [#{pos_x.to_mm.to_s}, #{pos_y.to_mm.to_s}, #{pos_z.to_mm.to_s}]"
                    puts "    Tamanho: [#{dim_x.to_mm.to_s}, #{dim_y.to_mm.to_s}, #{dim_z.to_mm.to_s}]"
                    puts "  Fatores de Escala: [#{escala_x.round(4)}, #{escala_y.round(4)}, #{escala_z.round(4)}]"

                    # PASSO 4: CRIA AS TRANSFORMAÇÕES E AS COMBINA
                    transform_posicao = Geom::Transformation.new([pos_x, pos_y, pos_z])
                    transform_escala = Geom::Transformation.scaling(escala_x, escala_y, escala_z)

                    # A transformação final combina a escala com a posição
                    transform_final = transform_posicao * transform_escala

                    # PASSO 5: APLICA A TRANSFORMAÇÃO ÚNICA E FINAL NA INSTÂNCIA
                    filho.transform!(transform_final)
                end


            rescue => e
                UI.messagebox("Erro ao processar regras: #{e.message}")
            ensure
                model.commit_operation
            end
        end
    end
end
