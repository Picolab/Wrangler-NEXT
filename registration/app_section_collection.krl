ruleset app_section_collection {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    shares nameFromID, showChildren, sections, wellKnown_Rx
  }
  global {
    nameFromID = function(section_id) {
      "Section " + section_id + " Pico"
    }
    showChildren = function() {
      wrangler:children()
    }
    sections = function() {
      ent:sections
    }
    wellKnown_Rx = function(section_id) {
      eci = ent:sections{[section_id,"eci"]}
      eci.isnull() => null
        | ctx:query(eci,"io.picolabs.subscription","wellKnown_Rx"){"id"}
    }
    tags = ["app_section_collection"]
    eventPolicy = {
      "allow": [
        { "domain": "section", "name": "*" },
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
  rule initialize_section_collection_pico {
    select when wrangler ruleset_installed
      where event:attr("rids") >< ctx:rid
    if ent:section_collection_pico_eci.isnull() then
      wrangler:createChannel(tags,eventPolicy,queryPolicy) setting(channel)
    fired {
      ent:section_collection_pico_eci := channel{"id"}
      ent:sections := {}
    }
  }
  rule section_already_exists {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections && ent:sections >< section_id
    }
    if exists then
      send_directive("section_ready", {"section_id":section_id})
  }
  rule section_needed {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections && ent:sections >< section_id
    }
    if not exists then noop()
    fired {
      raise wrangler event "new_child_request"
        attributes { "name": nameFromID(section_id),
                     "backgroundColor": "#ff69b4",
                     "section_id": section_id }
    }
  }
  rule section_offline {
    select when section offline
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
      eci_to_delete = ent:sections{[section_id,"eci"]}
    }
    if exists && eci_to_delete then
      send_directive("deleting_section", {"section_id":section_id})
    fired {
      raise wrangler event "child_deletion_request"
        attributes {"eci": eci_to_delete};
      clear ent:sections{[section_id]}
    }
  }
  rule store_new_section {
    select when wrangler new_child_created
    pre {
      the_section = {"eci": event:attr("eci")}
      section_id = event:attr("section_id")
    }
    if section_id.klog("found section_id") then
      event:send(
        { "eci": the_section.get("eci"), "eid": "install-ruleset",
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL":ctx:rid_url,
            "rid":"app_section",
            "config":{},
            "section_id":section_id
          }
        }
      )
    fired {
      ent:sections{section_id} := the_section
    }
  }
  rule accept_wellKnown {
    select when section identify
      section_id re#(.+)#
      wellKnown_eci re#(.+)#
      setting(section_id,wellKnown_eci)
    fired {
      ent:sections{[section_id,"wellKnown_eci"]} := wellKnown_eci
    }
  }
  rule identify_to_registration {
    select when wrangler ruleset_installed
      where event:attr("rids") >< ctx:rid
    pre {
      parent_eci = wrangler:parent_eci()
      wellKnown_eci = subs:wellKnown_Rx(){"id"}
    }
    event:send({"eci":parent_eci,
      "domain": "section", "type": "identify",
      "attrs": {
        "wellKnown_eci": wellKnown_eci
      }
    })
  }
  rule introduce_section_to_student {
    select when section add_request
    pre {
      wellKnown_Tx = event:attr("wellKnown_Tx")
      section_id = event:attr("section_id")
      name = event:attr("name")
      eci = wellKnown_Rx(section_id)
    }
    if eci then
      event:send({"eci":eci,
        "domain":"wrangler", "name":"subscription",
        "attrs":{
          "wellKnown_Tx":wellKnown_Tx,
          "Rx_role":"section", "Tx_role":"student",
          "name":name+"-"+section_id, "channel_type":"subscription",
          "section_id":section_id
        }
      })
  }
}
