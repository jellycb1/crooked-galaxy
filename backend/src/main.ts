const CG_API_VERSION = 1;
const CG_SHARD_ID = "international_1";
const CHARACTER_COLLECTION = "cg_characters_v1";
const CHARACTER_KEY = "primary";
const RECEIPT_COLLECTION = "cg_command_receipts_v1";
const AGENCY_GUARD_COLLECTION = "cg_agency_guard_v1";
const AGENCY_GUARD_KEY = "membership";
const AGENCY_GUARD_LEASE_MS = 30000;
const AGENCY_SCHEMA_VERSION = 1;
const AGENCY_MEMBER_LIMIT = 25;
const ATTRIBUTE_KEYS = ["strength", "vitality", "dexterity", "intelligence", "cunning"];
const EQUIPMENT_SLOTS = ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"];

const CLASS_IDS: {[key: string]: boolean} = {warrant_breaker: true, orbit_gunslinger: true, contract_hacker: true};
const SPECIES_IDS: {[key: string]: boolean} = {terran: true, synthetic: true, starworn: true, fungoid: true, abyssal: true, mothari: true, scraproot: true, glitchlight: true};
const APPEARANCE_OPTIONS: {[key: string]: {[key: string]: boolean}} = {
  palette: {native: true, warm: true, cool: true},
  eyes: {standard: true, wide: true, narrow: true},
  feature: {classic: true, bold: true, subtle: true},
  marking: {clean: true, stripe: true, spots: true}
};

interface CharacterProfile {
  character_id: string; hunter_name: string; class_id: string; species_id: string;
  appearance: {[key: string]: string}; level: number; xp: number; credits: number; warp_chips: number; scrap: number;
  fuel?: number; max_fuel?: number; fuel_day_id?: number; wins?: number; inventory_revision?: number; inventory_count?: number;
  active_hunt?: {[key: string]: any}; pending_reward?: {[key: string]: any};
  base_power?: number; attributes?: {[key: string]: number}; stat_points?: number;
  equipment?: {[key: string]: {[key: string]: any}}; inventory?: any[];
}
interface StoredCharacter {
  api_version: number; account_id: string; character_id: string; shard_id: string; revision: number; profile: CharacterProfile;
}

function requireUser(context: nkruntime.Context): string {
  if (!context.userId) throw Error("Authenticated session required.");
  return context.userId;
}

function parsePayload(payload: string): {[key: string]: any} {
  if (!payload) return {};
  if (payload.length > 4096) throw Error("Payload exceeds the protocol limit.");
  const parsed = JSON.parse(payload);
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw Error("Object payload required.");
  return parsed;
}

function validIdentifier(value: any): boolean { return typeof value === "string" && /^[a-z0-9._-]{1,128}$/.test(value); }

function validHunterName(value: any): boolean {
  if (typeof value !== "string" || value.length < 3 || value.length > 20 || value !== value.trim()) return false;
  for (let index = 0; index < value.length; index++) {
    const code = value.charCodeAt(index);
    if (code < 32 || code === 127 || value.charAt(index) === "<" || value.charAt(index) === ">") return false;
  }
  return true;
}

function canonicalAppearance(value: any): {[key: string]: string} | null {
  if (!value || typeof value !== "object" || Array.isArray(value) || Object.keys(value).length !== 4) return null;
  const clean: {[key: string]: string} = {};
  const categories = ["palette", "eyes", "feature", "marking"];
  for (let index = 0; index < categories.length; index++) {
    const category = categories[index];
    const option = value[category];
    if (typeof option !== "string" || !APPEARANCE_OPTIONS[category][option]) return null;
    clean[category] = option;
  }
  return clean;
}

function readCharacter(nk: nkruntime.Nakama, userId: string): nkruntime.StorageObject | null {
  const objects = nk.storageRead([{collection: CHARACTER_COLLECTION, key: CHARACTER_KEY, userId: userId}]);
  return objects.length === 1 ? objects[0] : null;
}

function validNonnegativeInteger(value: any): boolean {
  return typeof value === "number" && value >= 0 && Math.floor(value) === value;
}

function validServerItem(value: any, expectedSlot?: string): boolean {
  if (!value || typeof value !== "object" || Array.isArray(value) || !validIdentifier(value.id) || EQUIPMENT_SLOTS.indexOf(value.slot) < 0) return false;
  if (expectedSlot && value.slot !== expectedSlot) return false;
  if (!validNonnegativeInteger(value.power) || typeof value.origin_planet_id !== "string") return false;
  if (typeof value.item_level !== "undefined" && !validNonnegativeInteger(value.item_level)) return false;
  if (typeof value.integrity_upgrades !== "undefined" && !validNonnegativeInteger(value.integrity_upgrades)) return false;
  if (typeof value.trait !== "undefined" && (!value.trait || typeof value.trait !== "object" || Array.isArray(value.trait))) return false;
  if (typeof value.attribute_package_id !== "undefined" && typeof value.attribute_package_id !== "string") return false;
  return true;
}

function validStoredCharacter(value: any, expectedUserId: string): boolean {
  if (!value || typeof value !== "object" || value.api_version !== CG_API_VERSION || value.account_id !== expectedUserId || value.character_id !== expectedUserId || value.shard_id !== CG_SHARD_ID || !validNonnegativeInteger(value.revision)) return false;
  const profile = value.profile;
  const profileSize = profile && typeof profile === "object" ? Object.keys(profile).length : 0;
  if (!profile || typeof profile !== "object" || (profileSize !== 10 && profileSize !== 18 && profileSize !== 23) || profile.character_id !== expectedUserId || !validHunterName(profile.hunter_name) || !CLASS_IDS[profile.class_id] || !SPECIES_IDS[profile.species_id] || !canonicalAppearance(profile.appearance)) return false;
  if (!validNonnegativeInteger(profile.level) || profile.level < 1 || !validNonnegativeInteger(profile.xp) || !validNonnegativeInteger(profile.credits) || !validNonnegativeInteger(profile.warp_chips) || !validNonnegativeInteger(profile.scrap)) return false;
  if (profileSize === 10) return true;
  const economyValid = validNonnegativeInteger(profile.fuel) && validNonnegativeInteger(profile.max_fuel) && (profile.max_fuel as number) > 0 && (profile.fuel as number) <= (profile.max_fuel as number)
    && validNonnegativeInteger(profile.fuel_day_id) && validNonnegativeInteger(profile.wins) && validNonnegativeInteger(profile.inventory_revision) && validNonnegativeInteger(profile.inventory_count)
    && profile.active_hunt && typeof profile.active_hunt === "object" && !Array.isArray(profile.active_hunt)
    && profile.pending_reward && typeof profile.pending_reward === "object" && !Array.isArray(profile.pending_reward);
  if (!economyValid || profileSize === 18) return economyValid;
  const attributes = profile.attributes;
  const equipment = profile.equipment;
  if (!validNonnegativeInteger(profile.base_power) || !validNonnegativeInteger(profile.stat_points) || !attributes || Object.keys(attributes).length !== 5 || !equipment || Object.keys(equipment).length !== 9 || !Array.isArray(profile.inventory) || profile.inventory.length > 1000) return false;
  for (let index = 0; index < ATTRIBUTE_KEYS.length; index++) if (!validNonnegativeInteger(attributes[ATTRIBUTE_KEYS[index]]) || attributes[ATTRIBUTE_KEYS[index]] < 10) return false;
  const owned: {[key: string]: boolean} = {};
  if (profile.inventory_count !== profile.inventory.length) return false;
  for (let index = 0; index < profile.inventory.length; index++) {
    if (!validServerItem(profile.inventory[index]) || owned[profile.inventory[index].id]) return false;
    owned[profile.inventory[index].id] = true;
  }
  for (let index = 0; index < EQUIPMENT_SLOTS.length; index++) {
    const slot = EQUIPMENT_SLOTS[index]; const item = equipment[slot];
    if (!item || typeof item !== "object" || Array.isArray(item)) return false;
    if (Object.keys(item).length !== 0 && (!validServerItem(item, slot) || (String(item.id).indexOf("starter_") !== 0 && !owned[item.id]))) return false;
  }
  return true;
}

function defaultEquipment(): {[key: string]: {[key: string]: any}} {
  return {weapon: {id: "starter_weapon", slot: "weapon", power: 1, origin_planet_id: ""}, helmet: {},
    armor: {id: "starter_armor", slot: "armor", power: 1, origin_planet_id: ""}, gloves: {}, boots: {}, rig: {}, implant: {}, gadget: {}, relic: {}};
}

function canonicalState(value: StoredCharacter, expectedUserId: string): StoredCharacter {
  if (!validStoredCharacter(value, expectedUserId)) throw Error("Stored character failed integrity validation.");
  const state: StoredCharacter = JSON.parse(JSON.stringify(value));
  if (typeof state.profile.fuel === "undefined") {
    state.profile.fuel = 100; state.profile.max_fuel = 100; state.profile.fuel_day_id = Math.floor(Date.now() / 86400000);
    state.profile.wins = 0; state.profile.inventory_revision = 0; state.profile.inventory_count = 0;
    state.profile.active_hunt = {}; state.profile.pending_reward = {};
  }
  if (typeof state.profile.base_power === "undefined") {
    state.profile.base_power = 10; state.profile.attributes = {strength: 10, vitality: 10, dexterity: 10, intelligence: 10, cunning: 10};
    state.profile.stat_points = 0; state.profile.equipment = defaultEquipment(); state.profile.inventory = [];
  }
  return state;
}

function snapshot(value: StoredCharacter, expectedUserId: string): {[key: string]: any} {
  value = canonicalState(value, expectedUserId);
  return {api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, account_id: value.account_id,
    character_id: value.character_id, revision: value.revision, server_unix_ms: Date.now(), profile: value.profile};
}

function economySnapshot(value: StoredCharacter, expectedUserId: string): {[key: string]: any} {
  const state = canonicalState(value, expectedUserId);
  const active = state.profile.active_hunt || {};
  const pending = state.profile.pending_reward || {};
  return {api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, account_id: expectedUserId,
    character_id: expectedUserId, revision: state.revision, server_unix_ms: Date.now(), economy: {
      level: state.profile.level, xp: state.profile.xp, credits: state.profile.credits, warp_chips: state.profile.warp_chips,
      scrap: state.profile.scrap, fuel: state.profile.fuel, max_fuel: state.profile.max_fuel,
      inventory_revision: state.profile.inventory_revision, inventory_count: state.profile.inventory_count,
      active_hunt: Object.keys(active).length === 0 ? {} : {hunt_id: active.hunt_id, offer_id: active.offer_id, target_id: active.target_id,
        approach_id: active.approach_id, accepted_at_unix_ms: active.accepted_at_unix_ms, resolves_at_unix_ms: active.resolves_at_unix_ms},
      pending_reward: Object.keys(pending).length === 0 ? {} : {reward_id: pending.reward_id, hunt_id: pending.hunt_id, state: "sealed"}
    }};
}

function buildSnapshot(value: StoredCharacter, expectedUserId: string): {[key: string]: any} {
  const state = canonicalState(value, expectedUserId);
  return {api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, account_id: expectedUserId,
    character_id: expectedUserId, revision: state.revision, server_unix_ms: Date.now(), build: {
      base_power: state.profile.base_power, attributes: state.profile.attributes, stat_points: state.profile.stat_points,
      inventory_revision: state.profile.inventory_revision, equipment: state.profile.equipment, inventory: state.profile.inventory
    }};
}

function emptyAgencyMembershipSnapshot(expectedUserId: string): {[key: string]: any} {
  return {api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, account_id: expectedUserId,
    character_id: expectedUserId, revision: 0, server_unix_ms: Date.now(), membership_state: "none",
    agency_id: "", role_id: "", agency: {}};
}

function validAgencyName(value: any): boolean {
  return typeof value === "string" && value.length >= 3 && value.length <= 30 && value === value.trim()
    && value.indexOf("\n") < 0 && value.indexOf("\r") < 0 && value.indexOf("\t") < 0;
}

function validAgencyProfile(value: any): boolean {
  return value && typeof value === "object" && !Array.isArray(value) && exactKeys(value, ["name", "preferred_locale", "recruitment_mode"])
    && validAgencyName(value.name) && ["open", "application", "invite"].indexOf(value.recruitment_mode) >= 0
    && ["pt", "en", "multi"].indexOf(value.preferred_locale) >= 0;
}

function canonicalCgGroup(group: nkruntime.Group): nkruntime.Group | null {
  const metadata = group && group.metadata;
  if (!group || !validIdentifier(group.id) || !validAgencyName(group.name) || group.maxCount !== AGENCY_MEMBER_LIMIT || !metadata
      || metadata.cg_schema_version !== AGENCY_SCHEMA_VERSION || metadata.shard_id !== CG_SHARD_ID || !validNonnegativeInteger(metadata.revision)
      || ["open", "application", "invite"].indexOf(metadata.recruitment_mode) < 0
      || ["pt", "en", "multi"].indexOf(metadata.preferred_locale) < 0) return null;
  return group;
}

function userCgGroup(nk: nkruntime.Nakama, userId: string): nkruntime.UserGroupListUserGroup | null {
  const response = nk.userGroupsList(userId, 100);
  const entries = response.userGroups || []; let found: nkruntime.UserGroupListUserGroup | null = null;
  for (let index = 0; index < entries.length; index++) {
    if (!entries[index].group || !canonicalCgGroup(entries[index].group as nkruntime.Group)) continue;
    if (found) throw Error("Character has multiple Crooked Galaxy Agency memberships.");
    found = entries[index];
  }
  return found;
}

function agencyMembershipSnapshot(nk: nkruntime.Nakama, userId: string): {[key: string]: any} {
  const entry = userCgGroup(nk, userId);
  if (!entry || !entry.group) return emptyAgencyMembershipSnapshot(userId);
  const group = canonicalCgGroup(entry.group); if (!group) throw Error("Agency group failed validation.");
  const metadata = group.metadata; const revision = Number(metadata.revision);
  if (entry.state === 3) return {api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, account_id: userId,
    character_id: userId, revision: revision, server_unix_ms: Date.now(), membership_state: "application_pending",
    agency_id: group.id, role_id: "", agency: {}};
  if (typeof entry.state !== "number" || entry.state < 0 || entry.state > 2) throw Error("Unsupported Agency membership state.");
  const listed = nk.groupUsersList(group.id, AGENCY_MEMBER_LIMIT); const groupUsers = listed.groupUsers || []; const members: any[] = [];
  for (let index = 0; index < groupUsers.length; index++) {
    const groupUser = groupUsers[index]; if (!groupUser.user || typeof groupUser.state !== "number" || groupUser.state < 0 || groupUser.state > 2) continue;
    let role = groupUser.state === 0 ? "director" : (groupUser.state === 1 ? "coordinator" : "agent");
    if (metadata.roles && (metadata.roles[groupUser.user.userId] === "agent" || metadata.roles[groupUser.user.userId] === "recruit")) role = metadata.roles[groupUser.user.userId];
    members.push({character_id: groupUser.user.userId, role_id: role, joined_revision: 1, weekly_eligible: true});
  }
  const ownRole = entry.state === 0 ? "director" : (entry.state === 1 ? "coordinator" : ((metadata.roles && metadata.roles[userId] === "recruit") ? "recruit" : "agent"));
  return {api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, account_id: userId, character_id: userId,
    revision: revision, server_unix_ms: Date.now(), membership_state: "member", agency_id: group.id, role_id: ownRole,
    agency: {authority: "server", shard_id: CG_SHARD_ID, agency_id: group.id, name: group.name, revision: revision, members: members,
      recruitment_mode: metadata.recruitment_mode, preferred_locale: metadata.preferred_locale}};
}

function agencyReceipt(request: {[key: string]: any}, userId: string, status: string, revision: number, reason: string): {[key: string]: any} {
  return {api_version: CG_API_VERSION, authority: "server", command_id: request.command_id, idempotency_key: request.idempotency_key,
    operation: request.operation, shard_id: CG_SHARD_ID, character_id: userId, status: status, server_revision: revision,
    server_unix_ms: Date.now(), reason_code: reason};
}

function claimAgencyGuard(nk: nkruntime.Nakama, userId: string, operation: string, fingerprint: string, target: string): string {
  const now = Date.now(); const value = {operation: operation, fingerprint: fingerprint, target: target, lease_until_unix_ms: now + AGENCY_GUARD_LEASE_MS};
  try {
    nk.storageWrite([{collection: AGENCY_GUARD_COLLECTION, key: AGENCY_GUARD_KEY, userId: userId, value: value,
      version: "*", permissionRead: 0, permissionWrite: 0}]);
    return "acquired";
  } catch (_error) {
    const objects = nk.storageRead([{collection: AGENCY_GUARD_COLLECTION, key: AGENCY_GUARD_KEY, userId: userId}]);
    if (objects.length !== 1) throw Error("Agency membership guard could not be recovered.");
    const held = objects[0].value as {[key: string]: any};
    if (held.operation !== operation || held.fingerprint !== fingerprint || held.target !== target) return "different_busy";
    if (Number(held.lease_until_unix_ms || 0) > now) return "same_busy";
    try {
      nk.storageWrite([{collection: AGENCY_GUARD_COLLECTION, key: AGENCY_GUARD_KEY, userId: userId, value: value,
        version: objects[0].version, permissionRead: 0, permissionWrite: 0}]);
      return "acquired";
    } catch (_takeoverError) { return "same_busy"; }
  }
}

function validAllocation(value: any): boolean {
  if (!value || typeof value !== "object" || Array.isArray(value) || Object.keys(value).length === 0 || Object.keys(value).length > ATTRIBUTE_KEYS.length) return false;
  const keys = Object.keys(value); let total = 0;
  for (let index = 0; index < keys.length; index++) {
    if (ATTRIBUTE_KEYS.indexOf(keys[index]) < 0 || !validNonnegativeInteger(value[keys[index]]) || value[keys[index]] <= 0) return false;
    total += value[keys[index]];
  }
  return total > 0;
}

function inventoryItem(profile: CharacterProfile, itemId: string): any | null {
  const inventory = profile.inventory || [];
  for (let index = 0; index < inventory.length; index++) if (inventory[index] && inventory[index].id === itemId) return inventory[index];
  return null;
}

function salvageValue(item: any): number { return Math.max(1, Math.ceil(Number(item.power || 0) / 3)); }

function buildReceipt(request: {[key: string]: any}, userId: string, status: string, revision: number, reason: string, state?: StoredCharacter, result?: any): {[key: string]: any} {
  const response = economyReceipt(request, userId, status, revision, reason, state, result);
  if (state) response.snapshot = buildSnapshot(state, userId);
  return response;
}

function buildReplay(nk: nkruntime.Nakama, request: {[key: string]: any}, userId: string, fingerprint: string, state: StoredCharacter): {[key: string]: any} | null {
  const receipts = nk.storageRead([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId}]);
  if (receipts.length !== 1) return null;
  const saved = receipts[0].value as {[key: string]: any};
  if (saved.operation !== request.operation || saved.fingerprint !== fingerprint) return buildReceipt(request, userId, "rejected", state.revision, "idempotency_mismatch", state);
  return buildReceipt(request, userId, "duplicate", saved.server_revision, "", state, saved.result);
}

function writeBuild(nk: nkruntime.Nakama, object: nkruntime.StorageObject, request: {[key: string]: any}, userId: string, fingerprint: string, updated: StoredCharacter, result?: any): {[key: string]: any} {
  try {
    nk.multiUpdate(null, [
      {collection: CHARACTER_COLLECTION, key: CHARACTER_KEY, userId: userId, value: updated, version: object.version, permissionRead: 0, permissionWrite: 0},
      {collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId, value: {operation: request.operation, fingerprint: fingerprint, server_revision: updated.revision, result: result || null}, version: "*", permissionRead: 0, permissionWrite: 0}
    ], null, null);
  } catch (_error) {
    const latestObject = readCharacter(nk, userId);
    if (!latestObject) throw Error("Character disappeared during build mutation.");
    const latest = canonicalState(latestObject.value as StoredCharacter, userId);
    const replay = buildReplay(nk, request, userId, fingerprint, latest);
    if (replay) return replay;
    return buildReceipt(request, userId, "conflict", latest.revision, "revision_conflict", latest);
  }
  return buildReceipt(request, userId, "accepted", updated.revision, "", updated, result);
}

function roundPositive(value: number): number { return Math.floor(value + 0.5); }
function clamp(value: number, minimum: number, maximum: number): number { return Math.max(minimum, Math.min(maximum, value)); }
function catalogById(values: any[], id: string): any | null {
  for (let index = 0; index < values.length; index++) if (values[index].id === id) return values[index];
  return null;
}
function travelMultiplier(level: number): number {
  const bands = CG_CONTENT_MANIFEST.rules.early_travel_bands;
  for (let index = 0; index < bands.length; index++) if (level >= bands[index].minimum_level) return bands[index].multiplier;
  return 0.4;
}
function scaledOffer(planet: any, target: any, role: any, approach: any, level: number, offerIndex: number): any {
  const pressure = role.pressure_mult;
  const basePower = Math.max(1, roundPositive((11 + (level - 1) * 5) * pressure));
  const baseDefense = Math.max(0, roundPositive((4 + (level - 1) * 2.5) * pressure));
  const baseHealth = Math.max(1, roundPositive((70 + (level - 1) * 35) * pressure));
  const baseCredits = Math.max(1, roundPositive((32 + 1.35 * level * level) * role.reward_mult));
  const baseXp = Math.max(1, roundPositive((36 + 7 * level) * role.reward_mult));
  const planetIndex = CG_CONTENT_MANIFEST.planets.indexOf(planet);
  const blend = clamp((level - CG_CONTENT_MANIFEST.rules.late_blend_start) / (CG_CONTENT_MANIFEST.rules.late_blend_end - CG_CONTENT_MANIFEST.rules.late_blend_start), 0, 1);
  let powerMult = approach.power_mult; let defenseMult = approach.defense_mult;
  let healthMult = approach.health_mult + (approach.planet_health_step || 0) * planetIndex + (planetIndex === 0 ? (approach.frontier_health_bonus || 0) : 0);
  powerMult += ((approach.late_power_mult || powerMult) - powerMult) * blend;
  defenseMult += ((approach.late_defense_mult || defenseMult) - defenseMult) * blend;
  healthMult += ((approach.late_health_mult || healthMult) - healthMult) * blend;
  const travel = planet.travel_duration * travelMultiplier(level);
  const pursuit = (20 + Math.min(100, level * 4)) * approach.duration_mult;
  return {offer_id: "offer_" + String(offerIndex) + "_" + role.id, target_id: target.id, planet_id: planet.id, role_id: role.id,
    approach_id: approach.id, duration_seconds: Math.ceil(travel + pursuit), fuel_cost: clamp(Math.ceil(planet.travel_duration / 60), 1, CG_CONTENT_MANIFEST.rules.max_mission_fuel_cost),
    power: Math.max(1, roundPositive(basePower * powerMult)), defense: Math.max(0, roundPositive(baseDefense * defenseMult)),
    health: Math.max(1, roundPositive(baseHealth * healthMult)), credits: Math.max(1, roundPositive(baseCredits * approach.credits_mult)),
    xp: Math.max(1, roundPositive(baseXp * approach.xp_mult)), scrap: Math.max(0, approach.scrap_reward || 0), loot_power: basePower,
    enemy_profile_id: target.enemy_profile_id, enemy_modifiers: CG_CONTENT_MANIFEST.enemy_profiles[target.enemy_profile_id] || {}};
}

function huntBoard(value: StoredCharacter, expectedUserId: string): {[key: string]: any} {
  const state = canonicalState(value, expectedUserId);
  const wins = state.profile.wins || 0;
  const level = state.profile.level;
  const available: any[] = [];
  for (let index = 0; index < CG_CONTENT_MANIFEST.planets.length; index++) if (level >= CG_CONTENT_MANIFEST.planets[index].unlock_level) available.push(CG_CONTENT_MANIFEST.planets[index]);
  const offers: any[] = [];
  for (let index = 0; index < CG_CONTENT_MANIFEST.roles.length; index++) {
    const planet = available[(wins + index) % available.length];
    const targetId = planet.target_ids[(wins * (available.length === 1 ? 1 : 2) + index + CG_CONTENT_MANIFEST.planets.indexOf(planet)) % planet.target_ids.length];
    const target = catalogById(CG_CONTENT_MANIFEST.targets, targetId);
    const role = CG_CONTENT_MANIFEST.roles[index];
    const approaches: any[] = [];
    for (let approachIndex = 0; approachIndex < CG_CONTENT_MANIFEST.approaches.length; approachIndex++) approaches.push(scaledOffer(planet, target, role, CG_CONTENT_MANIFEST.approaches[approachIndex], level, index));
    offers.push({offer_id: "offer_" + String(index) + "_" + role.id, target_id: target.id, planet_id: planet.id, role_id: role.id,
      approach_ids: CG_CONTENT_MANIFEST.approaches.map(function (entry: any): string { return entry.id; }), duration_seconds: approaches[0].duration_seconds,
      fuel_cost: approaches[0].fuel_cost, approaches: approaches});
  }
  return {api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, account_id: expectedUserId,
    character_id: expectedUserId, revision: state.revision, server_unix_ms: Date.now(), content_hash: CG_CONTENT_MANIFEST.content_hash,
    board_id: "board_" + CG_CONTENT_MANIFEST.content_hash.substr(0, 12) + "_" + String(wins), offers: offers};
}

function effectiveHuntDuration(context: nkruntime.Context, authored: number): number {
  return context.env && context.env["CG_ENVIRONMENT"] === "local" ? 2 : authored;
}

function validCommandEnvelope(request: {[key: string]: any}, userId: string, operation: string): boolean {
  return Object.keys(request).length === 9 && request.api_version === CG_API_VERSION && validIdentifier(request.command_id)
    && validIdentifier(request.idempotency_key) && validIdentifier(request.session_id) && request.operation === operation
    && request.shard_id === CG_SHARD_ID && request.character_id === userId && validNonnegativeInteger(request.expected_revision)
    && request.payload && typeof request.payload === "object" && !Array.isArray(request.payload);
}

function exactKeys(value: any, keys: string[]): boolean {
  if (!value || typeof value !== "object" || Array.isArray(value) || Object.keys(value).length !== keys.length) return false;
  for (let index = 0; index < keys.length; index++) if (!Object.prototype.hasOwnProperty.call(value, keys[index])) return false;
  return true;
}

function economyReceipt(request: {[key: string]: any}, userId: string, status: string, revision: number, reason: string, state?: StoredCharacter, result?: any): {[key: string]: any} {
  const response: {[key: string]: any} = {api_version: CG_API_VERSION, authority: "server", command_id: request.command_id,
    idempotency_key: request.idempotency_key, operation: request.operation, shard_id: CG_SHARD_ID, character_id: userId,
    status: status, server_revision: revision, server_unix_ms: Date.now(), reason_code: reason};
  if (state) response.snapshot = economySnapshot(state, userId);
  if (result) response.result = result;
  return response;
}

function economyReplay(nk: nkruntime.Nakama, request: {[key: string]: any}, userId: string, fingerprint: string, state: StoredCharacter): {[key: string]: any} | null {
  const receipts = nk.storageRead([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId}]);
  if (receipts.length !== 1) return null;
  const saved = receipts[0].value as {[key: string]: any};
  if (saved.operation !== request.operation || saved.fingerprint !== fingerprint) return economyReceipt(request, userId, "rejected", state.revision, "idempotency_mismatch", state);
  return economyReceipt(request, userId, "duplicate", saved.server_revision, "", state, saved.result);
}

function writeEconomy(nk: nkruntime.Nakama, object: nkruntime.StorageObject, request: {[key: string]: any}, userId: string, fingerprint: string, updated: StoredCharacter, result?: any): {[key: string]: any} {
  try {
    nk.multiUpdate(null, [
      {collection: CHARACTER_COLLECTION, key: CHARACTER_KEY, userId: userId, value: updated, version: object.version, permissionRead: 0, permissionWrite: 0},
      {collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId, value: {operation: request.operation, fingerprint: fingerprint, server_revision: updated.revision, result: result || null}, version: "*", permissionRead: 0, permissionWrite: 0}
    ], null, null);
  } catch (_error) {
    const latestObject = readCharacter(nk, userId);
    if (!latestObject) throw Error("Character disappeared during economy mutation.");
    const latest = canonicalState(latestObject.value as StoredCharacter, userId);
    const replay = economyReplay(nk, request, userId, fingerprint, latest);
    if (replay) return replay;
    return economyReceipt(request, userId, "conflict", latest.revision, "revision_conflict", latest);
  }
  return economyReceipt(request, userId, "accepted", updated.revision, "", updated, result);
}

function rpcCrookedGalaxyClock(context: nkruntime.Context, logger: nkruntime.Logger, _nk: nkruntime.Nakama, _payload: string): string {
  const userId = requireUser(context);
  logger.debug("Authoritative clock sampled for user %s.", userId);
  return JSON.stringify({api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, server_unix_ms: Date.now()});
}

function rpcCharacterGet(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, _payload: string): string {
  const userId = requireUser(context);
  const object = readCharacter(nk, userId);
  if (!object) return JSON.stringify({api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, account_id: userId, exists: false, server_unix_ms: Date.now()});
  return JSON.stringify(snapshot(object.value as StoredCharacter, userId));
}

function rpcSessionSummary(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, _payload: string): string {
  const userId = requireUser(context);
  if (!readCharacter(nk, userId)) throw Error("Active character required.");
  const now = Date.now();
  const userSessionExp = context.userSessionExp;
  if (typeof userSessionExp !== "number") throw Error("Valid authenticated session required.");
  const expiresAt = userSessionExp * 1000;
  if (expiresAt <= now) throw Error("Valid authenticated session required.");
  const safeSessionId = context.sessionId || (userId + "." + String(userSessionExp));
  return JSON.stringify({
    api_version: CG_API_VERSION,
    provider_id: "nakama",
    account_id: userId,
    session_id: safeSessionId,
    session_state: "authenticated",
    shard_id: CG_SHARD_ID,
    active_character_id: userId,
    owned_character_ids: [userId],
    authority: "server",
    issued_at_unix_ms: now,
    expires_at_unix_ms: expiresAt
  });
}

function rpcCharacterCreate(context: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context);
  const request = parsePayload(payload);
  const idempotencyKey = request.idempotency_key;
  const appearance = canonicalAppearance(request.appearance);
  if (Object.keys(request).length !== 5 || !validIdentifier(idempotencyKey) || !validHunterName(request.hunter_name) || !CLASS_IDS[request.class_id] || !SPECIES_IDS[request.species_id] || !appearance) throw Error("Invalid character creation payload.");
  const fingerprint = [request.hunter_name, request.class_id, request.species_id, appearance.palette, appearance.eyes, appearance.feature, appearance.marking].join("|");
  const receiptObjects = nk.storageRead([{collection: RECEIPT_COLLECTION, key: idempotencyKey, userId: userId}]);
  if (receiptObjects.length === 1) {
    const receipt = receiptObjects[0].value as {[key: string]: any};
    if (receipt.operation !== "character_create" || receipt.fingerprint !== fingerprint) throw Error("Idempotency key was already used for another command.");
    const existing = readCharacter(nk, userId);
    if (!existing) throw Error("Character receipt exists without character state.");
    const replay = snapshot(existing.value as StoredCharacter, userId);
    replay.created = false; replay.idempotent_replay = true;
    return JSON.stringify(replay);
  }
  if (readCharacter(nk, userId)) throw Error("Account already owns its launch character.");
  const value: StoredCharacter = {
    api_version: CG_API_VERSION, account_id: userId, character_id: userId, shard_id: CG_SHARD_ID, revision: 0,
    profile: {character_id: userId, hunter_name: request.hunter_name, class_id: request.class_id, species_id: request.species_id,
      appearance: appearance, level: 1, xp: 0, credits: 25, warp_chips: 0, scrap: 0,
      fuel: 100, max_fuel: 100, fuel_day_id: Math.floor(Date.now() / 86400000), wins: 0,
      inventory_revision: 0, inventory_count: 0, active_hunt: {}, pending_reward: {}, base_power: 10,
      attributes: {strength: 10, vitality: 10, dexterity: 10, intelligence: 10, cunning: 10}, stat_points: 0,
      equipment: defaultEquipment(), inventory: []}
  };
  try {
    nk.multiUpdate(null, [
      {collection: CHARACTER_COLLECTION, key: CHARACTER_KEY, userId: userId, value: value, version: "*", permissionRead: 0, permissionWrite: 0},
      {collection: RECEIPT_COLLECTION, key: idempotencyKey, userId: userId, value: {operation: "character_create", fingerprint: fingerprint}, version: "*", permissionRead: 0, permissionWrite: 0}
    ], null, null);
  } catch (_error) {
    const racedReceipts = nk.storageRead([{collection: RECEIPT_COLLECTION, key: idempotencyKey, userId: userId}]);
    const racedCharacter = readCharacter(nk, userId);
    if (racedReceipts.length === 1 && racedCharacter) {
      const racedReceipt = racedReceipts[0].value as {[key: string]: any};
      if (racedReceipt.operation === "character_create" && racedReceipt.fingerprint === fingerprint) {
        const replay = snapshot(racedCharacter.value as StoredCharacter, userId);
        replay.created = false; replay.idempotent_replay = true;
        return JSON.stringify(replay);
      }
    }
    throw Error("Character creation conflict.");
  }
  logger.info("Created authoritative launch character for account %s.", userId);
  const response = snapshot(value, userId); response.created = true; response.idempotent_replay = false;
  return JSON.stringify(response);
}

function commitReceipt(request: {[key: string]: any}, userId: string, status: string, revision: number, reason: string, state?: StoredCharacter): {[key: string]: any} {
  const response: {[key: string]: any} = {api_version: CG_API_VERSION, authority: "server", command_id: request.command_id,
    idempotency_key: request.idempotency_key, operation: "profile_commit", shard_id: CG_SHARD_ID, character_id: userId,
    status: status, server_revision: revision, server_unix_ms: Date.now(), reason_code: reason};
  if (state) response.snapshot = snapshot(state, userId);
  return response;
}

function rpcCharacterCommit(context: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context);
  const request = parsePayload(payload);
  if (Object.keys(request).length !== 9 || request.api_version !== CG_API_VERSION || !validIdentifier(request.command_id) || !validIdentifier(request.idempotency_key) || !validIdentifier(request.session_id) || request.operation !== "profile_commit" || request.shard_id !== CG_SHARD_ID || request.character_id !== userId || typeof request.expected_revision !== "number" || request.expected_revision < 0 || Math.floor(request.expected_revision) !== request.expected_revision) throw Error("Invalid profile command envelope.");
  const object = readCharacter(nk, userId);
  if (!object) return JSON.stringify(commitReceipt(request, userId, "rejected", 0, "character_missing"));
  const current = canonicalState(object.value as StoredCharacter, userId);
  const change = request.payload;
  const appearance = change && canonicalAppearance(change.appearance);
  if (!change || typeof change !== "object" || !validHunterName(change.hunter_name) || !appearance || Object.keys(change).length !== 2) return JSON.stringify(commitReceipt(request, userId, "rejected", current.revision, "invalid_profile_change", current));
  const fingerprint = [request.command_id, request.expected_revision, change.hunter_name, appearance.palette, appearance.eyes, appearance.feature, appearance.marking].join("|");
  const receipts = nk.storageRead([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId}]);
  if (receipts.length === 1) {
    const saved = receipts[0].value as {[key: string]: any};
    if (saved.operation !== "profile_commit" || saved.fingerprint !== fingerprint) return JSON.stringify(commitReceipt(request, userId, "rejected", current.revision, "idempotency_mismatch", current));
    return JSON.stringify(commitReceipt(request, userId, "duplicate", saved.server_revision, "", current));
  }
  if (request.expected_revision !== current.revision) return JSON.stringify(commitReceipt(request, userId, "conflict", current.revision, "revision_conflict", current));
  const updated: StoredCharacter = JSON.parse(JSON.stringify(current));
  updated.revision = current.revision + 1; updated.profile.hunter_name = change.hunter_name; updated.profile.appearance = appearance;
  try {
    nk.multiUpdate(null, [
      {collection: CHARACTER_COLLECTION, key: CHARACTER_KEY, userId: userId, value: updated, version: object.version, permissionRead: 0, permissionWrite: 0},
      {collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId, value: {operation: "profile_commit", fingerprint: fingerprint, server_revision: updated.revision}, version: "*", permissionRead: 0, permissionWrite: 0}
    ], null, null);
  } catch (_error) {
    const latest = readCharacter(nk, userId);
    if (!latest) throw Error("Character disappeared during commit.");
    const racedReceipts = nk.storageRead([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId}]);
    if (racedReceipts.length === 1) {
      const racedReceipt = racedReceipts[0].value as {[key: string]: any};
      if (racedReceipt.operation === "profile_commit" && racedReceipt.fingerprint === fingerprint) return JSON.stringify(commitReceipt(request, userId, "duplicate", racedReceipt.server_revision, "", latest.value as StoredCharacter));
    }
    return JSON.stringify(commitReceipt(request, userId, "conflict", (latest.value as StoredCharacter).revision, "revision_conflict", latest.value as StoredCharacter));
  }
  logger.info("Committed character profile revision %d for account %s.", updated.revision, userId);
  return JSON.stringify(commitReceipt(request, userId, "accepted", updated.revision, "", updated));
}

function rpcEconomyGet(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, _payload: string): string {
  const userId = requireUser(context);
  const object = readCharacter(nk, userId);
  if (!object) throw Error("Active character required.");
  return JSON.stringify(economySnapshot(object.value as StoredCharacter, userId));
}

function rpcBuildGet(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, _payload: string): string {
  const userId = requireUser(context);
  const object = readCharacter(nk, userId);
  if (!object) throw Error("Active character required.");
  return JSON.stringify(buildSnapshot(object.value as StoredCharacter, userId));
}

function rpcAgencyMembershipGet(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, _payload: string): string {
  const userId = requireUser(context);
  if (!readCharacter(nk, userId)) throw Error("Active character required.");
  return JSON.stringify(agencyMembershipSnapshot(nk, userId));
}

function rpcAgencyDirectory(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  requireUser(context); const request = parsePayload(payload);
  if (!exactKeys(request, ["cursor"]) || (typeof request.cursor !== "string") || (request.cursor && !validIdentifier(request.cursor))) throw Error("Invalid Agency directory cursor.");
  const response = nk.groupsList(undefined, undefined, undefined, undefined, AGENCY_MEMBER_LIMIT, request.cursor || undefined);
  const groups = response.groups || []; const summaries: any[] = [];
  for (let index = 0; index < groups.length; index++) {
    const group = canonicalCgGroup(groups[index]); if (!group) continue;
    summaries.push({authority: "server", shard_id: CG_SHARD_ID, agency_id: group.id, name: group.name,
      revision: group.metadata.revision, member_count: group.edgeCount, recruitment_mode: group.metadata.recruitment_mode,
      preferred_locale: group.metadata.preferred_locale});
  }
  return JSON.stringify({api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, server_unix_ms: Date.now(),
    cursor: request.cursor || "", next_cursor: response.cursor || "", agencies: summaries});
}

function rpcAgencyCreate(context: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context); const request = parsePayload(payload); const profile = request.payload;
  if (!validCommandEnvelope(request, userId, "agency_create") || !validAgencyProfile(profile)) throw Error("Invalid Agency creation command.");
  if (!readCharacter(nk, userId)) return JSON.stringify(agencyReceipt(request, userId, "rejected", 0, "character_missing"));
  const fingerprint = [request.command_id, request.expected_revision, profile.name, profile.recruitment_mode, profile.preferred_locale].join("|");
  const receipts = nk.storageRead([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId}]);
  if (receipts.length === 1) {
    const saved = receipts[0].value as {[key: string]: any};
    if (saved.operation !== "agency_create" || saved.fingerprint !== fingerprint) return JSON.stringify(agencyReceipt(request, userId, "rejected", Number(saved.server_revision || 0), "idempotency_mismatch"));
    return JSON.stringify(agencyReceipt(request, userId, "duplicate", Number(saved.server_revision), ""));
  }
  const current = userCgGroup(nk, userId);
  if (current && current.group) {
    const metadata = current.group.metadata || {};
    if (metadata.creation_idempotency_key === request.idempotency_key && metadata.creation_fingerprint === fingerprint) {
      nk.storageWrite([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId,
        value: {operation: "agency_create", fingerprint: fingerprint, server_revision: Number(metadata.revision)}, permissionRead: 0, permissionWrite: 0}]);
      return JSON.stringify(agencyReceipt(request, userId, "duplicate", Number(metadata.revision), ""));
    }
    return JSON.stringify(agencyReceipt(request, userId, "rejected", Number(metadata.revision || 0), "already_member"));
  }
  if (request.expected_revision !== 0) return JSON.stringify(agencyReceipt(request, userId, "conflict", 0, "revision_conflict"));
  const creationGuard = claimAgencyGuard(nk, userId, "agency_create", fingerprint, profile.name);
  if (creationGuard === "same_busy") throw Error("Exact Agency creation is still in progress.");
  if (creationGuard !== "acquired") return JSON.stringify(agencyReceipt(request, userId, "rejected", 0, "membership_command_in_progress"));
  const roles: {[key: string]: string} = {}; roles[userId] = "director";
  const metadata = {cg_schema_version: AGENCY_SCHEMA_VERSION, shard_id: CG_SHARD_ID, revision: 1,
    recruitment_mode: profile.recruitment_mode, preferred_locale: profile.preferred_locale, roles: roles,
    creation_idempotency_key: request.idempotency_key, creation_fingerprint: fingerprint};
  const group = nk.groupCreate(userId, profile.name, userId, profile.preferred_locale, "", "", profile.recruitment_mode === "open", metadata, AGENCY_MEMBER_LIMIT);
  try {
    nk.storageWrite([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId,
      value: {operation: "agency_create", fingerprint: fingerprint, server_revision: 1}, permissionRead: 0, permissionWrite: 0}]);
  } catch (error) { logger.warn("Agency %s created with recoverable receipt write failure: %s", group.id, String(error)); }
  return JSON.stringify(agencyReceipt(request, userId, "accepted", 1, ""));
}

function rpcAgencyApply(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context); const request = parsePayload(payload); const change = request.payload;
  if (!validCommandEnvelope(request, userId, "agency_apply") || !exactKeys(change, ["agency_id"]) || !validIdentifier(change.agency_id)) throw Error("Invalid Agency application command.");
  if (!readCharacter(nk, userId)) return JSON.stringify(agencyReceipt(request, userId, "rejected", 0, "character_missing"));
  const fingerprint = [request.command_id, request.expected_revision, change.agency_id].join("|");
  const receipts = nk.storageRead([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId}]);
  let saved: {[key: string]: any} | null = receipts.length === 1 ? receipts[0].value as {[key: string]: any} : null;
  if (saved && (saved.operation !== "agency_apply" || saved.fingerprint !== fingerprint)) {
    return JSON.stringify(agencyReceipt(request, userId, "rejected", Number(saved.server_revision || 0), "idempotency_mismatch"));
  }
  if (saved && saved.phase === "committed") return JSON.stringify(agencyReceipt(request, userId, "duplicate", Number(saved.server_revision), ""));
  const current = userCgGroup(nk, userId);
  if (current && current.group) {
    const currentRevision = Number((current.group.metadata || {}).revision || 0);
    if (current.group.id !== change.agency_id) return JSON.stringify(agencyReceipt(request, userId, "rejected", currentRevision, "already_member_or_pending"));
    if (!saved || saved.phase !== "prepared") {
      const reason = current.state === 3 ? "application_pending" : "already_member";
      return JSON.stringify(agencyReceipt(request, userId, "rejected", currentRevision, reason));
    }
    nk.storageWrite([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId,
      value: {operation: "agency_apply", fingerprint: fingerprint, phase: "committed", server_revision: currentRevision}, permissionRead: 0, permissionWrite: 0}]);
    return JSON.stringify(agencyReceipt(request, userId, "duplicate", currentRevision, ""));
  }
  if (request.expected_revision !== 0) return JSON.stringify(agencyReceipt(request, userId, "conflict", 0, "revision_conflict"));
  const found = nk.groupsGetId([change.agency_id]);
  const target = found.length === 1 ? canonicalCgGroup(found[0]) : null;
  if (!target) return JSON.stringify(agencyReceipt(request, userId, "rejected", 0, "agency_missing"));
  const revision = Number(target.metadata.revision);
  if (target.metadata.recruitment_mode === "invite") return JSON.stringify(agencyReceipt(request, userId, "rejected", 0, "invite_only"));
  if (target.edgeCount >= AGENCY_MEMBER_LIMIT) return JSON.stringify(agencyReceipt(request, userId, "rejected", revision, "agency_full"));
  if (!saved) {
    const applicationGuard = claimAgencyGuard(nk, userId, "agency_apply", fingerprint, change.agency_id);
    if (applicationGuard === "same_busy") throw Error("Exact Agency application is still in progress.");
    if (applicationGuard !== "acquired") return JSON.stringify(agencyReceipt(request, userId, "rejected", 0, "membership_command_in_progress"));
    nk.storageWrite([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId,
      value: {operation: "agency_apply", fingerprint: fingerprint, phase: "prepared", server_revision: revision}, permissionRead: 0, permissionWrite: 0}]);
    saved = {operation: "agency_apply", fingerprint: fingerprint, phase: "prepared", server_revision: revision};
  }
  const username = context.username || userId;
  nk.groupUserJoin(target.id, userId, username);
  const joined = userCgGroup(nk, userId);
  if (!joined || !joined.group || joined.group.id !== target.id || (joined.state !== 2 && joined.state !== 3)) throw Error("Agency application edge was not committed.");
  nk.storageWrite([{collection: RECEIPT_COLLECTION, key: request.idempotency_key, userId: userId,
    value: {operation: "agency_apply", fingerprint: fingerprint, phase: "committed", server_revision: revision}, permissionRead: 0, permissionWrite: 0}]);
  return JSON.stringify(agencyReceipt(request, userId, "accepted", revision, ""));
}

function rpcAttributeAllocate(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context); const request = parsePayload(payload); const change = request.payload;
  if (!validCommandEnvelope(request, userId, "attribute_allocate") || !exactKeys(change, ["allocations"]) || !validAllocation(change.allocations)) throw Error("Invalid attribute allocation command.");
  const object = readCharacter(nk, userId);
  if (!object) return JSON.stringify(buildReceipt(request, userId, "rejected", 0, "character_missing"));
  const current = canonicalState(object.value as StoredCharacter, userId); const parts: string[] = [];
  for (let index = 0; index < ATTRIBUTE_KEYS.length; index++) parts.push(ATTRIBUTE_KEYS[index] + ":" + String(change.allocations[ATTRIBUTE_KEYS[index]] || 0));
  const fingerprint = [request.command_id, request.expected_revision].concat(parts).join("|");
  const replay = buildReplay(nk, request, userId, fingerprint, current); if (replay) return JSON.stringify(replay);
  if (request.expected_revision !== current.revision) return JSON.stringify(buildReceipt(request, userId, "conflict", current.revision, "revision_conflict", current));
  let total = 0; const keys = Object.keys(change.allocations); for (let index = 0; index < keys.length; index++) total += change.allocations[keys[index]];
  if (total > Number(current.profile.stat_points || 0)) return JSON.stringify(buildReceipt(request, userId, "rejected", current.revision, "insufficient_stat_points", current));
  const updated: StoredCharacter = JSON.parse(JSON.stringify(current)); updated.revision++;
  for (let index = 0; index < keys.length; index++) (updated.profile.attributes as any)[keys[index]] += change.allocations[keys[index]];
  updated.profile.stat_points = Number(updated.profile.stat_points || 0) - total;
  return JSON.stringify(writeBuild(nk, object, request, userId, fingerprint, updated, {allocated: total}));
}

function rpcInventoryEquip(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context); const request = parsePayload(payload); const change = request.payload;
  if (!validCommandEnvelope(request, userId, "inventory_equip") || !exactKeys(change, ["item_id"]) || !validIdentifier(change.item_id)) throw Error("Invalid inventory equip command.");
  const object = readCharacter(nk, userId);
  if (!object) return JSON.stringify(buildReceipt(request, userId, "rejected", 0, "character_missing"));
  const current = canonicalState(object.value as StoredCharacter, userId); const fingerprint = [request.command_id, request.expected_revision, change.item_id].join("|");
  const replay = buildReplay(nk, request, userId, fingerprint, current); if (replay) return JSON.stringify(replay);
  if (request.expected_revision !== current.revision) return JSON.stringify(buildReceipt(request, userId, "conflict", current.revision, "revision_conflict", current));
  const item = inventoryItem(current.profile, change.item_id);
  if (!item || EQUIPMENT_SLOTS.indexOf(String(item.slot)) < 0) return JSON.stringify(buildReceipt(request, userId, "rejected", current.revision, "item_missing", current));
  const updated: StoredCharacter = JSON.parse(JSON.stringify(current)); updated.revision++;
  (updated.profile.equipment as any)[item.slot] = JSON.parse(JSON.stringify(item)); updated.profile.inventory_revision = Number(updated.profile.inventory_revision || 0) + 1;
  return JSON.stringify(writeBuild(nk, object, request, userId, fingerprint, updated, {item_id: item.id, slot: item.slot}));
}

function rpcInventoryRecycle(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context); const request = parsePayload(payload); const change = request.payload;
  if (!validCommandEnvelope(request, userId, "inventory_recycle") || !exactKeys(change, ["item_id"]) || !validIdentifier(change.item_id)) throw Error("Invalid inventory recycle command.");
  const object = readCharacter(nk, userId);
  if (!object) return JSON.stringify(buildReceipt(request, userId, "rejected", 0, "character_missing"));
  const current = canonicalState(object.value as StoredCharacter, userId); const fingerprint = [request.command_id, request.expected_revision, change.item_id].join("|");
  const replay = buildReplay(nk, request, userId, fingerprint, current); if (replay) return JSON.stringify(replay);
  if (request.expected_revision !== current.revision) return JSON.stringify(buildReceipt(request, userId, "conflict", current.revision, "revision_conflict", current));
  const item = inventoryItem(current.profile, change.item_id);
  if (!item) return JSON.stringify(buildReceipt(request, userId, "rejected", current.revision, "item_missing", current));
  for (let index = 0; index < EQUIPMENT_SLOTS.length; index++) if ((current.profile.equipment as any)[EQUIPMENT_SLOTS[index]].id === change.item_id) return JSON.stringify(buildReceipt(request, userId, "rejected", current.revision, "item_equipped", current));
  const updated: StoredCharacter = JSON.parse(JSON.stringify(current)); const value = salvageValue(item); updated.revision++;
  updated.profile.inventory = (updated.profile.inventory as any[]).filter(function (entry: any): boolean { return entry.id !== change.item_id; });
  updated.profile.inventory_count = (updated.profile.inventory as any[]).length; updated.profile.inventory_revision = Number(updated.profile.inventory_revision || 0) + 1; updated.profile.scrap += value;
  return JSON.stringify(writeBuild(nk, object, request, userId, fingerprint, updated, {item_id: item.id, scrap: value}));
}

function rpcHuntBoard(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, _payload: string): string {
  const userId = requireUser(context);
  const object = readCharacter(nk, userId);
  if (!object) throw Error("Active character required.");
  const response = huntBoard(object.value as StoredCharacter, userId);
  if (context.env && context.env["CG_ENVIRONMENT"] === "local") {
    for (let index = 0; index < response.offers.length; index++) response.offers[index].duration_seconds = 2;
  }
  return JSON.stringify(response);
}

function rpcHuntAccept(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context);
  const request = parsePayload(payload);
  const change = request.payload;
  if (!validCommandEnvelope(request, userId, "hunt_accept") || !exactKeys(change, ["board_id", "offer_id", "target_id", "approach_id"])
      || !validIdentifier(change.board_id) || !validIdentifier(change.offer_id) || !validIdentifier(change.target_id) || !validIdentifier(change.approach_id)) throw Error("Invalid hunt acceptance command.");
  const object = readCharacter(nk, userId);
  if (!object) return JSON.stringify(economyReceipt(request, userId, "rejected", 0, "character_missing"));
  const current = canonicalState(object.value as StoredCharacter, userId);
  const fingerprint = [request.command_id, request.expected_revision, change.board_id, change.offer_id, change.target_id, change.approach_id].join("|");
  const replay = economyReplay(nk, request, userId, fingerprint, current);
  if (replay) return JSON.stringify(replay);
  if (request.expected_revision !== current.revision) return JSON.stringify(economyReceipt(request, userId, "conflict", current.revision, "revision_conflict", current));
  if (Object.keys(current.profile.active_hunt || {}).length !== 0 || Object.keys(current.profile.pending_reward || {}).length !== 0) return JSON.stringify(economyReceipt(request, userId, "rejected", current.revision, "hunt_state_busy", current));
  const board = huntBoard(current, userId);
  if (change.board_id !== board.board_id) return JSON.stringify(economyReceipt(request, userId, "rejected", current.revision, "board_expired", current));
  let offer: {[key: string]: any} | null = null;
  for (let index = 0; index < board.offers.length; index++) if (board.offers[index].offer_id === change.offer_id) offer = board.offers[index];
  if (!offer || offer.target_id !== change.target_id || offer.approach_ids.indexOf(change.approach_id) < 0) return JSON.stringify(economyReceipt(request, userId, "rejected", current.revision, "offer_mismatch", current));
  let selected: {[key: string]: any} | null = null;
  for (let index = 0; index < offer.approaches.length; index++) if (offer.approaches[index].approach_id === change.approach_id) selected = offer.approaches[index];
  if (!selected) return JSON.stringify(economyReceipt(request, userId, "rejected", current.revision, "approach_missing", current));
  if ((current.profile.fuel || 0) < selected.fuel_cost) return JSON.stringify(economyReceipt(request, userId, "rejected", current.revision, "insufficient_fuel", current));
  const now = Date.now();
  const updated: StoredCharacter = JSON.parse(JSON.stringify(current));
  updated.revision++; updated.profile.fuel = (updated.profile.fuel || 0) - selected.fuel_cost;
  updated.profile.active_hunt = {hunt_id: "hunt_" + request.command_id, offer_id: offer.offer_id, target_id: offer.target_id,
    approach_id: change.approach_id, role_id: offer.role_id, planet_id: offer.planet_id, accepted_at_unix_ms: now,
    resolves_at_unix_ms: now + effectiveHuntDuration(context, selected.duration_seconds) * 1000,
    power: selected.power, defense: selected.defense, health: selected.health, credits: selected.credits, xp: selected.xp,
    scrap: selected.scrap, loot_power: selected.loot_power, enemy_profile_id: selected.enemy_profile_id,
    enemy_modifiers: selected.enemy_modifiers, content_hash: CG_CONTENT_MANIFEST.content_hash,
    combat_profile: {class_id: current.profile.class_id, level: current.profile.level, base_power: current.profile.base_power,
      attributes: current.profile.attributes, equipment: current.profile.equipment}};
  return JSON.stringify(writeEconomy(nk, object, request, userId, fingerprint, updated));
}

function itemMetric(item: any, traitKey: string): number {
  if (!item || typeof item !== "object") return 0;
  return Number((item.trait || {})[traitKey] || 0);
}
function equipmentTotal(profile: CharacterProfile, metric: string): number {
  let total = 0; const equipment = profile.equipment || {};
  const slots = ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"];
  for (let index = 0; index < slots.length; index++) {
    const item = equipment[slots[index]] || {};
    if (metric === "power") total += Number(item.power || 0) + itemMetric(item, "power_bonus");
    else if (metric === "health") total += itemMetric(item, "health_bonus") + Number(item.integrity_upgrades || 0) * 8;
    else total += itemMetric(item, metric);
  }
  return total;
}
function classPreview(profile: CharacterProfile): any {
  const definition = catalogById(CG_CONTENT_MANIFEST.classes, profile.class_id) || {primary_attribute: "", effects: {}};
  const effects = definition.effects || {}; const attributes = profile.attributes || {};
  const investment = Math.max(0, Number(attributes[definition.primary_attribute] || 10) - 10);
  const powerStep = Number(effects.power_per_primary_points || 0);
  const reductionStep = Number(effects.damage_reduction_per_primary_points || 0);
  const counterStep = Number(effects.counter_damage_per_primary_points || 0);
  const bypassStep = Number(effects.defense_bypass_per_primary_points || 0);
  let attackBonus = Number(effects.base_attack_roll_bonus || 0) + investment * Number(effects.attack_roll_bonus_per_primary_point || 0);
  if (Number(effects.attack_roll_bonus_cap || 0) > 0) attackBonus = Math.min(attackBonus, Number(effects.attack_roll_bonus_cap));
  let evasion = Number(effects.base_evasion_chance || 0) + investment * Number(effects.evasion_per_primary_point || 0);
  if (Number(effects.evasion_cap || 0) > 0) evasion = Math.min(evasion, Number(effects.evasion_cap));
  let bypass = Number(effects.base_defense_bypass || 0) + (bypassStep > 0 ? Math.floor(investment / bypassStep) : 0);
  if (Number(effects.defense_bypass_cap || 0) > 0) bypass = Math.min(bypass, Number(effects.defense_bypass_cap));
  return {power: powerStep > 0 ? Math.floor(investment / powerStep) : 0,
    opening: Number(effects.base_opening_damage || 0) + investment * Number(effects.opening_damage_per_primary_point || 0),
    reduction: Number(effects.base_damage_reduction || 0) + (reductionStep > 0 ? Math.floor(investment / reductionStep) : 0),
    attack_bonus: attackBonus, evasion: evasion, bypass: bypass,
    counter: Number(effects.base_counter_damage || 0) + (counterStep > 0 ? Math.floor(investment / counterStep) : 0),
    counter_every: Number(effects.counter_every_rounds || 0), follow_threshold: Number(effects.follow_up_roll_threshold || 2),
    follow_ratio: Number(effects.follow_up_damage_ratio || 0)};
}
function playerCombat(profile: CharacterProfile): any {
  const attributes = profile.attributes || {strength: 10, vitality: 10, dexterity: 10, intelligence: 10, cunning: 10};
  const equipment = profile.equipment || defaultEquipment(); const armor = equipment.armor || {}; const preview = classPreview(profile);
  const weaponOrigin = String((equipment.weapon || {}).origin_planet_id || ""); const armorOrigin = String(armor.origin_planet_id || "");
  const setBonus = weaponOrigin !== "" && weaponOrigin === armorOrigin;
  return {power: Number(profile.base_power || 10) + equipmentTotal(profile, "power") + (setBonus ? 1 : 0) + Math.floor(Math.max(0, attributes.strength - 10) / 2) + preview.power,
    health: 72 + profile.level * 8 + Number(armor.power || 0) * 3 + equipmentTotal(profile, "health") + (setBonus ? 6 : 0) + Math.max(0, attributes.vitality - 10) * 4,
    armor: Number(armor.power || 0) + 3, opening: equipmentTotal(profile, "opening_damage_bonus") + Math.floor(Math.max(0, attributes.intelligence - 10) / 2) + preview.opening,
    reduction: equipmentTotal(profile, "damage_reduction") + Math.floor(Math.max(0, attributes.dexterity - 10) / 3) + preview.reduction,
    attack_bonus: Math.min(0.15, Math.max(0, attributes.cunning - 10) * 0.005) + preview.attack_bonus,
    evasion: Math.min(0.20, preview.evasion + equipmentTotal(profile, "evasion_chance_bonus")), bypass: preview.bypass + roundPositive(equipmentTotal(profile, "defense_bypass_bonus")), preview: preview};
}
function stableSeed(value: string): number {
  let seed = 2166136261;
  for (let index = 0; index < value.length; index++) seed = (seed ^ value.charCodeAt(index)) * 16777619 & 0x7fffffff;
  return Math.max(1, seed);
}
function combatRoller(seedValue: number): () => number {
  let state = seedValue;
  return function (): number { state = (state * 48271) % 2147483647; return state / 2147483647; };
}
function damageRoll(power: number, defense: number, roll: number): number {
  return Math.max(1, roundPositive(power * (0.82 + 0.36 * clamp(roll, 0, 1)) - defense * 0.45));
}
function resolveCombat(profile: CharacterProfile, active: any): any {
  const player = playerCombat(profile); const enemyProfile = active.enemy_modifiers || {};
  const openingMult = Number(enemyProfile.opening_damage_multiplier || 1); const attackBonusMult = Number(enemyProfile.attack_roll_bonus_multiplier || 1);
  const bypassMult = Number(enemyProfile.defense_bypass_multiplier || 1); const counterMult = Number(enemyProfile.counter_damage_multiplier || 1);
  const piercing = clamp(Number(enemyProfile.damage_reduction_piercing || 0), 0, 1);
  let playerHp = player.health; let enemyHp = active.health; let rounds = 0;
  const random = combatRoller(stableSeed([active.target_id, active.approach_id, profile.class_id, profile.level, active.content_hash].join("|")));
  while (playerHp > 0 && enemyHp > 0 && rounds < 100) {
    rounds++;
    const adjusted = clamp(random() + player.attack_bonus * attackBonusMult, 0, 1);
    const effectiveDefense = Math.max(0, active.defense - roundPositive(player.bypass * bypassMult));
    let primary = damageRoll(player.power, effectiveDefense, adjusted);
    if (rounds === 1) primary += roundPositive(player.opening * openingMult);
    enemyHp -= primary;
    if (enemyHp <= 0) break;
    if (adjusted >= player.preview.follow_threshold) enemyHp -= Math.max(1, roundPositive(primary * player.preview.follow_ratio));
    if (enemyHp <= 0) break;
    const enemyRoll = random();
    if (enemyRoll >= player.evasion) playerHp -= Math.max(1, damageRoll(active.power, player.armor, enemyRoll) - roundPositive(player.reduction * (1 - piercing)));
    if (playerHp > 0 && player.preview.counter_every > 0 && rounds % player.preview.counter_every === 0) enemyHp -= roundPositive(player.preview.counter * counterMult);
  }
  return {won: enemyHp <= 0, rounds: rounds, player_hp_remaining: Math.max(0, playerHp), enemy_hp_remaining: Math.max(0, enemyHp),
    player_power: player.power, player_max_health: player.health, target_power: active.power, target_health: active.health, content_hash: active.content_hash};
}

function validateCombatRuntime(): void {
  const base: any = {class_id: "orbit_gunslinger", level: 1, base_power: 10,
    attributes: {strength: 12, vitality: 10, dexterity: 12, intelligence: 12, cunning: 10}, equipment: defaultEquipment()};
  const breaker = JSON.parse(JSON.stringify(base)); breaker.class_id = "warrant_breaker";
  const hacker = JSON.parse(JSON.stringify(base)); hacker.class_id = "contract_hacker";
  const breakerBuild = playerCombat(breaker); const gunslingerBuild = playerCombat(base); const hackerBuild = playerCombat(hacker);
  if (breakerBuild.reduction !== 2 || breakerBuild.preview.counter_every !== 3 || gunslingerBuild.evasion !== 0.006
      || gunslingerBuild.preview.follow_ratio !== 0.1 || hackerBuild.opening !== 5 || hackerBuild.bypass !== 1) throw Error("Generated class combat identities failed runtime validation.");
  const offer = scaledOffer(CG_CONTENT_MANIFEST.planets[0], CG_CONTENT_MANIFEST.targets[0], CG_CONTENT_MANIFEST.roles[0], CG_CONTENT_MANIFEST.approaches[0], 1, 0);
  offer.content_hash = CG_CONTENT_MANIFEST.content_hash;
  if (!resolveCombat(base, offer).won) throw Error("Canonical starter recovery route failed runtime validation.");
}

function rpcHuntResolve(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context);
  const request = parsePayload(payload);
  const change = request.payload;
  if (!validCommandEnvelope(request, userId, "hunt_resolve") || !exactKeys(change, ["hunt_id"]) || !validIdentifier(change.hunt_id)) throw Error("Invalid hunt resolution command.");
  const object = readCharacter(nk, userId);
  if (!object) return JSON.stringify(economyReceipt(request, userId, "rejected", 0, "character_missing"));
  const current = canonicalState(object.value as StoredCharacter, userId);
  const fingerprint = [request.command_id, request.expected_revision, change.hunt_id].join("|");
  const replay = economyReplay(nk, request, userId, fingerprint, current);
  if (replay) return JSON.stringify(replay);
  if (request.expected_revision !== current.revision) return JSON.stringify(economyReceipt(request, userId, "conflict", current.revision, "revision_conflict", current));
  const active = current.profile.active_hunt || {};
  if (active.hunt_id !== change.hunt_id) return JSON.stringify(economyReceipt(request, userId, "rejected", current.revision, "hunt_missing", current));
  if (Date.now() < active.resolves_at_unix_ms) return JSON.stringify(economyReceipt(request, userId, "rejected", current.revision, "hunt_not_ready", current));
  const resolution = resolveCombat(active.combat_profile || current.profile, active);
  const updated: StoredCharacter = JSON.parse(JSON.stringify(current));
  updated.revision++; updated.profile.active_hunt = {};
  if (resolution.won) {
    const slots = ["weapon", "helmet", "armor", "gloves", "boots", "rig", "implant", "gadget", "relic"];
    const slot = slots[(current.profile.wins || 0) % slots.length];
    updated.profile.pending_reward = {reward_id: "reward_" + change.hunt_id, hunt_id: change.hunt_id, state: "sealed",
      credits: active.credits, xp: active.xp, scrap_reward: active.scrap, scrap_value: Math.max(1, Math.ceil(active.loot_power / 3)),
      item: {id: "drop_" + active.target_id + "_l" + String(current.profile.level) + "_" + slot, slot: slot,
        power: Math.max(1, roundPositive(active.loot_power * 0.55)), item_level: current.profile.level, origin_planet_id: active.planet_id}};
  }
  return JSON.stringify(writeEconomy(nk, object, request, userId, fingerprint, updated, resolution));
}

function xpNeeded(level: number): number {
  const offset = Math.max(0, level - 1);
  return 80 + offset * 45 + Math.floor((4 * offset * offset) / 5 + 0.5);
}

function applyXp(profile: CharacterProfile, amount: number): void {
  profile.xp += amount;
  while (profile.xp >= xpNeeded(profile.level)) {
    profile.xp -= xpNeeded(profile.level); profile.level++; profile.base_power = (profile.base_power || 10) + 2; profile.stat_points = (profile.stat_points || 0) + 2;
  }
}

function rpcRewardClaim(context: nkruntime.Context, _logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context);
  const request = parsePayload(payload);
  const change = request.payload;
  if (!validCommandEnvelope(request, userId, "reward_claim") || !exactKeys(change, ["hunt_id", "reward_id", "decision"])
      || !validIdentifier(change.hunt_id) || !validIdentifier(change.reward_id) || ["store", "equip", "recycle"].indexOf(change.decision) < 0) throw Error("Invalid reward claim command.");
  const object = readCharacter(nk, userId);
  if (!object) return JSON.stringify(economyReceipt(request, userId, "rejected", 0, "character_missing"));
  const current = canonicalState(object.value as StoredCharacter, userId);
  const fingerprint = [request.command_id, request.expected_revision, change.hunt_id, change.reward_id, change.decision].join("|");
  const replay = economyReplay(nk, request, userId, fingerprint, current);
  if (replay) return JSON.stringify(replay);
  if (request.expected_revision !== current.revision) return JSON.stringify(economyReceipt(request, userId, "conflict", current.revision, "revision_conflict", current));
  const pending = current.profile.pending_reward || {};
  if (pending.hunt_id !== change.hunt_id || pending.reward_id !== change.reward_id || pending.state !== "sealed") return JSON.stringify(economyReceipt(request, userId, "rejected", current.revision, "reward_missing", current));
  const updated: StoredCharacter = JSON.parse(JSON.stringify(current));
  updated.revision++; updated.profile.credits += pending.credits; updated.profile.scrap += Number(pending.scrap_reward || 0); applyXp(updated.profile, pending.xp);
  if (change.decision === "recycle") updated.profile.scrap += pending.scrap_value;
  else {
    (updated.profile.inventory as any[]).push(pending.item); updated.profile.inventory_count = (updated.profile.inventory as any[]).length;
    if (change.decision === "equip") (updated.profile.equipment as any)[pending.item.slot] = JSON.parse(JSON.stringify(pending.item));
    updated.profile.inventory_revision = (updated.profile.inventory_revision || 0) + 1;
  }
  updated.profile.wins = (updated.profile.wins || 0) + 1; updated.profile.pending_reward = {};
  return JSON.stringify(writeEconomy(nk, object, request, userId, fingerprint, updated, {decision: change.decision, item_id: pending.item.id}));
}

const InitModule: nkruntime.InitModule = function (_context: nkruntime.Context, logger: nkruntime.Logger, _nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  if (CG_CONTENT_MANIFEST.schema_version !== 1 || CG_CONTENT_MANIFEST.planets.length !== 35 || CG_CONTENT_MANIFEST.targets.length !== 140
      || CG_CONTENT_MANIFEST.approaches.length !== 3 || CG_CONTENT_MANIFEST.classes.length !== 3 || typeof CG_CONTENT_MANIFEST.content_hash !== "string" || CG_CONTENT_MANIFEST.content_hash.length !== 64) throw Error("Generated content manifest failed runtime integrity validation.");
  validateCombatRuntime();
  initializer.registerRpc("cg_clock", rpcCrookedGalaxyClock);
  initializer.registerRpc("cg_session", rpcSessionSummary);
  initializer.registerRpc("cg_character_get", rpcCharacterGet);
  initializer.registerRpc("cg_character_create", rpcCharacterCreate);
  initializer.registerRpc("cg_character_commit", rpcCharacterCommit);
  initializer.registerRpc("cg_economy_get", rpcEconomyGet);
  initializer.registerRpc("cg_build_get", rpcBuildGet);
  initializer.registerRpc("cg_agency_membership_get", rpcAgencyMembershipGet);
  initializer.registerRpc("cg_agency_directory", rpcAgencyDirectory);
  initializer.registerRpc("cg_agency_create", rpcAgencyCreate);
  initializer.registerRpc("cg_agency_apply", rpcAgencyApply);
  initializer.registerRpc("cg_attribute_allocate", rpcAttributeAllocate);
  initializer.registerRpc("cg_inventory_equip", rpcInventoryEquip);
  initializer.registerRpc("cg_inventory_recycle", rpcInventoryRecycle);
  initializer.registerRpc("cg_hunt_board", rpcHuntBoard);
  initializer.registerRpc("cg_hunt_accept", rpcHuntAccept);
  initializer.registerRpc("cg_hunt_resolve", rpcHuntResolve);
  initializer.registerRpc("cg_reward_claim", rpcRewardClaim);
  logger.info("Crooked Galaxy protocol v%d loaded for %s with content %s.", CG_API_VERSION, CG_SHARD_ID, CG_CONTENT_MANIFEST.content_hash.substr(0, 12));
};
