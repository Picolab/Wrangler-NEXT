ruleset app_student {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    shares name, wellKnown_Rx, courses
  }
  global {
    name = function(){
      ent:name
    }
    wellKnown_Rx = function(){
      ent:wellKnown_Rx
    }
    courses = function(){
      subs:established()
    }
    tags = ["app_student"]
    eventPolicy = {
      "allow": [
        { "domain": "section", "name": "add" },
        { "domain": "section", "name": "drop" },
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
  rule capture_initial_state {
    select when wrangler ruleset_installed
      where event:attr("rids") >< ctx:rid
    if ent:student_eci.isnull() then
      wrangler:createChannel(tags,eventPolicy,queryPolicy) setting(channel)
    fired {
      ent:name := event:attr("name")
      ent:wellKnown_Rx := event:attr("wellKnown_Rx")
      ent:student_eci := channel{"id"}
    }
  }
}
