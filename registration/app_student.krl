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
        { "domain": "student", "name": "new_subscription_request" },
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
      raise student event "new_subscription_request"
    }
  }
  rule make_a_subscription {
    select when student new_subscription_request
    event:send({"eci":ent:wellKnown_Rx,
      "domain":"wrangler", "name":"subscription",
      "attrs": {
        "wellKnown_Tx":subs:wellKnown_Rx(){"id"},
        "Rx_role":"registration", "Tx_role":"student",
        "name":ent:name+"-registration", "channel_type":"subscription"
      }
    })
  }
  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      my_role = event:attr("Rx_role")
      their_role = event:attr("Tx_role")
    }
    if my_role=="student" && their_role=="registration" then noop()
    fired {
      raise wrangler event "pending_subscription_approval"
        attributes event:attrs
      ent:subscriptionId := event:attr("Id")
    } else {
      raise wrangler event "inbound_rejection"
        attributes event:attrs
    }
  }
}
