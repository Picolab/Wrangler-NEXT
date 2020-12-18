ruleset app_student {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    shares name, wellKnown_Rx, classes
  }
  global {
    name = function(){
      ent:name
    }
    wellKnown_Rx = function(){
      ent:wellKnown_Rx
    }
    classes = function(){
      ent:classes.values()
    }
    tags = ["app_student"]
    eventPolicy = {
      "allow": [
        { "domain": "section", "name": "add_request" },
        { "domain": "section", "name": "drop_request" },
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
      ent:classes := {}
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
  rule auto_accept_add {
    select when wrangler inbound_pending_subscription_added
      Rx_role re#^student$#
      Tx_role re#^section$#
    pre {
      section_id = event:attr("section_id")
    }
    if section_id then noop()
    fired {
      ent:classes{event:attr("Id")} := section_id
      raise wrangler event "pending_subscription_approval"
        attributes event:attrs
      raise student event "section_added" attributes event:attrs
      last
    }
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
      ent:subscriptionTx := event:attr("Tx")
    } else {
      raise wrangler event "inbound_rejection"
        attributes event:attrs
    }
  }
  rule add_a_class {
    select when section add_request
      section_id re#(.+)# setting(section_id)
    pre {
      already_enrolled = classes() >< section_id
    }
    if not already_enrolled then
      event:send({"eci":ent:subscriptionTx,
        "domain":"section", "name":"add_request",
        "attrs":{
          "wellKnown_Tx":subs:wellKnown_Rx(){"id"},
          "section_id":section_id,
          "name":ent:name
        }
      })
  }
}
