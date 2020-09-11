ruleset app_section_collection {
  meta {
    shares nameFromID
  }
  global {
    nameFromID = function(section_id) {
      "Section " + section_id + " Pico"
    }
  }
  rule section_needed {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections && ent:sections >< section_id
    }
    if exists then
      send_directive("section_ready", {"section_id":section_id})
    notfired {
      ent:sections := ent:sections.defaultsTo([]).union([section_id])
      raise wrangler event "new_child_request"
        attributes { "name": nameFromID(section_id), "backgroundColor": "#ff69b4" }
    }
  }
}
