
extends Node

# Sala padrão, configurável no Inspector do Autoload
@export_file("*.tscn") var laboratorio_path: String = ""

# Sala de onde o jogador entrou no minijogo
var sala_origem_path: String = ""

# Posição antes de entrar no jogo
var posicao_jogador: Vector2 = Vector2.ZERO
var posicao_salva: bool = false

# Minijogo aberto
var jogo_atual: String = ""

# Proteção contra entradas duplicadas
var em_transicao: bool = false


func abrir_jogo(
	cena_jogo: PackedScene,
	jogador: Node2D
) -> void:

	if em_transicao:
		return

	if cena_jogo == null or jogador == null:
		push_warning("Jogo ou jogador inválido.")
		return

	var cena_atual := get_tree().current_scene

	if cena_atual == null:
		push_warning("Cena atual não encontrada.")
		return

	var caminho_origem := cena_atual.scene_file_path

	if caminho_origem.is_empty():
		push_warning("A sala precisa estar salva como .tscn.")
		return

	var caminho_jogo := cena_jogo.resource_path

	if caminho_jogo.is_empty():
		push_warning("O minijogo precisa ser uma cena salva.")
		return

	sala_origem_path = caminho_origem
	posicao_jogador = jogador.global_position
	posicao_salva = true
	jogo_atual = caminho_jogo

	em_transicao = true

	var erro := get_tree().change_scene_to_packed(
		cena_jogo
	)

	if erro != OK:
		em_transicao = false
		push_error("Erro ao abrir minijogo: " + str(erro))
		return

	em_transicao = false



func voltar_laboratorio() -> void:
	if em_transicao:
		return

	var destino: String = sala_origem_path

	if destino.is_empty():
		destino = laboratorio_path

	if destino.is_empty():
		push_error("ERRO: Nenhuma sala de retorno configurada!")
		return

	em_transicao = true

	print("Retornando para: ", destino)

	var erro := get_tree().change_scene_to_file(destino)

	if erro != OK:
		em_transicao = false
		push_error("Erro ao voltar: " + str(erro))
		return

	jogo_atual = ""
	em_transicao = false


func limpar_retorno() -> void:
	sala_origem_path = ""
	posicao_salva = false
	jogo_atual = ""
