# Installing multiple rulesets
## On the wrangler side: two ways to install them one at a time

For how this looks when it's being used, see [this page](https://github.com/Picolab/aries-cloudagent-pico/blob/master/NEXT/installation.md)

### Installing one ruleset using one rule

```
  rule install_ruleset {
    select when wrangler install_ruleset_request
    pre {
      rfc3986 = function(absoluteURL,rid){
        parts = absoluteURL.split("/")
        parts.splice(parts.length()-1,1,rid+".krl").join("/")
      }
      attr_url = event:attr("url")
      rid = event:attr("rid")
          || attr_url.extract(re#.*/([^/]+)[.]krl$#).head()
      url = attr_url || rfc3986(event:attr("absoluteURL"),rid)
      config = event:attr("config").defaultsTo({})
    }
    ctx:install(url,config)
    fired {
      raise wrangler event "ruleset_installed"
        attributes event:attrs.put({"rids": [rid]})
    }
  }
```
  
### Installing one ruleset using two rules
  
```
  rule install_relative_ruleset {
    select when wrangler install_ruleset_request
      absoluteURL re#(.+)#   // required
      rid re#(.+)#           // required
      setting(absoluteURL,rid)
    pre {
      parts = absoluteURL.split("/")
      url = parts.splice(parts.length()-1,1,rid+".krl").join("/")
    }
    fired {
      raise wrangler event "install_ruleset_request"
        attributes {"url":url, "config":event:attr("config")}
    }
  }
  
  rule install_absolute_ruleset {
    select when wrangler install_ruleset_request
      url re#(.+)#           // required
      setting(url)
    pre {
      rid = url.extract(re#.*/([^/]+)[.]krl$#).head()
    }
    ctx:install(url,event:attr("config").defaultsTo({}))
    fired {
      raise wrangler event "ruleset_installed"
        attributes event:attrs.put({"rids": [rid]})
    }
  }
```
  
## A suggested wrangler rule to install multiple URLs
  
```
  rule installRulesets {
    select when wrangler install_rulesets_request
    foreach event:attr("urls") setting (url)
      pre {
        rid = url.extract(re#.*/([^/]+)[.]krl$#).head()
      }
      every{
        ctx:install(url, event:attr("config").defaultsTo({}))
        send_directive("ruleset installed", { "rid": rid })
      }
      fired {
        raise wrangler event "ruleset_installed"
          attributes {"rids":[rid]}
        raise wrangler event "finish_initialization" on final
      }
  }
```
### Variant, building on one ruleset at at time rule
  
```
  rule installRulesets {
    select when wrangler install_rulesets_request
    foreach event:attr("urls") setting (url)
      fired {
        raise wrangler event "install_ruleset_request"
          attributes {"url":url,"config":event:attr("config")}
        raise wrangler event "finish_initialization" on final
      }
  }
```
  
### Variant, using an array of configs parallel to the array of URLs
  
```
  rule installRulesets {
    select when wrangler install_rulesets_request
    foreach [event:attr("urls"),event:attr("configs")].pairwise(function(a,b){[a,b]}) setting(pair)
      pre {
        url = pair.head()
        config = pair[1]
      }
      fired {
        raise wrangler event "install_ruleset_request"
          attributes {"url":url,"config":config}
        raise wrangler event "finish_initialization" on final
      }
}
```
  
