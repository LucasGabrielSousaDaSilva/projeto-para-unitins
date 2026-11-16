extends RefCounted
## Simulação da hierarquia de memória do Cache Rush.
##
## Cada nível guarda "linhas" (aqui, um endereço de 0x00 a 0xFF).
## - Busca: a CPU consulta do nível mais rápido para o mais lento.
## - Hit: o dado foi achado; ele é copiado para todos os níveis acima
##   (cache fill), trocando a linha menos usada (LRU) se o nível estiver cheio.
## - O armazenamento (SSD) contém todos os endereços, então sempre dá hit.

const NAMES: Array = ["REGISTRADORES", "CACHE L1", "CACHE L2", "CACHE L3", "RAM", "ARMAZENAMENTO"]
const SHORT: Array = ["REG", "L1", "L2", "L3", "RAM", "SSD"]
## Quantas linhas cada nível mostra/guarda (0 = guarda tudo)
const CAPACITY: Array = [4, 6, 8, 12, 12, 0]
## Latência aproximada em ciclos de CPU
const CYCLES: Array = [1, 4, 12, 40, 200, 100000]
const LEVELS := 6
const SSD := 5

## slots[nivel] = Array de tags (-1 = linha vazia)
var slots: Array = []
## stamp[nivel] = Array com o "relógio" do último uso de cada linha (para o LRU)
var stamp: Array = []
var clock: int = 0
var last_request: int = -1


func reset() -> void:
	clock = 0
	last_request = -1
	slots.clear()
	stamp.clear()
	for level in range(LEVELS):
		var n: int = CAPACITY[level]
		var s: Array = []
		var t: Array = []
		for k in range(n):
			s.append(-1)
			t.append(0)
		slots.append(s)
		stamp.append(t)

	# Estado inicial: cada nível guarda um subconjunto do nível de baixo.
	var ram_tags: Array = []
	while ram_tags.size() < int(CAPACITY[4]):
		var v: int = randi_range(0, 255)
		if not ram_tags.has(v):
			ram_tags.append(v)
	var l3_tags: Array = _sample(ram_tags, 8)
	var l2_tags: Array = _sample(l3_tags, 5)
	var l1_tags: Array = _sample(l2_tags, 3)
	var reg_tags: Array = _sample(l1_tags, 1)
	_seed(4, ram_tags)
	_seed(3, l3_tags)
	_seed(2, l2_tags)
	_seed(1, l1_tags)
	_seed(0, reg_tags)


func _sample(src: Array, n: int) -> Array:
	var c: Array = src.duplicate()
	c.shuffle()
	return c.slice(0, mini(n, c.size()))


func _seed(level: int, tags: Array) -> void:
	for tag in tags:
		fill(level, tag)


func has(level: int, tag: int) -> bool:
	if level == SSD:
		return true
	return slots[level].has(tag)


func slot_of(level: int, tag: int) -> int:
	if level == SSD:
		return -1
	return slots[level].find(tag)


func touch(level: int, tag: int) -> void:
	var idx: int = slot_of(level, tag)
	if idx >= 0:
		clock += 1
		stamp[level][idx] = clock


## Linha menos recentemente usada. Só existe candidata a saída se o nível
## estiver cheio (senão uma linha vazia seria usada). Retorna -1 se não houver.
func lru_slot(level: int) -> int:
	if level == SSD:
		return -1
	if slots[level].has(-1):
		return -1
	return _oldest(level)


func _oldest(level: int) -> int:
	var best: int = 0
	var best_stamp: int = 1 << 60
	for i in range(slots[level].size()):
		if int(stamp[level][i]) < best_stamp:
			best_stamp = stamp[level][i]
			best = i
	return best


## Copia a tag para o nível. Retorna {"slot": linha usada, "evicted": tag que saiu (-1 se nenhuma)}.
func fill(level: int, tag: int) -> Dictionary:
	if level == SSD:
		return {"slot": -1, "evicted": -1}
	clock += 1
	var idx: int = slots[level].find(tag)
	if idx >= 0:
		stamp[level][idx] = clock
		return {"slot": idx, "evicted": -1}
	var evicted: int = -1
	idx = slots[level].find(-1)
	if idx < 0:
		idx = _oldest(level)
		evicted = slots[level][idx]
	slots[level][idx] = tag
	stamp[level][idx] = clock
	return {"slot": idx, "evicted": evicted}


## Tags que estão no nível mas em nenhum nível mais rápido.
func _exclusive(level: int) -> Array:
	var out: Array = []
	for tag in slots[level]:
		if tag < 0:
			continue
		var faster := false
		for l in range(level):
			if slots[l].has(tag):
				faster = true
				break
		if not faster:
			out.append(tag)
	return out


func _hot() -> Array:
	var out: Array = []
	for l in [0, 1]:
		for tag in slots[l]:
			if tag >= 0 and not out.has(tag):
				out.append(tag)
	return out


## Sorteia o próximo endereço pedido pela CPU, com localidade:
## muitos pedidos repetem dados recentes (ficam rápidos), outros descem
## até a RAM ou o armazenamento.
func next_request() -> int:
	var roll: float = randf()
	var cand: Array = []
	if roll < 0.34:
		cand = _hot()
	elif roll < 0.54:
		cand = _exclusive(2)
	elif roll < 0.70:
		cand = _exclusive(3)
	elif roll < 0.89:
		cand = _exclusive(4)

	var tag: int = -1
	var filtered: Array = cand.duplicate()
	filtered.erase(last_request)
	if not filtered.is_empty():
		tag = filtered[randi() % filtered.size()]
	else:
		# endereço novo: não está em nenhum cache nem na RAM (vem do armazenamento)
		for _i in range(60):
			var v: int = randi_range(0, 255)
			if v != last_request and not slots[4].has(v):
				tag = v
				break
		if tag < 0:
			tag = randi_range(0, 255)
	last_request = tag
	return tag
