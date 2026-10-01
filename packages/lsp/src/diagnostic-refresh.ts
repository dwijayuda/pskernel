export function diagnosticRefreshUris(
  openUris:readonly string[],
):readonly string[] {
  return [...new Set(openUris)];
}
