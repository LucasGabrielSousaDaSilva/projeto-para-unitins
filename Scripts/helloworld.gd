extends Control

@onready var code_edit: CodeEdit = $CodeEdit
@onready var button: Button = $Button
@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	button.pressed.connect(_on_enviar_pressed)

func _on_enviar_pressed() -> void:
	var codigo: String = code_edit.text
	rich_text_label.clear()
	
	# Checa os elementos essenciais da estrutura Java e a saída esperada
	var possui_classe: bool = codigo.contains("public class")
	var possui_main: bool = codigo.contains("public static void main")
	var possui_print: bool = codigo.contains('System.out.println("Olá Mundo!!");') or codigo.contains('System.out.println("Hello, World!");') or codigo.contains('System.out.println("Hello World");')
	
	if possui_classe and possui_main and possui_print:
		rich_text_label.append_text("[color=green]Compilado com sucesso![/color]\n\n")
		rich_text_label.append_text("Saída:\n[b]Olá Mundo!![/b]")
	else:
		rich_text_label.append_text("[color=red]Erro de Compilação / Resposta Incorreta![/color]\n\n")
		rich_text_label.append_text("Verifique se declarou a classe, o método main e o comando System.out.println com a frase correta.")
