ruleset io.picolabs.wrangler {
  meta {
    version "0.0.0"
    shares channels, rulesets
  }
  global {
    channels = function(){
      ctx:channels
    }
    rulesets = function(){
      ctx:rulesets
    }
  }
  rule create_child_pico {
    select when wrangler new_child_request
      name re#.+#
    fired {
      raise engine_ui event "new" attributes event:attrs
    } else {
    }
  }
}
