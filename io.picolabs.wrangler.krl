ruleset io.picolabs.wrangler {
  meta {
    version "0.0.0"
    provides channels, children, createChannel
    shares channels, rulesets, engine_ui_ruleset, rfc3986, parent_eci ,isThisMe
  }
  global {
    isThisMe = function(eci){
      ctx:channels.any(function(c){c{"id"}==eci})
    }
    channels = function(){
      ctx:channels
    }
    rulesets = function(){
      ctx:rulesets
    }
    children = function() {
      ctx:children
    }
    parent_eci = function() {
      ctx:parent
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
    rfc3986 = function(absoluteURL,rid){
      parts = absoluteURL.split("/")
      parts.splice(parts.length()-1,1,rid+".krl").join("/")
    }
    createChannel = defaction(tags,eventPolicy,queryPolicy){
      ctx:newChannel(
        tags=tags,
        eventPolicy=eventPolicy,
        queryPolicy=queryPolicy
      ) setting(channel)
      return channel
    }
  }
  rule create_child_pico {
    select when wrangler new_child_request
      name re#.+#
      backgroundColor re#.*#
    pre {
      name = event:attrs{"name"}
      backgroundColor = event:attrs{"backgroundColor"}
    }
    every {
      ctx:newPico(rulesets=[
        engine_ui_ruleset(),
        { "url": ctx:rid_url, "config": {} }
      ]) setting(newEci)
      ctx:eventQuery(
        eci=newEci,
        domain="engine_ui",
        name="setup",
        rid="io.picolabs.pico-engine-ui",
        queryName="uiECI"
      ) setting(newUiECI)
      ctx:event(
        eci=newUiECI,
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
  rule delete_child_pico {
    select when wrangler child_deletion_request
      eci re#^(.+)$# setting(eci)
    ctx:delPico(eci)
    fired {
      raise wrangler event "child_deleted"
        attributes event:attrs
    }
  }
  rule install_ruleset {
    select when wrangler install_ruleset_request
    pre {
      attr_url = event:attr("url")
      rid = event:attr("rid")
          || attr_url.extract(re#.*/([^/]+)[.]krl$#).head()
      url = attr_url || rfc3986(event:attr("absoluteURL"),rid)
      config = event:attr("config") || {}
    }
    ctx:install(url=url,config=config)
    fired {
      raise wrangler event "ruleset_installed"
        attributes event:attrs.put({"rids": [rid]})
    }
  }
}
