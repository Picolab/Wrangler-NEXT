ruleset app_system {
  rule create_registration_pico {
    select when wrangler ruleset_installed
      where event:attr("rids") >< ctx:rid
    pre {
      registration_pico_eci = ent:registration_pico_eci
    }
    if registration_pico_eci.isnull() then noop()
    fired {
      raise wrangler event "new_child_request" attributes {
        "name":"Registration Pico"
      }
    }
  }
  rule initialize_registration_pico {
    select when wrangler new_child_created
      name re#^Registration Pico$#
    pre {
      eci = event:attr("eci")
    }
    event:send({"eci":eci,
      "domain":"wrangler", "type":"install_ruleset_request",
      "attrs":event:attrs.put({
        "absoluteURL":ctx:rid_url,
        "rid":"app_registration",
      })
    })
  }
  rule initialize_child {
    select when wrangler new_child_created
      name re#(.+)#
      wellKnown_Rx re#(.+)#
      setting(name,wellKnown_Rx)
    pre {
      eci = event:attr("eci")
    }
    event:send({"eci":eci,
      "domain":"wrangler", "type":"install_ruleset_request",
      "attrs":event:attrs.put({
        "absoluteURL":ctx:rid_url,
        "rid":"app_student",
      })
    })
  }
}
