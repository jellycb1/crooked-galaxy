const CG_API_VERSION = 1;
const CG_SHARD_ID = "international_1";


function rpcCrookedGalaxyClock(
  context: nkruntime.Context,
  logger: nkruntime.Logger,
  _nakama: nkruntime.Nakama,
  _payload: string
): string {
  if (!context.userId) {
    throw Error("Authenticated session required.");
  }
  const serverUnixMs = Date.now();
  logger.debug("Authoritative clock sampled for user %s.", context.userId);
  return JSON.stringify({
    api_version: CG_API_VERSION,
    authority: "server",
    shard_id: CG_SHARD_ID,
    server_unix_ms: serverUnixMs
  });
}


const InitModule: nkruntime.InitModule = function (
  _context: nkruntime.Context,
  logger: nkruntime.Logger,
  _nakama: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {
  initializer.registerRpc("cg_clock", rpcCrookedGalaxyClock);
  logger.info("Crooked Galaxy protocol v%d loaded for %s.", CG_API_VERSION, CG_SHARD_ID);
};
