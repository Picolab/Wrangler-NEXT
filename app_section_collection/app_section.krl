ruleset app_section {
  meta {
    shares sectionID
  }
  global {
    sectionID = function() {
      ent:section_id
    }
  }
  rule pico_ruleset_added {
    select when wrangler ruleset_installed
      where event:attr("rids") >< ctx:rid
    pre {
      section_id = event:attr("section_id")
    }
    always {
      ent:section_id := section_id
    }
  }
}
