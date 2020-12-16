ruleset app_registration {
  meta {
    use module io.picolabs.wrangler alias wrangler
    shares sectionCollectionECI
  }
  global {
    section_collection_name = "Section Collection Pico"
    sectionCollectionECI = function(){
      ent:sectionCollectionECI
    }
    tags = ["app_registration"]
    eventPolicy = {
      "allow": [
        { "domain": "student", "name": "arrives" },
      ],
      "deny": []
    }
    queryPolicy = {
      "allow": [
        { "rid": ctx:rid, "name": "*" }
      ],
      "deny": []
    }
  }
  rule initialize_app_registration {
    select when wrangler ruleset_installed
      where event:attr("rids") >< ctx:rid
    if ent:registration_eci.isnull() then
      wrangler:createChannel(tags,eventPolicy,queryPolicy) setting(channel)
    fired {
      ent:registration_eci := channel{"id"}
      raise wrangler event "new_child_request" attributes {
        "name":"Section Collection Pico",
        "backgroundColor":"#6CFFC9"
      }
    }
  }
  rule initialize_section_collection_pico {
    select when wrangler new_child_created
      name re#^Section Collection Pico$#
    pre {
      eci = event:attr("eci")
    }
    event:send({"eci":eci,
      "domain":"wrangler", "type":"install_ruleset_request",
      "attrs":event:attrs.put({
        "absoluteURL":ctx:rid_url,
        "rid":"app_section_collection",
      })
    })
  }
  rule allow_student_to_register {
    select when student arrives
      name re#(.+)# setting(name)
    pre {
      backgroundColor = event:attr("backgroundColor") || "#CCCCCC"
    }
    event:send({"eci":wrangler:parent_eci(),
      "domain":"wrangler", "type":"new_child_request",
      "attrs":{
        "name":name,
        "backgroundColor": backgroundColor,
        "wellKnown_Rx":sectionCollectionECI()
      }
    })
  }
  rule accept_wellKnown {
    select when section identify
      wellKnown_eci re#(.+)#
      setting(wellKnown_eci)
    fired {
      ent:sectionCollectionECI := wellKnown_eci
    }
  }
}
