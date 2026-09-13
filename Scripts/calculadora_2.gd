extends Control

# --- REFERÊNCIAS DOS NÓS DA INTERFACE ---
@onready var code_edit: CodeEdit = $CodeEdit
@onready var btn_enviar: Button = $Button
@onready var visor_operacao: LineEdit = $VBoxContainer/VisorOperacao
@onready var visor_resultado: LineEdit = $VBoxContainer/VisorResultado
@onready var grid_botoes: GridContainer = $VBoxContainer/GridContainer
@onready var conclusao: RichTextLabel = $Conclusao

# --- VARIÁVEIS DE ESTADO ---
var primeiro_numero: float = 0.0
var segundo_numero: float = 0.0
var operador: String = ""
var nova_entrada: bool = true

# Permissões ativadas SOMENTE se o aluno programar no CodeEdit
var permite_numeros: bool = false
var permite_operadores: bool = false
var permite_calcular: bool = false
var permite_limpar: bool = false
var permite_ponto: bool = false

func _ready():
	_carregar_template_java()
	
	if btn_enviar:
		btn_enviar.pressed.connect(_on_enviar_codigo)
	
	for botao in grid_botoes.get_children():
		if botao is Button:
			botao.pressed.connect(_on_botao_calculadora_pressionado.bind(botao.text))

# Carrega a estrutura de classe Java no estilo da sua imagem
func _carregar_template_java():
	var template = """public class Calculadora {
    public static void main(String[] args) {

        // Escreva aqui a lógica dos botões da calculadora

    }
}"""
	code_edit.text = template

# Botão "Enviar": Lê o código do aluno
func _on_enviar_codigo():
	var codigo_aluno = code_edit.text
	_analisar_codigo_java(codigo_aluno)
	_limpar_tudo()

# --- ANALISADOR DO CÓDIGO JAVA ---
func _analisar_codigo_java(texto: String):
	permite_numeros = false
	permite_operadores = false
	permite_calcular = false
	permite_limpar = false
	permite_ponto = false

	# Validações dos blocos Java escritos pelo aluno
	if "matches(\"[0-9]\")" in texto or "adicionarNumero" in texto:
		permite_numeros = true

	if "definirOperador" in texto or ("equals(\"+\")" in texto or "equals(\"-\")" in texto):
		permite_operadores = true

	if "calcular" in texto or "equals(\"=\")" in texto:
		permite_calcular = true

	if "limpar" in texto or "equals(\"AC\")" in texto or "equals(\"C\")" in texto:
		permite_limpar = true

	if "adicionarPonto" in texto or "equals(\".\")" in texto:
		permite_ponto = true

	if conclusao:
		if permite_numeros and permite_operadores and permite_calcular:
			conclusao.text = "[color=green]Código Compilado com Sucesso! Calculadora Ativa.[/color]"
		elif permite_numeros or permite_operadores or permite_calcular or permite_limpar:
			conclusao.text = "[color=yellow]Código Parcialmente Aplicado! Algumas funções ainda estão bloqueadas.[/color]"
		else:
			conclusao.text = "[color=red]Aviso: Escreva o código dentro do main e clique em Enviar.[/color]"

# Executado ao clicar nos botões da interface
func _on_botao_calculadora_pressionado(comando: String):
	if comando.is_valid_int():
		if permite_numeros:
			_adicionar_numero(comando)
		else:
			_mostrar_erro("Erro: Tratamento de NÚMEROS [0-9] não programado!")

	elif comando == ".":
		if permite_ponto:
			_adicionar_ponto()
		else:
			_mostrar_erro("Erro: Lógica do PONTO (.) não programada!")

	elif comando in ["+", "-", "×", "÷", "*", "/"]:
		if permite_operadores:
			_definir_operador(comando)
		else:
			_mostrar_erro("Erro: Lógica dos OPERADORES não programada!")

	elif comando == "=":
		if permite_calcular:
			_calcular_resultado()
		else:
			_mostrar_erro("Erro: Lógica do IGUAL (=) não programada!")

	elif comando in ["AC", "C"]:
		if permite_limpar:
			_limpar_tudo()
		else:
			_mostrar_erro("Erro: Lógica de LIMPAR (AC) não programada!")

func _mostrar_erro(mensagem: String):
	if conclusao:
		conclusao.text = "[color=red]" + mensagem + "[/color]"

func _adicionar_numero(num: String):
	if nova_entrada or visor_resultado.text == "0":
		visor_resultado.text = num
		nova_entrada = false
	else:
		visor_resultado.text += num

func _adicionar_ponto():
	if nova_entrada:
		visor_resultado.text = "0."
		nova_entrada = false
	elif not "." in visor_resultado.text:
		visor_resultado.text += "."

func _definir_operador(op: String):
	primeiro_numero = visor_resultado.text.to_float()
	operador = op
	visor_operacao.text = _formatar_numero(primeiro_numero) + " " + operador
	nova_entrada = true

func _calcular_resultado():
	if operador == "":
		return
		
	segundo_numero = visor_resultado.text.to_float()
	var resultado: float = 0.0
	
	match operador:
		"+": resultado = primeiro_numero + segundo_numero
		"-": resultado = primeiro_numero - segundo_numero
		"×", "*": resultado = primeiro_numero * segundo_numero
		"÷", "/":
			if segundo_numero == 0.0:
				visor_resultado.text = "Erro"
				visor_operacao.text = "Não é possível dividir por zero"
				nova_entrada = true
				return
			else:
				resultado = primeiro_numero / segundo_numero
	
	visor_operacao.text = _formatar_numero(primeiro_numero) + " " + operador + " " + _formatar_numero(segundo_numero) + " ="
	visor_resultado.text = _formatar_numero(resultado)
	
	primeiro_numero = resultado
	operador = ""
	nova_entrada = true

func _limpar_tudo():
	primeiro_numero = 0.0
	segundo_numero = 0.0
	operador = ""
	visor_operacao.text = ""
	visor_resultado.text = "0"
	nova_entrada = true

func _formatar_numero(num: float) -> String:
	if num == int(num):
		return str(int(num))
	return str(num)
