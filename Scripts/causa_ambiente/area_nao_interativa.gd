extends Area2D

# Permite alterar os textos diretamente no Inspetor para cada porta/área
@export var nome_do_local: String = "Bloco C"
@export var mensagem_aviso: String = "Área não disponível no momento."

# Se verdadeiro, precisa apertar botão de interação; se falso, aparece só de encostar
@export var exigir_botao: bool = false
@export var acao_interagir: String = "ui_accept" # Troque pelo nome do seu Input (ex: "interagir")

@onready var indicador: Node2D = $Indicador
@onready var label_informacao: Label = $"Indicador/Informação"
@onready var label_local: Label = $Indicador/Local

var jogador_na_area: bool = false

func _ready() -> void:
	# Atualiza os textos com os valores definidos no Inspetor
	label_informacao.text = mensagem_aviso
	label_local.text = nome_do_local
	
	# Garante que o aviso comece invisível no jogo
	indicador.visible = false
	
	# Conecta os sinais de entrada e saída via código (evita esquecer de conectar no editor)
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

func _ao_entrar(body: Node2D) -> void:
	# Verifica se quem entrou foi o jogador (ajuste se seu Player não usar o grupo "player")
	if body.is_in_group("player") or body.name == "Player":
		jogador_na_area = true
		if not exigir_botao:
			indicador.visible = true

func _ao_sair(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		jogador_na_area = false
		indicador.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# Se você ativar 'exigir_botao' no Inspetor, o texto aparece ao apertar a tecla perto da porta
	if exigir_botao and jogador_na_area and event.is_action_pressed(acao_interagir):
		indicador.visible = !indicador.visible
