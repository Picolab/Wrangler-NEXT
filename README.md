# Wrangler-NEXT
Creation of a ruleset for operating picos in the pico-engine NEXT

## Organization of this repository

As in the current pico-engine (version 0.52.4) this ruleset is named `io.picolabs.wrangler`.

The ruleset is being created incrementally, and the history before this repo was created is shown
in a `pre-history` folder.
The remainder of its development will be recorded in the usual way,
by successive commits.

Two additional rulesets are included here,
as their development drove the accretion of rules and functions in Wrangler itself.

## Guidelines for development

1. Provide useful wrappers for what is exposed directly by the pico-engine (the `ctx` object)
1. Use careful naming conventions for functions provided by Wrangler
1. Use `wrangler` as the event domain for all rules
1. Use a noun or noun phrase as the event type for all rules
1. Use a verb or verb phrase for each rule name
1. Raise events with `wrangler` as the domain and a noun phrase for the type for every action taken by Wrangler

## Functions provided

- `channels` returns all the channels of this pico
- `rulesets` returns all the rulesets of this pico
- `children` returns all the children of this pico

## Events expected and event(s) raised when actions are taken

- `wrangler:new_child_request` attributes `name`, `backgroundColor`, and others from user
  - raise event `wrangler:new_child_created` attributes passed in and `eci` of created pico
  - raise event `wrangler:child_creation_failed` attributes passed in

- `wrangler:child_deletion_request` attribute `eci` (which must be the "family" ECI)
  - raise event `wrangler:child_deleted` attributes passed in
  
