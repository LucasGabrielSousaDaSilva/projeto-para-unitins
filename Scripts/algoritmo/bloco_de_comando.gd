extends Control

@onready var code_edit: CodeEdit = $CodeEdit
@onready var terminal_output: RichTextLabel = $RichTextLabel
@onready var terminal_input: LineEdit = $LineEdit
@onready var btn_executar: Button = $Button

# Guarda os dados extraídos do código após passar na "compilação"
var dados_compilados: Dictionary = {}

func _ready() -> void:
	btn_executar.pressed.connect(_on_executar_pressed)
	terminal_input.text_submitted.connect(_on_entrada_terminal_enviada)
	terminal_input.editable = false
	
	code_edit.text = "public class Comando {\n\t\n}"

func _on_executar_pressed() -> void:
	var codigo: String = code_edit.text
	terminal_output.clear()
	terminal_input.editable = false
	
	# 1. Valida a sintaxe e extrai variáveis, condição e saídas do código
	var resultado_compilacao: Dictionary = compilar_codigo_java(codigo)
	
	if not resultado_compilacao["sucesso"]:
		imprimir_no_terminal("[color=red][ERRO DE COMPILAÇÃO][/color] " + resultado_compilacao["erro"])
		return
	
	dados_compilados = resultado_compilacao
	imprimir_no_terminal("[color=green]Compilado com sucesso![/color]\n")
	
	# Se o jogador escreveu um System.out.println antes do nextInt(), exibe a pergunta dele
	if dados_compilados["prompt_inicial"] != "":
		imprimir_no_terminal(dados_compilados["prompt_inicial"])
	else:
		imprimir_no_terminal("Digite a sua idade no campo abaixo e pressione Enter:")
	
	terminal_input.editable = true
	terminal_input.grab_focus()

func _on_entrada_terminal_enviada(texto_digitado: String) -> void:
	if not texto_digitado.is_valid_int():
		imprimir_no_terminal("[color=red][ERRO][/color] InputMismatchException: digite um número inteiro válido!")
		terminal_input.clear()
		return
	
	var idade: int = texto_digitado.to_int()
	
	imprimir_no_terminal("> " + texto_digitado)
	terminal_input.clear()
	terminal_input.editable = false
	
	# 2. Executa a condição real escrita pelo jogador usando a idade digitada
	var condicao_verdadeira: bool = avaliar_expressao(
		dados_compilados["variavel"],
		dados_compilados["operador"],
		dados_compilados["valor_comparacao"],
		idade
	)
	
	var saida_escolhida: String = dados_compilados["saida_if"] if condicao_verdadeira else dados_compilados["saida_else"]
	imprimir_no_terminal("\nSaída:\n[b]%s[/b]" % saida_escolhida)
	
	# Verifica se a lógica atende ao objetivo do desafio (maioridade aos 18 anos)
	var testa_maioridade_corretamente: bool = (
		avaliar_expressao(dados_compilados["variavel"], dados_compilados["operador"], dados_compilados["valor_comparacao"], 18) !=
		avaliar_expressao(dados_compilados["variavel"], dados_compilados["operador"], dados_compilados["valor_comparacao"], 17)
	)
	if not testa_maioridade_corretamente:
		imprimir_no_terminal("\n[color=yellow][AVISO][/color] O código rodou, mas a regra não separa corretamente menores de 18 e maiores ou iguais a 18.")

func compilar_codigo_java(codigo: String) -> Dictionary:
	# Verifica chaves { } e parênteses ( ) balanceados
	if not verificar_balanceamento(codigo, "{", "}"):
		return { "sucesso": false, "erro": "Chaves '{ }' desbalanceadas. Verifique a abertura e o fechamento dos blocos." }
	if not verificar_balanceamento(codigo, "(", ")"):
		return { "sucesso": false, "erro": "Parênteses '( )' desbalanceados." }
	
	# Verifica declaração da classe
	var regex_classe := RegEx.new()
	regex_classe.compile('public\\s+class\\s+\\w+\\s*\\{')
	if regex_classe.search(codigo) == null:
		return { "sucesso": false, "erro": "Declaração 'public class NomeDaClasse {' não encontrada." }
	
	# Verifica instanciação válida do Scanner com ponto e vírgula
	var regex_scanner := RegEx.new()
	regex_scanner.compile('Scanner\\s+(\\w+)\\s*=\\s*new\\s+Scanner\\s*\\(\\s*System\\.in\\s*\\)\\s*;')
	var match_scanner := regex_scanner.search(codigo)
	if match_scanner == null:
		return { "sucesso": false, "erro": "Declare o Scanner corretamente. Ex: Scanner leitor = new Scanner(System.in);" }
	var nome_scanner: String = match_scanner.get_string(1)
	
	# Verifica leitura do inteiro usando o Scanner declarado e captura o nome da variável
	var regex_next_int := RegEx.new()
	regex_next_int.compile('(?:int\\s+)?(\\w+)\\s*=\\s*' + nome_scanner + '\\s*\\.\\s*nextInt\\s*\\(\\s*\\)\\s*;')
	var match_next_int := regex_next_int.search(codigo)
	if match_next_int == null:
		return { "sucesso": false, "erro": "Leia um inteiro usando '%s.nextInt();' e armazene em uma variável (ex: int idade = %s.nextInt();)." % [nome_scanner, nome_scanner] }
	var nome_variavel: String = match_next_int.get_string(1)
	
	# Verifica se existe um print opcional antes do nextInt()
	var codigo_antes_leitura: String = codigo.substr(0, match_next_int.get_start())
	var prompt_inicial: String = extrair_print(codigo_antes_leitura)
	
	# Verifica a estrutura completa: if (condicao) { ... } else { ... }
	var regex_if_else := RegEx.new()
	regex_if_else.compile('if\\s*\\(([^)]+)\\)\\s*\\{([^{}]*)\\}\\s*else\\s*\\{([^{}]*)\\}')
	var match_if_else := regex_if_else.search(codigo)
	if match_if_else == null:
		return { "sucesso": false, "erro": "Estrutura 'if (condição) { ... } else { ... }' inválida ou incompleta." }
	
	var condicao_bruta: String = match_if_else.get_string(1)
	var bloco_if: String = match_if_else.get_string(2)
	var bloco_else: String = match_if_else.get_string(3)
	
	# Valida a expressão lógica dentro do if (...)
	var dados_condicao: Dictionary = interpretar_condicao(condicao_bruta, nome_variavel)
	if not dados_condicao["valida"]:
		return { "sucesso": false, "erro": dados_condicao["erro"] }
	
	# Extrai os comandos System.out.print/println dentro de cada bloco
	var saida_if: String = extrair_print(bloco_if)
	if saida_if == "":
		return { "sucesso": false, "erro": "Falta um comando System.out.println(\"...\"); válido dentro do bloco 'if'." }
	
	var saida_else: String = extrair_print(bloco_else)
	if saida_else == "":
		return { "sucesso": false, "erro": "Falta um comando System.out.println(\"...\"); válido dentro do bloco 'else'." }
	
	return {
		"sucesso": true,
		"variavel": nome_variavel,
		"operador": dados_condicao["operador"],
		"valor_comparacao": dados_condicao["valor"],
		"saida_if": saida_if,
		"saida_else": saida_else,
		"prompt_inicial": prompt_inicial
	}

func interpretar_condicao(condicao: String, var_esperada: String) -> Dictionary:
	# Aceita formato: variavel operador numero (ex: idade >= 18, idade > 17, idade < 18)
	var regex_esq := RegEx.new()
	regex_esq.compile('^\\s*(\\w+)\\s*(>=|<=|>|<|==|!=)\\s*(-?\\d+)\\s*$')
	var m_esq := regex_esq.search(condicao)
	
	if m_esq != null:
		var var_usada: String = m_esq.get_string(1)
		if var_usada != var_esperada:
			return { "valida": false, "erro": "A variável '%s' usada no 'if' não foi declarada (use '%s')." % [var_usada, var_esperada] }
		return {
			"valida": true,
			"operador": m_esq.get_string(2),
			"valor": m_esq.get_string(3).to_int()
		}
	
	# Aceita formato invertido: numero operador variavel (ex: 18 <= idade, 17 < idade)
	var regex_dir := RegEx.new()
	regex_dir.compile('^\\s*(-?\\d+)\\s*(>=|<=|>|<|==|!=)\\s*(\\w+)\\s*$')
	var m_dir := regex_dir.search(condicao)
	
	if m_dir != null:
		var var_usada: String = m_dir.get_string(3)
		if var_usada != var_esperada:
			return { "valida": false, "erro": "A variável '%s' usada no 'if' não foi declarada (use '%s')." % [var_usada, var_esperada] }
		
		var op_invertido: String = m_dir.get_string(2)
		match op_invertido:
			">=": op_invertido = "<="
			"<=": op_invertido = ">="
			">": op_invertido = "<"
			"<": op_invertido = ">"
		
		return {
			"valida": true,
			"operador": op_invertido,
			"valor": m_dir.get_string(1).to_int()
		}
	
	return { "valida": false, "erro": "Condição '%s' inválida no 'if'. Use uma comparação numérica (ex: %s >= 18 ou %s > 17)." % [condicao.strip_edges(), var_esperada, var_esperada] }

func avaliar_expressao(variavel: String, operador: String, valor_comp: int, entrada: int) -> bool:
	match operador:
		">=": return entrada >= valor_comp
		"<=": return entrada <= valor_comp
		">": return entrada > valor_comp
		"<": return entrada < valor_comp
		"==": return entrada == valor_comp
		"!=": return entrada != valor_comp
	return false

func extrair_print(trecho: String) -> String:
	var regex_print := RegEx.new()
	regex_print.compile('System\\.out\\.print(?:ln)?\\s*\\(\\s*"([^"]*)"\\s*\\)\\s*;')
	var m := regex_print.search(trecho)
	return m.get_string(1) if m != null else ""

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

func imprimir_no_terminal(texto: String) -> void:
	terminal_output.append_text(texto + "\n")

func _on_botao_voltar_pressed() -> void:
	GameManager.voltar_laboratorio()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		GameManager.voltar_laboratorio()
