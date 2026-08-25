class_name SpeciesRules
extends RefCounted

# Provisional identity roster. Species are presentation-only until their
# mechanical contract has been balanced across every class and campaign route.
const DEFINITIONS := [
	{
		"id": "patched_terran",
		"name": "Terrano Remendado",
		"tagline": "Sobrevive por adaptação, fita industrial e uma confiança estatisticamente injustificada.",
		"identity": "ORGÂNICO · ADAPTÁVEL",
		"color": "#ffc857",
		"prototype": true,
	},
	{
		"id": "discontinued_synthetic",
		"name": "Sintético Descontinuado",
		"tagline": "O fabricante encerrou o suporte; felizmente também encerrou as limitações de garantia.",
		"identity": "SINTÉTICO · MODULAR",
		"color": "#55e5ff",
		"prototype": true,
	},
	{
		"id": "nebular_nomad",
		"name": "Nômade Nebular",
		"tagline": "Lê correntes cósmicas, maus contratos e salas onde ninguém pretende pagar.",
		"identity": "ALIENÍGENA · INTUITIVO",
		"color": "#b8f45d",
		"prototype": true,
	},
]


static func is_valid(species_id: String) -> bool:
	return not get_definition(species_id).is_empty()


static func get_definition(species_id: String) -> Dictionary:
	for definition in DEFINITIONS:
		if str(definition.id) == species_id:
			return definition.duplicate(true)
	return {}


static func species_name_for(species_id: String) -> String:
	return str(get_definition(species_id).get("name", "SEM RAÇA"))
