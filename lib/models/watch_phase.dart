/// The lifecycle of the watch.
///
/// idle -> (tap core) -> transforming -> transformed -> (timeout) ->
/// recharging -> idle. Reverting manually from transformed goes straight
/// back to idle.
enum WatchPhase {
  /// Dial can be turned; selected alien is shown as a silhouette.
  idle,

  /// Charge-up and flash after the core was tapped.
  transforming,

  /// Alien is active and the timeout countdown is running.
  transformed,

  /// Watch timed out and is cooling down; input is locked.
  recharging,
}
