extends Control

@onready var code_edit: CodeEdit = $CodeEdit
@onready var check_button: Button = $Button
@onready var console_log: RichTextLabel = $RichTextLabel
@onready var task_list: ItemList = $Panel/ItemList
@onready var bg_color: ColorRect = $ColorRect

func _ready() -> void:
	# Conecta o sinal do botão e configura as missões
	check_button.pressed.connect(_on_verificar_pressed)
	_setup_tasks()
	
	# Preenche o CodeEdit com a classe base para poupar tempo
	code_edit.text = "public class Variaveis {\n    public static void main(String[] args) {\n        \n        // Declare suas variáveis aqui\n        \n    }\n}"

func _setup_tasks() -> void:
	task_list.clear()
	# Adiciona os itens baseados na imagem de algoritmo do VisuAlg/Portugol
	task_list.add_item("1. Letra -> char (Ex: 'A')")
	task_list.add_item("2. Texto -> String (Ex: \"João\")")
	task_list.add_item("3. Inteiro -> int (Ex: 10)")
	task_list.add_item("4. Real -> double ou float (Ex: 11.50)")
	task_list.add_item("5. Lógico -> boolean (Ex: true)")
	task_list.add_item("6. Imprimir -> System.out.println")

func _on_verificar_pressed() -> void:
	var code: String = code_edit.text
	console_log.clear()
	
	# Remove espaços e quebras de linha para facilitar a validação exata
	var code_limpo: String = code.replace(" ", "").replace("\n", "").replace("\t", "")
	
	# Regras de validação de declaração
	var has_char = code.contains("char ") and code.contains("'")
	var has_string = code.contains("String ") and code.contains("\"")
	var has_int = code.contains("int ")
	var has_double = code.contains("double ") or code.contains("float ")
	var has_boolean = code.contains("boolean ") and (code.contains("true") or code.contains("false"))
	
	# Regras de validação de impressão (exige todos os prints específicos)
	var has_print_letra = code_limpo.contains("System.out.println(letra);") or code_limpo.contains("System.out.print(letra);")
	var has_print_texto = code_limpo.contains("System.out.println(texto);") or code_limpo.contains("System.out.print(texto);")
	var has_print_inteiro = code_limpo.contains("System.out.println(inteiro);") or code_limpo.contains("System.out.print(inteiro);")
	var has_print_real = code_limpo.contains("System.out.println(real);") or code_limpo.contains("System.out.print(real);")
	var has_print_logico = code_limpo.contains("System.out.println(logico);") or code_limpo.contains("System.out.print(logico);")
	
	# A tarefa 6 só é concluída se TODOS os prints existirem
	var has_print = has_print_letra and has_print_texto and has_print_inteiro and has_print_real and has_print_logico
	
	# Atualiza visualmente o ItemList
	_update_task_color(0, has_char)
	_update_task_color(1, has_string)
	_update_task_color(2, has_int)
	_update_task_color(3, has_double)
	_update_task_color(4, has_boolean)
	_update_task_color(5, has_print)
	
	# Verifica se todas as missões foram cumpridas
	if has_char and has_string and has_int and has_double and has_boolean and has_print:
		console_log.append_text("[color=green]Excelente! Você declarou e imprimiu todas as variáveis corretamente.[/color]")
		bg_color.color = Color(0.1, 0.3, 0.1) 
	else:
		console_log.append_text("[color=orange]Alguns tipos de dados ou impressões estão faltando. Verifique se você usou System.out.println() para cada variável.[/color]")
		bg_color.color = Color(0.2, 0.2, 0.2)


# Função auxiliar para pintar o texto do ItemList
func _update_task_color(index: int, is_done: bool) -> void:
	if is_done:
		task_list.set_item_custom_fg_color(index, Color.GREEN)
	else:
		task_list.set_item_custom_fg_color(index, Color.WHITE)
