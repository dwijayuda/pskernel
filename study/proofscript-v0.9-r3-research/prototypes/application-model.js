"use strict";

function success(value) { return { tag: "success", value }; }
function failure(error) { return { tag: "failure", error }; }
function cancelled(reason) { return { tag: "cancelled", reason }; }
function panic(error) { return { tag: "panic", error }; }

function finalizeResource(bodyExit, releaseExit) {
  const trace = ["acquired", "body:" + bodyExit.tag, "release:" + releaseExit.tag];
  if (releaseExit.tag === "success") {
    return { trace, exit: bodyExit };
  }
  if (bodyExit.tag === "success") {
    return { trace, exit: releaseExit };
  }
  return {
    trace,
    exit: {
      tag: "cleanupFailure",
      body: bodyExit,
      cleanup: releaseExit
    }
  };
}

function raceModel(firstTerminal, secondTerminal) {
  const winner = firstTerminal;
  const loser = secondTerminal;
  return {
    trace: [
      "winner:" + winner.name + ":" + winner.exit.tag,
      "cancel-request:" + loser.name,
      "cleanup-awaited:" + loser.name,
      "scope-complete"
    ],
    exit: winner.exit
  };
}

module.exports = { success, failure, cancelled, panic, finalizeResource, raceModel };
