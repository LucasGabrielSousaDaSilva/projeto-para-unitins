extends Control

@onready var code_edit: CodeEdit = $CodeEdit
@onready var check_button: Button = $Button
@onready var console_log: RichTextLabel = $RichTextLabel
@onready var task_list: ItemList = $Panel/ItemList
@onready var bg_color: ColorRect = $ColorRect

# Mapeia exclusivamente as referências propostas na atividade e seus tipos Java
const ESPECIFICACOES_VARIAVEIS: Dictionary = {
	"letra": { "tipos": ["char"], "exemplo": "char letra = 'A';" },
	"texto": { "tipos": ["String"], "exemplo": "String texto = \"João\";" },
	"inteiro": { "tipos": ["int"], "exemplo": "int inteiro = 10;" },
	"real": { "tipos": ["double", "float"], "exemplo": "double real = 11.50;" },
	"logico": { "tipos": ["boolean"], "exemplo": "boolean logico = true;" }
}

func _ready() -> void:
	check_button.pressed.connect(_on_verificar_pressed)
	_setup_tasks()
	
	code_edit.text = "public class Variaveis {\n\tpublic static void main(String[] args) {\n\t\t\n\t\t// Declare suas variáveis aqui\n\t\t\n\t}\n}"

func _setup_tasks() -> void:
	task_list.clear()
	task_list.add_item("1. Letra -> char (Ex: 'A')")
	task_list.add_item("2. Texto -> String (Ex: \"João\")")
	task_list.add_item("3. Inteiro -> int (Ex: 10)")
	task_list.add_item("4. Real -> double ou float (Ex: 11.50)")
	task_list.add_item("5. Lógico -> boolean (Ex: true)")
	task_list.add_item("6. Imprimir -> System.out.println")

func _on_verificar_pressed() -> void:
	var code: String = code_edit.text
	console_log.clear()
	
	for i in range(6):
		_update_task_color(i, false)
	bg_color.color = Color(0.2, 0.2, 0.2)
	
	var resultado: Dictionary = compilar_e_executar_java(code)
	var vars_ok: Dictionary = resultado["variaveis"]
	var prints_ok: Dictionary = resultado["prints_realizados"]
	var erros: Array = resultado["erros"]
	
	var has_char: bool = vars_ok.has("letra")
	var has_string: bool = vars_ok.has("texto")
	var has_int: bool = vars_ok.has("inteiro")
	var has_real: bool = vars_ok.has("real")
	var has_boolean: bool = vars_ok.has("logico")
	
	var has_all_prints: bool = (
		erros.is_empty()
		and prints_ok.has("letra")
		and prints_ok.has("texto")
		and prints_ok.has("inteiro")
		and prints_ok.has("real")
		and prints_ok.has("logico")
	)
	
	_update_task_color(0, has_char)
	_update_task_color(1, has_string)
	_update_task_color(2, has_int)
	_update_task_color(3, has_real)
	_update_task_color(4, has_boolean)
	_update_task_color(5, has_all_prints)
	
	if not erros.is_empty():
		console_log.append_text("[color=red][ERRO DE COMPILAÇÃO][/color]\n")
		for erro in erros:
			console_log.append_text("• " + erro + "\n")
		return
	
	if has_char and has_string and has_int and has_real and has_boolean and has_all_prints:
		bg_color.color = Color(0.1, 0.3, 0.1)
		console_log.append_text("[color=green]Compilado com sucesso! Todas as variáveis foram declaradas e impressas corretamente.[/color]\n\n")
		console_log.append_text("Saída:\n[b]" + resultado["saida_console"] + "[/b]")
	else:
		console_log.append_text("[color=orange]Sintaxe válida até aqui, mas ainda faltam declarações ou comandos System.out.println() para todas as variáveis propostas.[/color]")
		if resultado["saida_console"] != "":
			console_log.append_text("\n\nSaída parcial:\n[b]" + resultado["saida_console"] + "[/b]")

func compilar_e_executar_java(codigo_bruto: String) -> Dictionary:
	var erros: Array[String] = []
	var variaveis_declaradas: Dictionary = {}
	var prints_realizados: Dictionary = {}
	var saida_console: String = ""
	
	var codigo: String = remover_comentarios(codigo_bruto)
	
	# 1. Valida chaves, parênteses, classe e método main
	if not verificar_balanceamento(codigo, "{", "}") or not verificar_balanceamento(codigo, "(", ")"):
		erros.append("Chaves '{ }' ou parênteses '( )' desbalanceados.")
		return { "erros": erros, "variaveis": variaveis_declaradas, "prints_realizados": prints_realizados, "saida_console": "" }
	
	var regex_classe := RegEx.new()
	regex_classe.compile('public\\s+class\\s+\\w+\\s*\\{')
	if regex_classe.search(codigo) == null:
		erros.append("Declaração 'public class NomeDaClasse {' não encontrada.")
		return { "erros": erros, "variaveis": variaveis_declaradas, "prints_realizados": prints_realizados, "saida_console": "" }
	
	var regex_main := RegEx.new()
	regex_main.compile('public\\s+static\\s+void\\s+main\\s*\\(\\s*String(?:\\[\\s*\\]|\\.\\.\\.)\\s+\\w+(?:\\[\\s*\\])?\\s*\\)\\s*\\{')
	var match_main := regex_main.search(codigo)
	if match_main == null:
		erros.append("Método 'public static void main(String[] args) {' não encontrado.")
		return { "erros": erros, "variaveis": variaveis_declaradas, "prints_realizados": prints_realizados, "saida_console": "" }
	
	# 2. Extrai e divide as instruções dentro do main
	var corpo_main: String = extrair_bloco_interno(codigo, match_main.get_end() - 1)
	var instrucoes: Array[String] = dividir_instrucoes_por_ponto_virgula(corpo_main, erros)
	
	var regex_decl := RegEx.new()
	regex_decl.compile('^(char|String|int|double|float|boolean)\\s+([a-zA-Z_]\\w*)\\s*=\\s*(.+)$')
	
	var regex_print := RegEx.new()
	regex_print.compile('^System\\.out\\.(println|print)\\s*\\(\\s*([^)]+)\\s*\\)$')
	
	# 3. Analisa cada linha: exige referência proposta + tipo compatível + literal válido
	for instrucao in instrucoes:
		var m_decl := regex_decl.search(instrucao)
		if m_decl != null:
			var tipo: String = m_decl.get_string(1)
			var nome_var: String = m_decl.get_string(2)
			var valor_bruto: String = m_decl.get_string(3).strip_edges()
			
			if not ESPECIFICACOES_VARIAVEIS.has(nome_var):
				erros.append("Referência '%s' não permitida. Use apenas: letra, texto, inteiro, real ou logico." % nome_var)
				continue
			
			var tipos_permitidos: Array = ESPECIFICACOES_VARIAVEIS[nome_var]["tipos"]
			if not (tipo in tipos_permitidos):
				erros.append("Tipo incorreto para '%s': esperado %s (Ex: %s)." % [nome_var, " ou ".join(tipos_permitidos), ESPECIFICACOES_VARIAVEIS[nome_var]["exemplo"]])
				continue
			
			if variaveis_declaradas.has(nome_var):
				erros.append("A variável '%s' já foi declarada anteriormente." % nome_var)
				continue
			
			var validacao_valor: Dictionary = validar_literal_por_tipo(tipo, valor_bruto)
			if not validacao_valor["valido"]:
				erros.append("Erro na atribuição de '%s': %s" % [nome_var, validacao_valor["erro"]])
				continue
			
			variaveis_declaradas[nome_var] = {
				"tipo": tipo,
				"valor_saida": validacao_valor["valor_formatado"]
			}
			continue
		
		var m_print := regex_print.search(instrucao)
		if m_print != null:
			var metodo_print: String = m_print.get_string(1)
			var argumento: String = m_print.get_string(2).strip_edges()
			
			if not ESPECIFICACOES_VARIAVEIS.has(argumento):
				erros.append("Referência inválida em System.out.%s(%s): passe apenas uma das variáveis propostas (letra, texto, inteiro, real, logico)." % [metodo_print, argumento])
				continue
			
			if not variaveis_declaradas.has(argumento):
				erros.append("A variável '%s' está sendo impressa antes de ser declarada corretamente." % argumento)
				continue
			
			prints_realizados[argumento] = true
			saida_console += variaveis_declaradas[argumento]["valor_saida"]
			if metodo_print == "println":
				saida_console += "\n"
			continue
		
		erros.append("Instrução inválida ou incompleta: '%s;'" % instrucao)
	
	return {
		"erros": erros,
		"variaveis": variaveis_declaradas,
		"prints_realizados": prints_realizados,
		"saida_console": saida_console.strip_edges(false, true)
	}

func validar_literal_por_tipo(tipo: String, valor: String) -> Dictionary:
	var regex := RegEx.new()
	
	match tipo:
		"char":
			regex.compile('^' + "'" + '([^\'\\\\]|\\\\[btnfr"\'\\\\])' + "'" + '$')
			var m := regex.search(valor)
			if m != null:
				return { "valido": true, "valor_formatado": m.get_string(1) }
			return { "valido": false, "erro": "'char' aceita apenas 1 caractere entre aspas simples (ex: 'A')." }
		
		"String":
			regex.compile('^"([^"\\\\]|\\\\.)*"$')
			if regex.search(valor) != null:
				return { "valido": true, "valor_formatado": valor.substr(1, valor.length() - 2) }
			return { "valido": false, "erro": "'String' aceita apenas texto entre aspas duplas (ex: \"João\")." }
		
		"int":
			regex.compile('^-?\\d+$')
			if regex.search(valor) != null:
				return { "valido": true, "valor_formatado": valor }
			return { "valido": false, "erro": "'int' aceita apenas números inteiros (ex: 10)." }
		
		"double":
			regex.compile('^-?\\d+(?:\\.\\d+)?[dD]?$')
			if regex.search(valor) != null:
				var limpo: String = valor.trim_suffix("d").trim_suffix("D")
				if not "." in limpo:
					limpo += ".0"
				return { "valido": true, "valor_formatado": limpo }
			return { "valido": false, "erro": "'double' aceita apenas valores numéricos reais (ex: 11.50)." }
		
		"float":
			regex.compile('^-?\\d+(?:\\.\\d+)?[fF]$')
			if regex.search(valor) != null:
				var limpo: String = valor.trim_suffix("f").trim_suffix("F")
				if not "." in limpo:
					limpo += ".0"
				return { "valido": true, "valor_formatado": limpo }
			
			var regex_sem_f := RegEx.new()
			regex_sem_f.compile('^-?\\d+(?:\\.\\d+)?$')
			if regex_sem_f.search(valor) != null:
				return { "valido": false, "erro": "Em Java, literais 'float' precisam terminar com 'f' (ex: %sf) ou declare como 'double'." % valor }
			return { "valido": false, "erro": "'float' aceita apenas valores numéricos com sufixo 'f' (ex: 11.50f)." }
		
		"boolean":
			if valor == "true" or valor == "false":
				return { "valido": true, "valor_formatado": valor }
			return { "valido": false, "erro": "'boolean' aceita apenas true ou false (sem aspas)." }
	
	return { "valido": false, "erro": "Tipo desconhecido." }

func dividir_instrucoes_por_ponto_virgula(corpo: String, erros: Array[String]) -> Array[String]:
	var lista: Array[String] = []
	var atual: String = ""
	var em_aspas_duplas: bool = false
	var em_aspas_simples: bool = false
	var escapado: bool = false
	
	for i in corpo.length():
		var c: String = corpo[i]
		if escapado:
			atual += c
			escapado = false
			continue
		if c == "\\":
			atual += c
			escapado = true
			continue
		if c == "\"" and not em_aspas_simples:
			em_aspas_duplas = not em_aspas_duplas
			atual += c
			continue
		if c == "'" and not em_aspas_duplas:
			em_aspas_simples = not em_aspas_simples
			atual += c
			continue
		if c == ";" and not em_aspas_duplas and not em_aspas_simples:
			var limpa: String = atual.strip_edges()
			if limpa != "":
				lista.append(limpa)
			atual = ""
		else:
			atual += c
	
	if em_aspas_duplas or em_aspas_simples:
		erros.append("Aspas não fechadas em uma das instruções.")
	elif atual.strip_edges() != "":
		erros.append("Falta ponto e vírgula ';' no final da instrução: '%s'" % atual.strip_edges())
	
	return lista

func remover_comentarios(texto: String) -> String:
	var resultado: String = ""
	var em_aspas_duplas: bool = false
	var em_aspas_simples: bool = false
	var i: int = 0
	
	while i < texto.length():
		var c: String = texto[i]
		if c == "\\" and (em_aspas_duplas or em_aspas_simples) and i + 1 < texto.length():
			resultado += c + texto[i + 1]
			i += 2
			continue
		if c == "\"" and not em_aspas_simples:
			em_aspas_duplas = not em_aspas_duplas
			resultado += c
			i += 1
			continue
		if c == "'" and not em_aspas_duplas:
			em_aspas_simples = not em_aspas_simples
			resultado += c
			i += 1
			continue
		if not em_aspas_duplas and not em_aspas_simples and c == "/" and i + 1 < texto.length() and texto[i + 1] == "/":
			while i < texto.length() and texto[i] != "\n":
				i += 1
			continue
		resultado += c
		i += 1
	
	return resultado

func extrair_bloco_interno(texto: String, pos_abre_chave: int) -> String:
	var nivel: int = 0
	var inicio: int = pos_abre_chave + 1
	for i in range(pos_abre_chave, texto.length()):
		if texto[i] == "{":
			nivel += 1
		elif texto[i] == "}":
			nivel -= 1
			if nivel == 0:
				return texto.substr(inicio, i - inicio)
	return ""

func verificar_balanceamento(texto: String, abre: String, fecha: String) -> bool:
	var contador: int = 0
	for i in texto.length():
		var c: String = texto[i]
		if c == abre:
			contador += 1
		elif c == fecha:
			contador -= 1
			if contador < 0:
				return false
	return contador == 0

func _update_task_color(index: int, is_done: bool) -> void:
	if is_done:
		task_list.set_item_custom_fg_color(index, Color.GREEN)
	else:
		task_list.set_item_custom_fg_color(index, Color.WHITE)

func _on_botao_voltar_pressed() -> void:
	GameManager.voltar_laboratorio()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		GameManager.voltar_laboratorio()
