ruleset io.picolabs.wrangler {
  meta {
    version "0.0.0"
    use module io.picolabs.pico-engine-ui alias ui
    shares channels, rulesets, engine_ui_ruleset, box
  }
  global {
    channels = function(){
      ctx:channels
    }
    rulesets = function(){
      ctx:rulesets
    }
    engine_ui_rid = "io.picolabs.pico-engine-ui"
    engine_ui_ruleset = function(){
      the_ruleset = rulesets()
        .filter(function(r){r.get("rid")==engine_ui_rid})
        .head();
      { "url":the_ruleset.get("url"),
        "config":the_ruleset.get("config")
      }
    }
    box = function(){
      ui:box()
    }
  }
  rule create_child_pico {
    select when wrangler new_child_request
      name re#.+#
      backgroundColor re#.*#
    pre {
      name = event:attrs{"name"}
      backgroundColor = event:attrs{"backgroundColor"}
      //x = event:attrs.get("x") || ui:box().get("x")+10
      //y = event:attrs.get("y") || ui:box().get("y")+10
    }
    every {
      ctx:newPico(rulesets=[
        engine_ui_ruleset(),
        { "url": ctx:rid_url, "config": {} }
      ].klog("rulesets")) setting(newEci)
      ctx:eventQuery(
        eci=newEci.klog("newEci"),
        domain="engine_ui",
        name="setup",
        rid="io.picolabs.pico-engine-ui",
        queryName="uiECI"
      ) setting(newUiECI)
      ctx:event(
        eci=newUiECI.klog("newUiECI"),
        domain="engine_ui",
        name="box",
        attrs={
          "name": name,
          "backgroundColor": backgroundColor
        }
      )
    }
    fired {
      raise wrangler event "new_child_created"
        attributes event:attrs.put({"eci":newEci})
    } else {
      raise wrangler event "child_creation_failure"
        attributes event:attrs
    }
  }
}
