class_name QuestionManager
extends RefCounted


var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func int_to_binary(value: int, minimum_bits: int = 1) -> String:
	var binary := String.num_int64(value, 2)

	while binary.length() < minimum_bits:
		binary = "0" + binary

	return binary


func generate_addition() -> Dictionary:
	var value_a := rng.randi_range(1, 15)
	var value_b := rng.randi_range(1, 15)

	var result := value_a + value_b

	var binary_a := int_to_binary(value_a, 4)
	var binary_b := int_to_binary(value_b, 4)

	var result_bits : int = max(
		4,
		int_to_binary(result).length()
	)

	var correct := int_to_binary(
		result,
		result_bits
	)

	var answers := generate_numeric_answers(
		result,
		result_bits
	)

	return {
		"type": "addition",
		"title": "ADIÇÃO BINÁRIA",

		"line_a": "  " + binary_a,
		"line_b": "+ " + binary_b,

		"correct_answer": correct,
		"answers": answers,

		"player_display": "%s + %s" % [
			binary_a,
			binary_b
		]
	}


func generate_numeric_answers(
	correct_value: int,
	bit_count: int
) -> Array[String]:

	var numeric_answers: Array[int] = []

	numeric_answers.append(correct_value)

	var variations: Array[int] = [
		1,
		-1,
		2,
		-2,
		3,
		-3,
		4,
		-4,
		8,
		-8
	]

	variations.shuffle()

	for variation in variations:
		if numeric_answers.size() >= 4:
			break

		var candidate := correct_value + variation

		if candidate < 0:
			continue

		if candidate in numeric_answers:
			continue

		numeric_answers.append(candidate)

	while numeric_answers.size() < 4:
		var candidate := rng.randi_range(
			0,
			max(31, correct_value + 10)
		)

		if candidate not in numeric_answers:
			numeric_answers.append(candidate)

	numeric_answers.shuffle()

	var answers: Array[String] = []

	for value in numeric_answers:
		answers.append(
			int_to_binary(
				value,
				bit_count
			)
		)

	return answers

func generate_subtraction() -> Dictionary:
	var value_a := rng.randi_range(5, 15)
	var value_b := rng.randi_range(1, value_a)

	var result := value_a - value_b

	var binary_a := int_to_binary(
		value_a,
		4
	)

	var binary_b := int_to_binary(
		value_b,
		4
	)

	var correct := int_to_binary(
		result,
		4
	)

	return {
		"type": "subtraction",
		"title": "SUBTRAÇÃO BINÁRIA",

		"line_a": "  " + binary_a,
		"line_b": "- " + binary_b,

		"correct_answer": correct,

		"answers":
			generate_numeric_answers(
				result,
				4
			),

		"player_display":
			"%s - %s" % [
				binary_a,
				binary_b
			]
	}
	

func generate_multiplication() -> Dictionary:
	var value_a := rng.randi_range(
		1,
		7
	)

	var value_b := rng.randi_range(
		1,
		7
	)

	var result := value_a * value_b

	var binary_a := int_to_binary(
		value_a,
		3
	)

	var binary_b := int_to_binary(
		value_b,
		3
	)

	var result_bits :int = max(
		4,
		int_to_binary(result).length()
	)

	var correct := int_to_binary(
		result,
		result_bits
	)

	return {
		"type": "multiplication",

		"title":
			"MULTIPLICAÇÃO BINÁRIA",

		"line_a":
			"  " + binary_a,

		"line_b":
			"× " + binary_b,

		"correct_answer":
			correct,

		"answers":
			generate_numeric_answers(
				result,
				result_bits
			),

		"player_display":
			"%s × %s" % [
				binary_a,
				binary_b
			]
	}
	

func generate_question(
	difficulty: int
) -> Dictionary:

	match difficulty:

		1:
			return generate_addition()

		2:
			var options := [
				"addition",
				"subtraction"
			]

			var selected: String = \
				options.pick_random()

			if selected == "subtraction":
				return generate_subtraction()

			return generate_addition()

		_:
			var options := [
				"addition",
				"subtraction",
				"multiplication"
			]

			match options.pick_random():
				"subtraction":
					return generate_subtraction()

				"multiplication":
					return generate_multiplication()

				_:
					return generate_addition()
