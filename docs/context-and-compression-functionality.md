/*
 * This is captured from a discussion with Claude
 * regarding Context management and Compression.
 * Includes analysis of runtime binary v2.1.92.
 */


  ---
  How Conversations & Context Compression Work in Claude Code

  Message Format

  Every message in a conversation is an object with this shape (from n$() at the message factory):

  {
    type: "user" | "assistant" | "system",
    message: {
      role: "user" | "assistant",
      content: [...content blocks...]  // text, tool_use, tool_result, image, document, thinking, compaction
    },
    uuid: string,
    timestamp: string,
    // metadata flags:
    isMeta: bool,           // injected system messages (not user-authored)
    isCompactSummary: bool, // this message IS a compaction summary
    isVirtual: bool,        // synthetic message
    isVisibleInTranscriptOnly: bool,
    toolUseResult: string,
    permissionMode: string,
  }

  Transcripts are written as line-delimited JSON to disk, accessible via $TRANSCRIPT_PATH.

  The Main Conversation Loop

  The core loop is the generator tC() → Ko9(). Each iteration of the loop:

  1. Microcompact (RF) — clears old tool result content from messages that are stale (based on time gaps). Replaces with "[Old tool result content
  cleared]". This is cheap and local (no API call).
  2. Autocompact check (M57) — checks if token usage exceeds the autocompact threshold
  3. API call — streams the response from Claude
  4. Tool execution — runs any tool_use blocks
  5. Stop hook — checks if the session should stop
  6. Loop — if there were tool uses, go back to step 1

  Context Window Math

  The key functions, deobfuscated:

  effectiveWindow(model, userOverride) = contextWindow(model) - min(maxOutputTokens(model), 20000)

  autoCompactThreshold(model, userOverride) = effectiveWindow - 13000   (G86 = 13000 token buffer)

  warningThreshold  = effectiveWindow - 20000   (do9)
  errorThreshold    = effectiveWindow - 20000   (Fo9)
  blockingLimit     = effectiveWindow - 3000    (Z86 = 3000 token buffer)

  So for a 200k context model with 8k max output:
  - effective window: ~192k
  - autocompact triggers at: ~179k tokens
  - hard block at: ~189k tokens

  The /autocompact command lets users set autoCompactWindow between 100k-1M tokens.

  Compaction Flow (function vEH)

  When autocompact triggers or user runs /compact:

  1. PreCompact hook fires — plugins can inject info to preserve
  2. Images/documents stripped from messages (function Zo9) — replaced with [image] / [document] text placeholders
  3. Summarization API call — sends messages to Claude with the summarizer prompt (Po9), asking for a structured summary with <analysis> and <summary>
  sections
  4. Tool use blocked during compaction — ko9() returns deny for all tools
  5. Result assembled — Ea() combines: [boundaryMarker, ...summaryMessages, ...messagesToKeep, ...attachments, ...hookResults]
  6. Summary injected as a user message with isCompactSummary: true, prefixed with:

  ▎ "This session is being continued from a previous conversation that ran out of context..."

  Plus instructions to resume directly without acknowledging the summary.

  The Summarizer Prompt

  The summarizer (Po9) asks for 9 sections:
  1. Primary Request and Intent
  2. Key Technical Concepts
  3. Files and Code Sections (with full snippets)
  4. Errors and fixes
  5. Problem Solving
  6. All user messages (non-tool-result)
  7. Pending Tasks
  8. Current Work
  9. Optional Next Step

  It wraps analysis in <analysis> tags, then produces a <summary>. The prompt ends with a hard reminder: "Do NOT call any tools. Tool calls will be
  rejected."

  Microcompact (function RF)

  A lightweight, pre-API optimization:
  - Detects time gaps in the conversation
  - Clears old tool result content (replaces with "[Old tool result content cleared]")
  - Keeps recent tool results (within keepRecent window)
  - No API call — just local token savings

  Safety Mechanisms

  ┌───────────────────────────────────┬───────┬──────────────────────────────────────────────────────────────────┐
  │             Constant              │ Value │                             Purpose                              │
  ├───────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────┤
  │ fA7 (max consecutive failures)    │ 3     │ Circuit breaker — stops autocompact after 3 failures             │
  ├───────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────┤
  │ OA7 (max rapid refills)           │ 3     │ Thrash detector — stops if context refills 3x rapidly            │
  ├───────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────┤
  │ L86 (rapid refill turn threshold) │ 3     │ A refill is "rapid" if it happens within 3 turns of last compact │
  ├───────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────┤
  │ B57 (max compaction retries)      │ 5     │ Per-compaction retry limit                                       │
  ├───────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────┤
  │ Xo9 (large tool result threshold) │ 50000 │ Tool results >50k chars get persisted to disk                    │
  └───────────────────────────────────┴───────┴──────────────────────────────────────────────────────────────────┘

  Environment Variable Overrides

  - DISABLE_COMPACT / DISABLE_AUTO_COMPACT — disables compaction entirely
  - CLAUDE_AUTOCOMPACT_PCT_OVERRIDE — override autocompact threshold as a percentage (0-100) of effective window
  - CLAUDE_CODE_BLOCKING_LIMIT_OVERRIDE — override the hard blocking limit (in tokens)
  - CLAUDE_CODE_MAX_OUTPUT_TOKENS — respected during compaction for effective window calculation
  - CLAUDE_CODE_DISABLE_1M_CONTEXT — force smaller context window

  Partial Compaction ("Summarize from here")

  Function U57 handles partial compaction — summarizes only messages before a user-selected point, keeping everything after verbatim. Supports both
  prefix-preserving and suffix-preserving modes.

  Reactive Compaction

  When an API call fails with prompt_too_long, the system can attempt a reactive compact — compacting on-the-fly and retrying, tracked by
  hasAttemptedReactiveCompact to avoid infinite loops.

  Max Output Token Recovery

  If output hits the token limit mid-response, the system injects:

  ▎ "Output token limit hit. Resume directly — no apology, no recap of what you were doing. Pick up mid-thought if that is where the cut happened.
  Break remaining work into smaller pieces."

  And retries up to qo9 times (the max output token recovery count).

