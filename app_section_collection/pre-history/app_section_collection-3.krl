ruleset app_section_collection {
  meta {
    use module io.picolabs.wrangler alias wrangler
    shares nameFromID, showChildren, sections
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
  }
  rule initialize_sections {
    select when section needs_initialization
    always {
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
}
