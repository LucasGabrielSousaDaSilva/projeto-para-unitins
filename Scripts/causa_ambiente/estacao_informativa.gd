extends Area2D
## Estação reutilizável de inspeção e acesso a minijogos (Godot 4.x).
## Use com EstacaoInformativa.tscn. O jogador precisa estar no grupo "player" ou "jogador".

@export_group("Minijogo")
@export var nome_jogo: String = "Minijogo"
@export var cena_jogo: PackedScene
@export var categoria: String = "ESTAÇÃO DE APRENDIZADO"

@export_group("Conteúdo da inspeção")
@export_multiline var descricao: String = "Aprenda conceitos de arquitetura de computadores em uma missão interativa."
@export_multiline var objetivo: String = "Conclua o desafio proposto pela estação."
@export_multiline var instrucoes: String = "1. Leia o desafio na tela.\n2. Interaja com os elementos da atividade.\n3. Conclua a missão para vencer."
@export_multiline var dica: String = "Observe as pistas antes de responder."

@onready var nome_placa: Label = $Placa/Margem/Coluna/Cabecalho/Titulos/Nome
@onready var tipo_placa: Label = $Placa/Margem/Coluna/Cabecalho/Titulos/Tipo
@onready var emblema: PanelContainer = $Placa/Margem/Coluna/Cabecalho/Emblema
@onready var indicador: PanelContainer = $Indicador
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
	botao_jogar.disabled = (cena_jogo == null)
	if cena_jogo == null:
		botao_jogar.text = "JOGO NÃO CONFIGURADO"
	else:
		botao_jogar.text = "INICIAR MISSÃO  >"

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

	if event.is_action_pressed("information") and not event.is_echo():
		if inspecao_aberta:
			_fechar_inspecao()
		else:
			_abrir_inspecao()
		get_viewport().set_input_as_handled()
		return

	if inspecao_aberta and event.is_action_pressed("ui_cancel") and not event.is_echo():
		_fechar_inspecao()
		get_viewport().set_input_as_handled()
		return

	if jogador_proximo and not inspecao_aberta and event.is_action_pressed("interagir") and not event.is_echo():
		_iniciar_minijogo()
		get_viewport().set_input_as_handled()

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
	if cena_jogo == null:
		push_warning("A estação '%s' está sem Cena Jogo configurada no Inspetor." % nome_jogo)
		return
	var erro: Error = get_tree().change_scene_to_packed(cena_jogo)
	if erro != OK:
		push_error("Não foi possível abrir '%s'. Código: %s" % [nome_jogo, erro])
