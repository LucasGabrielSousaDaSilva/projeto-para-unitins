extends Control

# =============================================================================
# CALCULADORA (Algoritmos)
# O aluno escreve em Java, no editor, a lógica de cada botão. A calculadora só
# libera um botão quando o código enviado REALMENTE trata aquele botão, isto é,
# quando existe um if / else if com a condição correta e a chamada correta
# dentro dele. Palavras soltas ou escritas em comentários não liberam nada.
# =============================================================================

# --- REFERÊNCIAS DOS NÓS DA INTERFACE ---
@onready var code_edit: CodeEdit = %CodeEdit
@onready var btn_enviar: Button = %BotaoEnviar
@onready var btn_voltar: Button = %BotaoVoltar
@onready var visor_operacao: Label = %VisorOperacao
@onready var visor_resultado: Label = %VisorResultado
@onready var grid_botoes: GridContainer = %GridBotoes
@onready var conclusao: RichTextLabel = %Conclusao

# --- CONSTANTES DA CALCULADORA ---
const DIGITOS: Array[String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
const OPERADORES: Array[String] = ["+", "-", "*", "/"]
const ALIAS_OPERADORES: Dictionary = { "×": "*", "÷": "/" }
const MAX_DIGITOS: int = 12
const MAX_TERMOS: int = 41

# Textos aceitos em matches("...") para "qualquer dígito"
const PADROES_DIGITO: Array[String] = ["[0-9]", "\\d", "\\\\d"]

# Nomes de métodos aceitos dentro de cada ramo do if
const CHAMADAS_IGUAL: Array[String] = ["calcular", "calcularResultado"]
const CHAMADAS_LIMPAR: Array[String] = ["limpar", "limparVisor"]

# --- PALETA VISUAL ---
var cor_fundo_codigo: Color = Color("#0b120e")
var cor_cartao: Color = Color("#13201a")
var cor_visor: Color = Color("#09100c")
var cor_borda: Color = Color("#2b4538")
var cor_texto: Color = Color("#eef6f1")
var cor_texto_suave: Color = Color("#8fb3a0")
var cor_numero: Color = Color("#26392f")
var cor_operador: Color = Color("#e3a63d")
var cor_igual: Color = Color("#3ecf8e")
var cor_limpar: Color = Color("#d95c5c")
var cor_suave: String = "#8fb3a0"
var cor_ok: String = "#5ee08f"
var cor_alerta: String = "#ffb454"
var cor_erro: String = "#ff7b72"

# --- ESTADO DA CALCULADORA ---
var termos: Array = []              # Números (float) e operadores (String) já confirmados
var entrada_atual: String = ""      # Número que está sendo digitado agora
var resultado_na_tela: bool = false # Acabou de calcular com "="
var ultimo_resultado: float = 0.0
var expressao_final: String = ""
var em_erro: bool = false

# --- ESTADO DO CÓDIGO DO ALUNO ---
# Guarda quais botões foram programados corretamente: { "7": true, "+": true, ... }
var botoes_liberados: Dictionary = {}
var resumo_codigo: String = ""

func _ready() -> void:
	_aplicar_estilos()
	_configurar_editor()
	_carregar_template_java()

	btn_enviar.pressed.connect(_on_enviar_codigo)

	for no in grid_botoes.get_children():
		var botao := no as Button
		if botao:
			botao.pressed.connect(_on_botao_calculadora_pressionado.bind(botao.text))

	_limpar_tudo()
	_atualizar_estado_botoes()
	resumo_codigo = "[color=%s]Escreva o código dentro do main e clique em Enviar para ativar a calculadora.[/color]" % cor_suave
	conclusao.text = resumo_codigo

# Carrega a estrutura de classe Java inicial
func _carregar_template_java() -> void:
	var template: String = """public class Calculadora {
    public static void main(String[] args) {

        // Escreva aqui a lógica dos botões da calculadora

    }
}"""
	code_edit.text = template

# Botão "Enviar": lê o código do aluno
func _on_enviar_codigo() -> void:
	_analisar_codigo_java(code_edit.text)
	_limpar_tudo()
	_atualizar_estado_botoes()

# =============================================================================
# ANALISADOR DO CÓDIGO JAVA
# =============================================================================
func _analisar_codigo_java(texto: String) -> void:
	botoes_liberados.clear()

	var codigo: String = _remover_comentarios(texto)

	if not _delimitadores_balanceados(codigo):
		resumo_codigo = "[color=%s]Erro de sintaxe: há chaves { } ou parênteses ( ) sem fechamento.[/color]" % cor_erro
		conclusao.text = resumo_codigo
		return

	for ramo in _extrair_ramos_if(codigo):
		_processar_ramo(ramo["condicao"], ramo["corpo"])

	_montar_relatorio(codigo)

# Verifica se um if/else if trata algum botão de forma correta
func _processar_ramo(condicao: String, corpo: String) -> void:
	var comparacoes: Array[String] = []
	var residuo: String = condicao

	# Comparações aceitas: comando.equals("x") / "x".equals(comando)
	for padrao in ['comando\\s*\\.\\s*equals\\s*\\(\\s*"([^"]*)"\\s*\\)', '"([^"]*)"\\s*\\.\\s*equals\\s*\\(\\s*comando\\s*\\)']:
		var re := RegEx.new()
		re.compile(padrao)
		for m in re.search_all(condicao):
			comparacoes.append(m.get_string(1))
			residuo = residuo.replace(m.get_string(0), "")

	# Comparação por expressão regular: comando.matches("[0-9]")
	var tem_digitos_regex: bool = false
	var re_matches := RegEx.new()
	re_matches.compile('comando\\s*\\.\\s*matches\\s*\\(\\s*"([^"]*)"\\s*\\)')
	for m in re_matches.search_all(condicao):
		if m.get_string(1) in PADROES_DIGITO:
			tem_digitos_regex = true
		residuo = residuo.replace(m.get_string(0), "")

	# Depois de tirar as comparações só podem sobrar "||", parênteses e espaços.
	# Isso recusa condições com && , ! ou lixo no meio.
	residuo = residuo.replace("||", "").replace("(", "").replace(")", "").strip_edges()
	if residuo != "":
		return
	if comparacoes.is_empty() and not tem_digitos_regex:
		return

	# Números: if (comando.matches("[0-9]")) { adicionarNumero(comando); }
	if _corpo_chama(corpo, ["adicionarNumero"], "comando"):
		if tem_digitos_regex:
			for d in DIGITOS:
				botoes_liberados[d] = true
		for c in comparacoes:
			if c in DIGITOS:
				botoes_liberados[c] = true

	# Operadores: if (comando.equals("+") || ...) { definirOperador(comando); }
	if _corpo_chama(corpo, ["definirOperador"], "comando"):
		for c in comparacoes:
			var op: String = ALIAS_OPERADORES.get(c, c)
			if op in OPERADORES:
				botoes_liberados[op] = true

	# Igual: if (comando.equals("=")) { calcular(); }
	if "=" in comparacoes and _corpo_chama(corpo, CHAMADAS_IGUAL, ""):
		botoes_liberados["="] = true

	# Limpar: if (comando.equals("C")) { limpar(); }
	if "C" in comparacoes and _corpo_chama(corpo, CHAMADAS_LIMPAR, ""):
		botoes_liberados["C"] = true

# Confere se o corpo do ramo contém a chamada "nome(argumento);"
func _corpo_chama(corpo: String, nomes: Array, argumento: String) -> bool:
	for nome in nomes:
		var re := RegEx.new()
		re.compile('\\b' + nome + '\\s*\\(\\s*' + argumento + '\\s*\\)\\s*;')
		if re.search(corpo) != null:
			return true
	return false

# Monta o texto de feedback (checklist) exibido no painel de status
func _montar_relatorio(codigo: String) -> void:
	var digitos_faltando: Array[String] = []
	for d in DIGITOS:
		if not _botao_liberado(d):
			digitos_faltando.append(d)

	var operadores_faltando: Array[String] = []
	for op in OPERADORES:
		if not _botao_liberado(op):
			operadores_faltando.append(op)

	var numeros_ok: bool = digitos_faltando.is_empty()
	var operadores_ok: bool = operadores_faltando.is_empty()
	var igual_ok: bool = _botao_liberado("=")
	var limpar_ok: bool = _botao_liberado("C")

	var linhas: Array[String] = []
	linhas.append(_linha_status(numeros_ok, "Números (0-9)", digitos_faltando, DIGITOS.size()))
	linhas.append(_linha_status(operadores_ok, "Operadores (+ - * /)", operadores_faltando, OPERADORES.size()))
	linhas.append(_linha_status(igual_ok, "Igual (=)", [], 0))
	linhas.append(_linha_status(limpar_ok, "Limpar (C)", [], 0))

	var titulo: String
	if numeros_ok and operadores_ok and igual_ok and limpar_ok:
		titulo = "[color=%s][b]Código Compilado com Sucesso! Calculadora Ativa.[/b][/color]" % cor_ok
	elif botoes_liberados.is_empty():
		titulo = "[color=%s][b]Aviso: Escreva o código dentro do main e clique em Enviar.[/b][/color]" % cor_erro
	else:
		titulo = "[color=%s][b]Código Parcialmente Aplicado! Algumas funções ainda estão bloqueadas.[/b][/color]" % cor_alerta

	var texto: String = titulo + "\n" + "\n".join(linhas)

	# Palavras soltas: o nome do método aparece, mas fora do if certo
	var faltou_algo: bool = not (numeros_ok and operadores_ok and igual_ok and limpar_ok)
	if faltou_algo and _tem_palavra_solta(codigo):
		texto += "\n[color=%s]Dica: não basta escrever o nome do método. Ele precisa estar dentro do if / else if do botão certo.[/color]" % cor_suave

	resumo_codigo = texto
	conclusao.text = texto

func _linha_status(ok: bool, nome: String, faltando: Array, total: int) -> String:
	if ok:
		return "[color=%s]OK[/color]  %s" % [cor_ok, nome]
	var detalhe: String = ""
	if not faltando.is_empty() and faltando.size() < total:
		detalhe = "  (falta: " + " ".join(faltando) + ")"
	return "[color=%s]Falta[/color]  %s%s" % [cor_alerta, nome, detalhe]

func _tem_palavra_solta(codigo: String) -> bool:
	for nome in ["adicionarNumero", "definirOperador", "calcular", "limpar"]:
		if codigo.contains(nome):
			return true
	return false

# Remove // e /* */ respeitando textos entre aspas
func _remover_comentarios(texto: String) -> String:
	var saida: String = ""
	var n: int = texto.length()
	var i: int = 0
	var em_string: bool = false

	while i < n:
		var c: String = texto[i]

		if em_string:
			saida += c
			if c == "\\" and i + 1 < n:
				saida += texto[i + 1]
				i += 1
			elif c == "\"":
				em_string = false
			i += 1
			continue

		if c == "\"":
			em_string = true
			saida += c
		elif c == "/" and i + 1 < n and texto[i + 1] == "/":
			while i < n and texto[i] != "\n":
				i += 1
			continue
		elif c == "/" and i + 1 < n and texto[i + 1] == "*":
			i += 2
			while i + 1 < n and not (texto[i] == "*" and texto[i + 1] == "/"):
				i += 1
			i += 2
			saida += " "
			continue
		else:
			saida += c
		i += 1

	return saida

func _delimitadores_balanceados(codigo: String) -> bool:
	var pilha: Array[String] = []
	var pares: Dictionary = { ")": "(", "}": "{", "]": "[" }
	var em_string: bool = false
	var i: int = 0

	while i < codigo.length():
		var c: String = codigo[i]
		if em_string:
			if c == "\\":
				i += 1
			elif c == "\"":
				em_string = false
		elif c == "\"":
			em_string = true
		elif c == "(" or c == "{" or c == "[":
			pilha.append(c)
		elif pares.has(c):
			if pilha.is_empty() or pilha.pop_back() != pares[c]:
				return false
		i += 1

	return pilha.is_empty() and not em_string

# Retorna a posição do delimitador que fecha o que foi aberto em pos_abre
func _achar_fechamento(texto: String, pos_abre: int, abre: String, fecha: String) -> int:
	var profundidade: int = 0
	var em_string: bool = false
	var i: int = pos_abre

	while i < texto.length():
		var c: String = texto[i]
		if em_string:
			if c == "\\":
				i += 1
			elif c == "\"":
				em_string = false
		elif c == "\"":
			em_string = true
		elif c == abre:
			profundidade += 1
		elif c == fecha:
			profundidade -= 1
			if profundidade == 0:
				return i
		i += 1

	return -1

# Lista cada if / else if com a sua condição e o seu corpo
func _extrair_ramos_if(codigo: String) -> Array[Dictionary]:
	var ramos: Array[Dictionary] = []
	var re_if := RegEx.new()
	re_if.compile('\\bif\\s*\\(')

	for m in re_if.search_all(codigo):
		var abre: int = m.get_end() - 1
		var fecha: int = _achar_fechamento(codigo, abre, "(", ")")
		if fecha == -1:
			continue

		var condicao: String = codigo.substr(abre + 1, fecha - abre - 1)

		var pos: int = fecha + 1
		while pos < codigo.length() and codigo[pos].strip_edges() == "":
			pos += 1

		var corpo: String = ""
		if pos < codigo.length() and codigo[pos] == "{":
			var fecha_chave: int = _achar_fechamento(codigo, pos, "{", "}")
			if fecha_chave == -1:
				continue
			corpo = codigo.substr(pos + 1, fecha_chave - pos - 1)
		else:
			# if sem chaves: o corpo é a próxima instrução
			var fim: int = codigo.find(";", pos)
			if fim == -1:
				continue
			corpo = codigo.substr(pos, fim - pos + 1)

		ramos.append({ "condicao": condicao, "corpo": corpo })

	return ramos

# =============================================================================
# BOTÕES DA CALCULADORA
# =============================================================================
func _botao_liberado(comando: String) -> bool:
	return botoes_liberados.has(comando)

func _on_botao_calculadora_pressionado(comando: String) -> void:
	if not _botao_liberado(comando):
		_mostrar_erro(_mensagem_bloqueio(comando))
		return

	conclusao.text = resumo_codigo

	if comando in DIGITOS:
		_adicionar_numero(comando)
	elif comando in OPERADORES:
		_definir_operador(comando)
	elif comando == "=":
		_calcular_resultado()
	elif comando == "C":
		_limpar_tudo()

func _mensagem_bloqueio(comando: String) -> String:
	if comando in DIGITOS:
		return "Erro: Tratamento do NÚMERO %s não programado!" % comando
	if comando in OPERADORES:
		return "Erro: Lógica do OPERADOR (%s) não programada!" % comando
	if comando == "=":
		return "Erro: Lógica do IGUAL (=) não programada!"
	return "Erro: Lógica de LIMPAR (C) não programada!"

func _mostrar_erro(mensagem: String) -> void:
	conclusao.text = "[color=%s]%s[/color]" % [cor_erro, mensagem]

# =============================================================================
# MOTOR DA CALCULADORA (várias contas na mesma expressão, com precedência)
# =============================================================================
func _adicionar_numero(digito: String) -> void:
	if em_erro or resultado_na_tela:
		_reiniciar_estado()

	if entrada_atual == "0":
		entrada_atual = digito
	elif entrada_atual.length() < MAX_DIGITOS:
		entrada_atual += digito

	_atualizar_visores()

func _definir_operador(op: String) -> void:
	if em_erro:
		_reiniciar_estado()

	if resultado_na_tela:
		# Continua a conta a partir do resultado anterior
		termos = [ultimo_resultado]
		entrada_atual = ""
		resultado_na_tela = false

	if entrada_atual != "":
		if termos.size() >= MAX_TERMOS:
			return
		termos.append(entrada_atual.to_float())
		entrada_atual = ""
	elif termos.is_empty():
		termos.append(0.0)
	elif termos.back() is String:
		# Dois operadores seguidos: o último substitui o anterior
		termos.pop_back()

	termos.append(op)
	_atualizar_visores()

func _calcular_resultado() -> void:
	if em_erro or resultado_na_tela:
		return

	var conta: Array = termos.duplicate()
	if entrada_atual != "":
		conta.append(entrada_atual.to_float())
	elif not conta.is_empty() and conta.back() is String:
		conta.pop_back() # operador sobrando no final é ignorado

	if conta.is_empty():
		return

	var texto_conta: String = _montar_expressao(conta)
	var avaliacao: Dictionary = _avaliar(conta)

	if not avaliacao["ok"]:
		visor_operacao.text = avaliacao["erro"]
		visor_resultado.text = "Erro"
		_ajustar_fonte_resultado()
		em_erro = true
		termos = []
		entrada_atual = ""
		return

	ultimo_resultado = avaliacao["valor"]
	expressao_final = texto_conta + " ="
	termos = []
	entrada_atual = ""
	resultado_na_tela = true
	_atualizar_visores()

# Avalia a lista [n, op, n, op, n...] respeitando a precedência: * e / antes de + e -
# Exemplo: 1 + 2 * 3  ->  1 + 6  ->  7
func _avaliar(conta: Array) -> Dictionary:
	var valores: Array[float] = [float(conta[0])]
	var somas: Array[String] = []

	var i: int = 1
	while i + 1 < conta.size():
		var op: String = conta[i]
		var numero: float = float(conta[i + 1])

		if op == "*":
			valores[valores.size() - 1] = valores[valores.size() - 1] * numero
		elif op == "/":
			if numero == 0.0:
				return { "ok": false, "erro": "Não é possível dividir por zero" }
			valores[valores.size() - 1] = valores[valores.size() - 1] / numero
		else:
			somas.append(op)
			valores.append(numero)
		i += 2

	var total: float = valores[0]
	for j in somas.size():
		if somas[j] == "+":
			total += valores[j + 1]
		else:
			total -= valores[j + 1]

	return { "ok": true, "valor": total }

func _montar_expressao(conta: Array) -> String:
	var partes: Array[String] = []
	for item in conta:
		if item is String:
			partes.append(item)
		else:
			partes.append(_formatar_numero(float(item)))
	return " ".join(partes)

func _limpar_tudo() -> void:
	_reiniciar_estado()

func _reiniciar_estado() -> void:
	termos = []
	entrada_atual = ""
	resultado_na_tela = false
	ultimo_resultado = 0.0
	expressao_final = ""
	em_erro = false
	_atualizar_visores()

func _atualizar_visores() -> void:
	var operacao: String = ""
	var principal: String = "0"

	if resultado_na_tela:
		operacao = expressao_final
		principal = _formatar_numero(ultimo_resultado)
	else:
		var partes: Array[String] = []
		if not termos.is_empty():
			partes.append(_montar_expressao(termos))
		if entrada_atual != "":
			partes.append(entrada_atual)
		operacao = " ".join(partes)

		if entrada_atual != "":
			principal = entrada_atual
		elif termos.size() >= 2:
			# Logo após um operador: mostra o último número digitado
			principal = _formatar_numero(float(termos[termos.size() - 2]))

	if operacao.length() > 30:
		operacao = "..." + operacao.substr(operacao.length() - 27)

	visor_operacao.text = operacao
	visor_resultado.text = principal
	_ajustar_fonte_resultado()

func _ajustar_fonte_resultado() -> void:
	var tamanho: int = 40
	var n: int = visor_resultado.text.length()
	if n > 16:
		tamanho = 24
	elif n > 11:
		tamanho = 32
	visor_resultado.add_theme_font_size_override("font_size", tamanho)

func _formatar_numero(num: float) -> String:
	if is_nan(num) or is_inf(num):
		return "Erro"

	var arredondado: float = snappedf(num, 0.000001)
	if arredondado == 0.0:
		return "0"
	if absf(arredondado) >= 1.0e12:
		return String.num_scientific(arredondado)

	var texto: String = "%.6f" % arredondado
	return texto.rstrip("0").rstrip(".")

# =============================================================================
# VISUAL
# =============================================================================
func _atualizar_estado_botoes() -> void:
	for no in grid_botoes.get_children():
		var botao := no as Button
		if botao == null:
			continue
		var liberado: bool = _botao_liberado(botao.text)
		botao.modulate = Color(1, 1, 1, 1) if liberado else Color(1, 1, 1, 0.45)
		botao.tooltip_text = "" if liberado else "Ainda não programado no código Java"

func _estilo_caixa(cor: Color, raio: int = 12, cor_borda_caixa: Color = Color(0, 0, 0, 0), largura_borda: int = 0, margem: int = 0) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(raio)
	estilo.border_color = cor_borda_caixa
	estilo.set_border_width_all(largura_borda)
	if margem > 0:
		estilo.set_content_margin_all(margem)
	return estilo

func _estilizar_botao(botao: Button, cor: Color, cor_fonte: Color, tamanho_fonte: int) -> void:
	var normal := _estilo_caixa(cor, 10)
	normal.shadow_color = Color(0, 0, 0, 0.4)
	normal.shadow_size = 3
	normal.shadow_offset = Vector2(0, 2)

	var hover := _estilo_caixa(cor.lightened(0.14), 10)
	hover.shadow_color = Color(0, 0, 0, 0.4)
	hover.shadow_size = 3
	hover.shadow_offset = Vector2(0, 2)

	var apertado := _estilo_caixa(cor.darkened(0.2), 10)

	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_stylebox_override("pressed", apertado)
	botao.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	botao.add_theme_stylebox_override("disabled", normal)
	botao.add_theme_color_override("font_color", cor_fonte)
	botao.add_theme_color_override("font_hover_color", cor_fonte)
	botao.add_theme_color_override("font_pressed_color", cor_fonte)
	botao.add_theme_color_override("font_focus_color", cor_fonte)
	botao.add_theme_font_size_override("font_size", tamanho_fonte)

func _aplicar_estilos() -> void:
	var negrito := FontVariation.new()
	negrito.base_font = get_theme_default_font()
	negrito.variation_embolden = 0.6

	# Títulos
	var titulo := %Titulo as Label
	titulo.add_theme_font_override("font", negrito)
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", cor_texto)

	var rotulo_editor := %RotuloEditor as Label
	rotulo_editor.add_theme_font_override("font", negrito)
	rotulo_editor.add_theme_font_size_override("font_size", 16)
	rotulo_editor.add_theme_color_override("font_color", cor_texto_suave)

	# Botão de voltar
	btn_voltar.add_theme_stylebox_override("normal", _estilo_caixa(Color(1, 1, 1, 0.06), 8, cor_borda, 1, 8))
	btn_voltar.add_theme_stylebox_override("hover", _estilo_caixa(Color(1, 1, 1, 0.14), 8, cor_borda, 1, 8))
	btn_voltar.add_theme_stylebox_override("pressed", _estilo_caixa(Color(1, 1, 1, 0.03), 8, cor_borda, 1, 8))
	btn_voltar.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn_voltar.add_theme_color_override("font_color", cor_texto)
	btn_voltar.add_theme_color_override("font_hover_color", cor_texto)
	btn_voltar.add_theme_font_size_override("font_size", 14)

	# Botão de enviar
	_estilizar_botao(btn_enviar, cor_igual, Color("#06210f"), 20)
	btn_enviar.add_theme_font_override("font", negrito)

	# Cartão da calculadora e visores
	(%Cartao as PanelContainer).add_theme_stylebox_override("panel", _estilo_caixa(cor_cartao, 16, cor_borda, 1))
	(%PainelStatus as PanelContainer).add_theme_stylebox_override("panel", _estilo_caixa(cor_cartao, 12, cor_borda, 1))

	(%PainelVisorOperacao as PanelContainer).add_theme_stylebox_override("panel", _estilo_caixa(cor_visor, 10, cor_borda, 1, 10))
	(%PainelVisorResultado as PanelContainer).add_theme_stylebox_override("panel", _estilo_caixa(cor_visor, 10, cor_borda, 1, 10))

	visor_operacao.add_theme_color_override("font_color", cor_texto_suave)
	visor_operacao.add_theme_font_size_override("font_size", 18)
	visor_resultado.add_theme_color_override("font_color", cor_texto)
	visor_resultado.add_theme_font_override("font", negrito)

	# Status
	conclusao.add_theme_color_override("default_color", cor_texto)
	conclusao.add_theme_font_size_override("normal_font_size", 14)
	conclusao.add_theme_font_size_override("bold_font_size", 15)
	conclusao.add_theme_font_override("bold_font", negrito)

	# Botões da calculadora, coloridos por função
	for no in grid_botoes.get_children():
		var botao := no as Button
		if botao == null:
			continue
		if botao.text in DIGITOS:
			_estilizar_botao(botao, cor_numero, cor_texto, 22)
		elif botao.text in OPERADORES:
			_estilizar_botao(botao, cor_operador, Color("#2a1b02"), 26)
			botao.add_theme_font_override("font", negrito)
		elif botao.text == "=":
			_estilizar_botao(botao, cor_igual, Color("#06210f"), 26)
			botao.add_theme_font_override("font", negrito)
		else:
			_estilizar_botao(botao, cor_limpar, Color("#2a0707"), 22)
			botao.add_theme_font_override("font", negrito)

# Editor com aparência de IDE: números de linha, cores de sintaxe Java
func _configurar_editor() -> void:
	code_edit.add_theme_stylebox_override("normal", _estilo_caixa(cor_fundo_codigo, 12, cor_borda, 1, 12))
	code_edit.add_theme_stylebox_override("focus", _estilo_caixa(cor_fundo_codigo, 12, cor_igual.darkened(0.2), 2, 12))
	code_edit.add_theme_font_size_override("font_size", 16)
	code_edit.add_theme_color_override("font_color", Color("#d7e4dc"))
	code_edit.add_theme_color_override("caret_color", cor_igual)
	code_edit.add_theme_color_override("current_line_color", Color(1, 1, 1, 0.05))
	code_edit.add_theme_color_override("line_number_color", Color("#4f6b5c"))
	code_edit.add_theme_color_override("selection_color", Color(0.24, 0.81, 0.56, 0.28))
	code_edit.gutters_draw_line_numbers = true
	code_edit.highlight_current_line = true
	code_edit.indent_automatic = true
	code_edit.caret_blink = true

	var cores := CodeHighlighter.new()
	cores.number_color = Color("#79c0ff")
	cores.symbol_color = Color("#c3d3ca")
	cores.function_color = Color("#d2a8ff")
	cores.member_variable_color = Color("#d7e4dc")

	for palavra in ["public", "class", "static", "void", "if", "else", "return", "new", "for", "while", "break", "continue"]:
		cores.add_keyword_color(palavra, Color("#ff7b72"))
	for tipo in ["int", "double", "float", "char", "boolean", "String"]:
		cores.add_keyword_color(tipo, Color("#ffa657"))
	for literal in ["true", "false", "null"]:
		cores.add_keyword_color(literal, Color("#79c0ff"))

	cores.add_color_region("//", "", Color("#6e8b7a"), true)
	cores.add_color_region("/*", "*/", Color("#6e8b7a"))
	cores.add_color_region("\"", "\"", Color("#a5d6a7"))

	code_edit.syntax_highlighter = cores

func _on_botao_voltar_pressed() -> void:
	GameManager.voltar_laboratorio()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		GameManager.voltar_laboratorio()
