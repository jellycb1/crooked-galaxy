class_name SpeciesRules
extends RefCounted

# Initial identity roster. Species are permanently presentation-only: they may
# change portrait, emblem and narrative copy, but never combat or progression.
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
	{
		"id": "cellar_mycelian",
		"name": "Miceliano de Porão",
		"tagline": "Uma colônia de esporos com um casaco, uma licença duvidosa e excelente memória coletiva.",
		"identity": "FÚNGICO · COLETIVO",
		"color": "#ff7ad9",
		"prototype": true,
	},
	{
		"id": "rusted_ferrite",
		"name": "Ferrídeo Oxidado",
		"tagline": "Nasceu entre asteroides de ferro e considera ferrugem uma respeitável marca de maturidade.",
		"identity": "MINERAL · RESSONANTE",
		"color": "#ff8a4c",
		"prototype": true,
	},
	{
		"id": "tankborn_abyssal",
		"name": "Abissal de Tanque",
		"tagline": "Criado sob pressão, respira qualquer atmosfera desde que ninguém pergunte pela garantia.",
		"identity": "AQUÁTICO · ANFÍBIO",
		"color": "#46d9c8",
		"prototype": true,
	},
	{
		"id": "unstable_luminar",
		"name": "Luminar Instável",
		"tagline": "É feito de luz condensada; pisca quando mente e ilumina corredores sem cobrar adicional.",
		"identity": "ENERGÉTICO · PRISMÁTICO",
		"color": "#ffe66d",
		"prototype": true,
	},
	{
		"id": "catalog_chimera",
		"name": "Quimera de Catálogo",
		"tagline": "Encomendada por peças, montada sem manual e orgulhosamente fora do padrão de fábrica.",
		"identity": "HÍBRIDO · BIOENGENHADO",
		"color": "#f06d8f",
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
	var definition := get_definition(species_id)
	if definition.is_empty():
		return str(TranslationServer.translate("SPECIES_NONE"))
	var key := "SPECIES_%s_NAME" % species_id.to_upper()
	var translated := str(TranslationServer.translate(key))
	return str(definition.name) if translated == key else translated
