extends Control

@onready var code_edit: CodeEdit = $CodeEdit
@onready var terminal_output: RichTextLabel = $RichTextLabel
@onready var terminal_input: LineEdit = $LineEdit
@onready var btn_executar: Button = $Button

var codigo_salvo: String = ""

func _ready() -> void:
	btn_executar.pressed.connect(_on_executar_pressed)
	terminal_input.text_submitted.connect(_on_entrada_terminal_enviada)
	terminal_input.editable = false # Trava o terminal até o programa rodar

func _on_executar_pressed() -> void:
	codigo_salvo = code_edit.text
	terminal_output.clear()
	
	# Verifica se o jogador usou Scanner para pedir entrada
	if "Scanner" in codigo_salvo or "nextInt()" in codigo_salvo:
		imprimir_no_terminal("Digite a sua idade no campo abaixo e pressione Enter:")
		terminal_input.editable = true
		terminal_input.grab_focus()
	else:
		imprimir_no_terminal("[ERRO] Seu código precisa usar 'Scanner' para ler a idade.")

func _on_entrada_terminal_enviada(texto_digitado: String) -> void:
	if not texto_digitado.is_valid_int():
		imprimir_no_terminal("[ERRO] Por favor, digite um número válido!")
		terminal_input.clear()
		return
	
	var idade = texto_digitado.to_int()
	
	# Exibe o que o usuário digitou no terminal
	imprimir_no_terminal("> " + texto_digitado)
	terminal_input.clear()
	terminal_input.editable = false
	
	# Simula a execução do código escrito pelo jogador
	avaliar_execucao_java(codigo_salvo, idade)

func avaliar_execucao_java(codigo: String, idade: int) -> void:
	# Limpa espaços, quebras de linha e tabulações para padronizar o texto
	var codigo_limpo = codigo.replace(" ", "").replace("\n", "").replace("\t", "").replace("\r", "")
	
	# Compara com a condição também sem espaços ("idade>=18")
	var tem_if = "if(idade>=18)" in codigo_limpo
	var tem_else = "else" in codigo_limpo
	
	if tem_if and tem_else:
		if idade >= 18:
			imprimir_no_terminal("Saída: Você é maior de idade.")
		else:
			imprimir_no_terminal("Saída: Você é menor de idade.")
	else:
		imprimir_no_terminal("[ERRO DE SINTAXE] Verifique se a estrutura 'if (idade >= 18)' e 'else' estão corretas.")

func imprimir_no_terminal(texto: String) -> void:
	terminal_output.append_text(texto + "\n")
