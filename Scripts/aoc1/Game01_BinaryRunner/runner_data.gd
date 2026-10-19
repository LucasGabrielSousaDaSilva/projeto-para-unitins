extends RefCounted
## Fonte única das perguntas para todas as fases. Altere aqui os desafios.

static func get_mission(phase: int) -> Dictionary:
	match phase:
		1:
			return {
				"title": "FASE 1 — FUGA DOS BITS",
				"objective": "Monte 10 decimal usando 4 bits.",
				"mode": "bits",
				"prompts": ["PESO 8", "PESO 4", "PESO 2", "PESO 1"],
				"answers": ["1", "0", "1", "0"],
				"success": "1010₂ = 8 + 2 = 10₁₀. Primeira fase concluída!",
				"teaching": "10 decimal é 1010 binário (pesos 8, 4, 2, 1)."
			}
		2:
			return {
				"title": "FASE 2 — BYTE E AGRUPAMENTOS",
				"objective": "Forme o byte 01001011 (75 decimal).",
				"mode": "bits",
				"prompts": ["128", "64", "32", "16", "8", "4", "2", "1"],
				"answers": ["0", "1", "0", "0", "1", "0", "1", "1"],
				"success": "0100 1011₂ = 75₁₀. 8 bits formam 1 byte; dois grupos de 4 bits são nibbles!",
				"teaching": "1 byte = 8 bits. Os nibbles 0100 e 1011 equivalem a 4 e B hexadecimal."
			}
		3:
			return {
				"title": "FASE 3 — BINÁRIO ↔ DECIMAL",
				"objective": "Converta as 4 representações entre bases 2 e 10.",
				"mode": "choices",
				"prompts": ["10110₂ → ?₁₀", "13₁₀ → ?₂", "100101₂ → ?₁₀", "26₁₀ → ?₂"],
				"answers": ["22", "1101", "37", "11010"],
				"options": [["23", "22"], ["1101", "1110"], ["35", "37"], ["11010", "10110"]],
				"success": "Muito bem! Você converteu binário ↔ decimal nos dois sentidos.",
				"teaching": "Ex.: 10110₂ = 16 + 4 + 2 = 22₁₀."
			}
		4:
			return {
				"title": "FASE 4 — PORTÕES HEXADECIMAIS",
				"objective": "Resolva 4 conversões envolvendo a base 16.",
				"mode": "choices",
				"prompts": ["10₁₀ → ?₁₆", "1111₂ → ?₁₆", "2A₁₆ → ?₁₀", "31₁₀ → ?₁₆"],
				"answers": ["A", "F", "42", "1F"],
				"options": [["A", "B"], ["E", "F"], ["44", "42"], ["1F", "2F"]],
				"success": "Base 16 dominada: A=10, F=15 e 2A₁₆=42₁₀!",
				"teaching": "Hexadecimal usa 0–9 e A–F. Cada dígito equivale a 4 bits."
			}
		5:
			return {
				"title": "BOSS — NÚCLEO FIREWALL",
				"objective": "Responda a 6 conversões seguidas para liberar o núcleo.",
				"mode": "choices",
				"prompts": ["1010₂ → ?₁₀", "31₁₀ → ?₂", "2D₁₆ → ?₁₀", "63₁₀ → ?₁₆", "101111₂ → ?₁₆", "17₈ → ?₁₀"],
				"answers": ["10", "11111", "45", "3F", "2F", "15"],
				"options": [["10", "12"], ["11111", "11110"], ["43", "45"], ["3F", "4F"], ["3F", "2F"], ["15", "17"]],
				"success": "FIREWALL SUPERADO! Você concluiu todas as conversões e escapou do computador!",
				"teaching": "Revise bases 2, 8, 10 e 16; converta sempre mantendo o mesmo valor."
			}
	return {}
