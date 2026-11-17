extends Control

@onready var code_edit: CodeEdit = $CodeEdit
@onready var button: Button = $Button
@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	button.pressed.connect(_on_enviar_pressed)
	
	# Preenche o CodeEdit com a classe base para poupar tempo
	code_edit.text = "public class HelloWorld {\n\t\n}"

func _on_enviar_pressed() -> void:
	var codigo: String = code_edit.text
	rich_text_label.clear()
	
	# Checa os elementos essenciais da estrutura Java
	var possui_classe: bool = codigo.contains("public class")
	var possui_main: bool = codigo.contains("public static void main")
	
	# Captura dinamicamente o texto dentro de System.out.print("...") ou println("...")
	var regex := RegEx.new()
	regex.compile('System\\.out\\.print(?:ln)?\\s*\\(\\s*"([^"]*)"\\s*\\)\\s*;')
	var resultado_print := regex.search(codigo)
	
	if possui_classe and possui_main and resultado_print != null:
		# Extrai a frase exata que foi atribuída entre as aspas
		var texto_atribuido: String = resultado_print.get_string(1)
		
		# Normaliza o texto para aceitar qualquer variação de "Hello World" / "Olá Mundo"
		var texto_normalizado: String = texto_atribuido.to_lower().replace(",", "").replace("!", "").strip_edges()
		var eh_hello_world: bool = texto_normalizado in ["hello world", "ola mundo", "olá mundo"]
		
		if eh_hello_world:
			rich_text_label.append_text("[color=green]Compilado com sucesso![/color]\n\n")
			rich_text_label.append_text("Saída:\n[b]%s[/b]" % texto_atribuido)
		else:
			# Compilou um Java válido, mostra a saída digitada, mas avisa sobre o objetivo da fase
			rich_text_label.append_text("[color=yellow]Compilado, mas a frase não é a esperada![/color]\n\n")
			rich_text_label.append_text("Saída:\n[b]%s[/b]\n\n" % texto_atribuido)
			rich_text_label.append_text("O desafio pede para exibir \"Hello World!\" ou \"Olá Mundo!\".")
	else:
		rich_text_label.append_text("[color=red]Erro de Compilação / Resposta Incorreta![/color]\n\n")
		rich_text_label.append_text("Verifique se declarou a classe, o método main e o comando System.out.println(\"...\"); com ponto e vírgula.")


func _on_botao_voltar_pressed() -> void:
	GameManager.voltar_laboratorio()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		GameManager.voltar_laboratorio()
