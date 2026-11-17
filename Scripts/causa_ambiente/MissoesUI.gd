extends CanvasLayer
## Interface global de missões (Autoload: Missoes).
## Também exibe uma conquista ao encontrar o Laboratório 1.
## Godot 4.7.

signal introducao_concluida
signal laboratorio_1_encontrado

@onready var escurecer: ColorRect = $Escurecer
@onready var inicio_container: CenterContainer = $InicioContainer
@onready var titulo: Label = $InicioContainer/InicioPanel/Margem/Conteudo/Titulo
@onready var descricao: Label = $InicioContainer/InicioPanel/Margem/Conteudo/Descricao
@onready var botao_comecar: Button = $InicioContainer/InicioPanel/Margem/Conteudo/BotaoComecar
@onready var objetivo_panel: PanelContainer = $ObjetivoPanel
@onready var texto_objetivo: Label = $ObjetivoPanel/Margem/TextoObjetivo

const OBJETIVO_INICIAL: String = "Siga para o Laboratório 1, que se encontra no Bloco B"
const OBJETIVO_LAB1: String = "Inicie os desafios do Laboratório 1"

var missao_atual: String = OBJETIVO_INICIAL
var partida_ativa: bool = false
var introducao_mostrada: bool = false
var introducao_pendente: bool = false
var lab1_ja_encontrado: bool = false

var _modo_janela: String = ""  # "", "introducao" ou "lab1"
var _cena_desafios_lab1: String = ""
var _pausou_por_tutorial: bool = false


func _ready() -> void:
	# A interface continua recebendo eventos com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ocultar_tudo()
	if not botao_comecar.pressed.is_connected(_on_botao_comecar):
		botao_comecar.pressed.connect(_on_botao_comecar)
	if not get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.connect(_on_scene_changed)


func iniciar_nova_partida() -> void:
	# Chamar SOMENTE no botão JOGAR do Menu.tscn.
	_liberar_pausa_do_tutorial()
	get_tree().paused = false
	partida_ativa = true
	introducao_mostrada = false
	introducao_pendente = true
	lab1_ja_encontrado = false
	missao_atual = OBJETIVO_INICIAL
	_cena_desafios_lab1 = ""
	_modo_janela = ""
	_atualizar_texto_objetivo()
	_ocultar_tudo()


func _on_scene_changed(_nova_cena: Node = null) -> void:
	var nova_cena: Node = _nova_cena
	if nova_cena == null:
		nova_cena = get_tree().current_scene
	if nova_cena == null:
		return

	if not partida_ativa:
		_ocultar_tudo()
		return

	# Não interfere em pop-ups ativos durante transições de cena.
	if _modo_janela == "lab1" and inicio_container.visible:
		return

	if introducao_pendente and not introducao_mostrada:
		if nova_cena.scene_file_path.get_file() == "unitins.tscn":
			introducao_pendente = false
			introducao_mostrada = true
			_mostrar_introducao()
		else:
			_ocultar_tudo()
		return

	_mostrar_objetivo()


func _mostrar_introducao() -> void:
	_modo_janela = "introducao"
	titulo.text = "BEM-VINDO À UNI ADVENTURE!"
	descricao.text = (
        "Prepare-se para explorar o ambiente universitario e "
		+ "realizar alguns mini games de Sistemas.\n\n"
		+ "MISSÃO 01: Siga para o Laboratório 1 e encontre os "
		+ "desafios."
	)
	botao_comecar.text = "COMEÇAR EXPLORAÇÃO"
	_mostrar_janela_pausando()


func encontrar_laboratorio_1(cena_desafios: String = "") -> bool:
	# Chamado pela Area2D na porta do Laboratório 1.
	# Retorna false se a mensagem já foi exibida nesta partida.
	if not partida_ativa or lab1_ja_encontrado:
		return false
	if introducao_pendente or _modo_janela != "":
		return false

	lab1_ja_encontrado = true
	_cena_desafios_lab1 = cena_desafios
	atualizar_objetivo(OBJETIVO_LAB1)
	_modo_janela = "lab1"

	titulo.text = "PARABÉNS!"
	descricao.text = (
        "Você encontrou o Laboratório 1!\n\n"
		+ "Muito bem, explorador! Agora é hora de colocar seus "
		+ "conhecimentos em prática e iniciar os desafios."
	)
	if cena_desafios.is_empty():
		botao_comecar.text = "CONTINUAR"
	else:
		botao_comecar.text = "INICIAR DESAFIOS"
	_mostrar_janela_pausando()
	laboratorio_1_encontrado.emit()
	return true


func _mostrar_janela_pausando() -> void:
	objetivo_panel.hide()
	escurecer.show()
	inicio_container.show()
	if not get_tree().paused:
		get_tree().paused = true
		_pausou_por_tutorial = true


func _on_botao_comecar() -> void:
	var era_lab1: bool = _modo_janela == "lab1"
	var proxima_cena: String = _cena_desafios_lab1

	_modo_janela = ""
	_liberar_pausa_do_tutorial()
	escurecer.hide()
	inicio_container.hide()
	_mostrar_objetivo()

	if era_lab1:
		_cena_desafios_lab1 = ""
		if not proxima_cena.is_empty():
			var erro: Error = get_tree().change_scene_to_file(proxima_cena)
			if erro != OK:
				push_error("Não foi possível abrir a cena dos desafios: " + proxima_cena)
		return

	introducao_concluida.emit()



func atualizar_objetivo(nova_missao: String) -> void:
	missao_atual = nova_missao
	_atualizar_texto_objetivo()

	if partida_ativa and not introducao_pendente and _modo_janela == "":
		_mostrar_objetivo()


func _mostrar_objetivo() -> void:
	escurecer.hide()
	inicio_container.hide()
	_atualizar_texto_objetivo()

	var cena_atual: Node = get_tree().current_scene

	if cena_atual == null:
		objetivo_panel.hide()
		return

	# Exibe a missão somente nas cenas autorizadas.
	var mostrar_hud: bool = cena_atual.is_in_group("com_hud_missao")

	objetivo_panel.visible = (
		partida_ativa
		and mostrar_hud
	)


func ocultar_objetivo() -> void:
	objetivo_panel.hide()


func voltar_ao_menu() -> void:
	_liberar_pausa_do_tutorial()
	get_tree().paused = false
	partida_ativa = false
	introducao_pendente = false
	_modo_janela = ""
	_cena_desafios_lab1 = ""
	_ocultar_tudo()


func _atualizar_texto_objetivo() -> void:
	texto_objetivo.text = "MISSÃO ATUAL: " + missao_atual


func _ocultar_tudo() -> void:
	escurecer.hide()
	inicio_container.hide()
	objetivo_panel.hide()


func _liberar_pausa_do_tutorial() -> void:
	if _pausou_por_tutorial:
		get_tree().paused = false
		_pausou_por_tutorial = false


func _exit_tree() -> void:
	_liberar_pausa_do_tutorial()
