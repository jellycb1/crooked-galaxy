const CG_API_VERSION = 1;
const CG_SHARD_ID = "international_1";
const CHARACTER_COLLECTION = "cg_characters_v1";
const CHARACTER_KEY = "primary";
const RECEIPT_COLLECTION = "cg_command_receipts_v1";

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

function snapshot(value: StoredCharacter): {[key: string]: any} {
  return {api_version: CG_API_VERSION, authority: "server", shard_id: CG_SHARD_ID, account_id: value.account_id,
    character_id: value.character_id, revision: value.revision, server_unix_ms: Date.now(), profile: value.profile};
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
  return JSON.stringify(snapshot(object.value as StoredCharacter));
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
    const replay = snapshot(existing.value as StoredCharacter);
    replay.created = false; replay.idempotent_replay = true;
    return JSON.stringify(replay);
  }
  if (readCharacter(nk, userId)) throw Error("Account already owns its launch character.");
  const value: StoredCharacter = {
    api_version: CG_API_VERSION, account_id: userId, character_id: userId, shard_id: CG_SHARD_ID, revision: 0,
    profile: {character_id: userId, hunter_name: request.hunter_name, class_id: request.class_id, species_id: request.species_id,
      appearance: appearance, level: 1, xp: 0, credits: 25, warp_chips: 0, scrap: 0}
  };
  nk.multiUpdate(null, [
    {collection: CHARACTER_COLLECTION, key: CHARACTER_KEY, userId: userId, value: value, version: "*", permissionRead: 0, permissionWrite: 0},
    {collection: RECEIPT_COLLECTION, key: idempotencyKey, userId: userId, value: {operation: "character_create", fingerprint: fingerprint}, version: "*", permissionRead: 0, permissionWrite: 0}
  ], null, null);
  logger.info("Created authoritative launch character for account %s.", userId);
  const response = snapshot(value); response.created = true; response.idempotent_replay = false;
  return JSON.stringify(response);
}

function commitReceipt(request: {[key: string]: any}, userId: string, status: string, revision: number, reason: string, state?: StoredCharacter): {[key: string]: any} {
  const response: {[key: string]: any} = {api_version: CG_API_VERSION, authority: "server", command_id: request.command_id,
    idempotency_key: request.idempotency_key, operation: "profile_commit", shard_id: CG_SHARD_ID, character_id: userId,
    status: status, server_revision: revision, server_unix_ms: Date.now(), reason_code: reason};
  if (state) response.snapshot = snapshot(state);
  return response;
}

function rpcCharacterCommit(context: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
  const userId = requireUser(context);
  const request = parsePayload(payload);
  if (Object.keys(request).length !== 9 || request.api_version !== CG_API_VERSION || !validIdentifier(request.command_id) || !validIdentifier(request.idempotency_key) || !validIdentifier(request.session_id) || request.operation !== "profile_commit" || request.shard_id !== CG_SHARD_ID || request.character_id !== userId || typeof request.expected_revision !== "number" || request.expected_revision < 0 || Math.floor(request.expected_revision) !== request.expected_revision) throw Error("Invalid profile command envelope.");
  const object = readCharacter(nk, userId);
  if (!object) return JSON.stringify(commitReceipt(request, userId, "rejected", 0, "character_missing"));
  const current = object.value as StoredCharacter;
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
    return JSON.stringify(commitReceipt(request, userId, "conflict", (latest.value as StoredCharacter).revision, "revision_conflict", latest.value as StoredCharacter));
  }
  logger.info("Committed character profile revision %d for account %s.", updated.revision, userId);
  return JSON.stringify(commitReceipt(request, userId, "accepted", updated.revision, "", updated));
}

const InitModule: nkruntime.InitModule = function (_context: nkruntime.Context, logger: nkruntime.Logger, _nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("cg_clock", rpcCrookedGalaxyClock);
  initializer.registerRpc("cg_session", rpcSessionSummary);
  initializer.registerRpc("cg_character_get", rpcCharacterGet);
  initializer.registerRpc("cg_character_create", rpcCharacterCreate);
  initializer.registerRpc("cg_character_commit", rpcCharacterCommit);
  logger.info("Crooked Galaxy protocol v%d loaded for %s.", CG_API_VERSION, CG_SHARD_ID);
};
