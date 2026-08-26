class_name SpeciesRules
extends RefCounted

# The launch roster is presentation-only. Species never grant combat or
# progression bonuses; each one exists to support a distinct visual fantasy.
const DEFINITIONS := [
	{"id": "terran", "name": "Terrano", "tagline": "Humanos espalhados pela galáxia, especialistas em sobreviver com equipamento remendado.", "identity": "ORGÂNICO · ADAPTÁVEL", "color": "#ffc857", "prototype": false},
	{"id": "synthetic", "name": "Sintético", "tagline": "Corpos modulares que continuaram a evoluir muito depois do fim da garantia.", "identity": "SINTÉTICO · MODULAR", "color": "#55e5ff", "prototype": false},
	{"id": "starworn", "name": "Astrerrante", "tagline": "Viajantes esguios marcados por rotas estelares que só eles conseguem ler.", "identity": "CÓSMICO · INTUITIVO", "color": "#b8f45d", "prototype": false},
	{"id": "fungoid", "name": "Fungoide", "tagline": "Colónias conscientes que usam um único corpo, muitas memórias e excelentes casacos.", "identity": "FÚNGICO · COLETIVO", "color": "#ff7ad9", "prototype": false},
	{"id": "abyssal", "name": "Abissal", "tagline": "Anfíbios de mundos oceânicos, criados sob uma pressão capaz de esmagar cargueiros.", "identity": "AQUÁTICO · ANFÍBIO", "color": "#46d9c8", "prototype": false},
	{"id": "mothari", "name": "Mothari", "tagline": "Navegadores noturnos de olhos enormes, antenas sensíveis e mantos iridescentes.", "identity": "ALADO · NOTURNO", "color": "#ff8a4c", "prototype": false},
	{"id": "scraproot", "name": "Raiz-de-Sucata", "tagline": "Flora ambulante que enxerta metal recuperado onde outras espécies usariam armadura.", "identity": "BOTÂNICO · ENXERTADO", "color": "#72d572", "prototype": false},
	{"id": "glitchlight", "name": "Luz-Defeituosa", "tagline": "Entidades de energia condensada que piscam, fragmentam e recusam ficar quietas.", "identity": "ENERGÉTICO · PRISMÁTICO", "color": "#ffe66d", "prototype": false},
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
