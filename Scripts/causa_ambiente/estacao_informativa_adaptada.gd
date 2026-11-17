extends Area2D

# Integração opcional: conecte este sinal ao fluxo de abertura do GameManager.
signal jogar_solicitado(cena: PackedScene)

const ACAO_INFO: StringName = &"information"
const ACAO_INTERAGIR: StringName = &"interact"
const ACAO_SAIR: StringName = &"Sair"
## Estação reutilizável de inspeção e acesso a minijogos (Godot 4.x).
## Use com EstacaoInformativa.tscn. O jogador precisa estar no grupo "player" ou "jogador".

@export_group("Minijogo")
@export var nome_jogo: String = "Minijogo"
@export var cena_jogo: PackedScene
@export var categoria: String = "ESTAÇÃO DE APRENDIZADO"
# Ativo: o PC original continua responsável pela entrada no jogo.
@export var somente_inspecao: bool = true

@export_group("Conteúdo da inspeção")
@export_multiline var descricao: String = "Aprenda conceitos de arquitetura de computadores em uma missão interativa."
@export_multiline var objetivo: String = "Conclua o desafio proposto pela estação."
@export_multiline var instrucoes: String = "1. Leia o desafio na tela.\n2. Interaja com os elementos da atividade.\n3. Conclua a missão para vencer."
@export_multiline var dica: String = "Observe as pistas antes de responder."

@onready var nome_placa: Label = $Placa/Margem/Coluna/Cabecalho/Titulos/Nome
@onready var tipo_placa: Label = $Placa/Margem/Coluna/Cabecalho/Titulos/Tipo
@onready var emblema: PanelContainer = $Placa/Margem/Coluna/Cabecalho/Emblema
@onready var indicador: PanelContainer = $Indicador
@onready var texto_indicador: Label = $Indicador/Texto
@onready var tela: Control = $Interface/Tela
@onready var titulo_popup: Label = $Interface/Tela/Cartao/Margem/Conteudo/Titulo
@onready var descricao_popup: Label = $Interface/Tela/Cartao/Margem/Conteudo/Descricao
@onready var objetivo_popup: Label = $Interface/Tela/Cartao/Margem/Conteudo/Objetivo
@onready var instrucoes_popup: Label = $Interface/Tela/Cartao/Margem/Conteudo/Instrucoes
@onready var dica_popup: Label = $Interface/Tela/Cartao/Margem/Conteudo/Dica
@onready var botao_fechar: Button = $Interface/Tela/Cartao/Margem/Conteudo/Acoes/Fechar
@onready var botao_jogar: Button = $Interface/Tela/Cartao/Margem/Conteudo/Acoes/Jogar

var jogador_proximo: bool = false
var inspecao_aberta: bool = false
var fase_pulso: float = 0.0

func _ready() -> void:
	indicador.hide()
	tela.hide()
	_atualizar_informacoes()
	for acao in [ACAO_INFO, ACAO_INTERAGIR, ACAO_SAIR]:
		if not InputMap.has_action(acao):
			push_warning("Configure a ação no Input Map: %s" % acao)

	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	botao_fechar.pressed.connect(_fechar_inspecao)
	botao_jogar.pressed.connect(_iniciar_minijogo)

func _process(delta: float) -> void:
	# Brilho discreto do ícone "i" na placa, sem imagem externa.
	fase_pulso += delta * 2.8
	emblema.modulate.a = 0.84 + 0.16 * (0.5 + 0.5 * sin(fase_pulso))

func _atualizar_informacoes() -> void:
	nome_placa.text = nome_jogo
	tipo_placa.text = categoria.to_upper()
	titulo_popup.text = nome_jogo
	descricao_popup.text = descricao
	objetivo_popup.text = objetivo
	instrucoes_popup.text = instrucoes
	dica_popup.text = dica
	texto_indicador.text = "[ I ] INSPECIONAR"
	botao_jogar.visible = not somente_inspecao
	botao_jogar.disabled = cena_jogo == null or not jogar_solicitado.has_connections()
	if not somente_inspecao:
		if cena_jogo == null:
			botao_jogar.text = "JOGO NÃO CONFIGURADO"
		elif not jogar_solicitado.has_connections():
			botao_jogar.text = "CONECTE O GERENCIADOR"
		else:
			botao_jogar.text = "INICIAR MISSÃO  >"
			texto_indicador.text = "[ I ] INSPECIONAR    •    [ E ] JOGAR"

func _eh_jogador(corpo: Node2D) -> bool:
	return corpo.is_in_group("player") or corpo.is_in_group("jogador")

func _ao_entrar(corpo: Node2D) -> void:
	if not _eh_jogador(corpo):
		return
	jogador_proximo = true
	if not inspecao_aberta:
		indicador.show()

func _ao_sair(corpo: Node2D) -> void:
	if not _eh_jogador(corpo):
		return
	jogador_proximo = false
	_fechar_inspecao()
	indicador.hide()

func _input(event: InputEvent) -> void:
	if not jogador_proximo and not inspecao_aberta:
		return
	if event.is_echo():
		return

	if _acao_pressionada(event, ACAO_INFO):
		get_viewport().set_input_as_handled()
		if inspecao_aberta:
			_fechar_inspecao()
		else:
			_abrir_inspecao()
		return

	if inspecao_aberta:
		if _acao_pressionada(event, ACAO_SAIR):
			get_viewport().set_input_as_handled()
			_fechar_inspecao()
		elif _acao_pressionada(event, ACAO_INTERAGIR):
			# Evita que a estação inicie um jogo durante a leitura.
			get_viewport().set_input_as_handled()
		return

	# No modo de inspeção o PC original recebe a ação interact.
	if somente_inspecao:
		return

	if jogador_proximo and _acao_pressionada(event, ACAO_INTERAGIR):
		# Espaço também está associado a jump no projeto.
		if event is InputEventKey and (event.physical_keycode == KEY_SPACE or event.keycode == KEY_SPACE):
			return
		get_viewport().set_input_as_handled()
		_iniciar_minijogo()

func _acao_pressionada(event: InputEvent, acao: StringName) -> bool:
	return InputMap.has_action(acao) and event.is_action_pressed(acao)

func _abrir_inspecao() -> void:
	if not jogador_proximo:
		return
	_atualizar_informacoes()
	inspecao_aberta = true
	tela.show()
	indicador.hide()

func _fechar_inspecao() -> void:
	inspecao_aberta = false
	tela.hide()
	indicador.visible = jogador_proximo

func _iniciar_minijogo() -> void:
	if somente_inspecao:
		return
	if cena_jogo == null:
		push_warning("Configure Cena Jogo na estação '%s'." % nome_jogo)
		return
	if not jogar_solicitado.has_connections():
		push_warning("Conecte jogar_solicitado ao fluxo de abertura do GameManager.")
		return
	_fechar_inspecao()
	jogar_solicitado.emit(cena_jogo)
