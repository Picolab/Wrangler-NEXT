ruleset io.picolabs.wrangler {
  meta {
    version "0.0.0"
    provides createPico
  }
  global {
    createPico = defaction(name,rid_urls){
      ctx:newPico(rid_urls) setting(the_pico)
      return the_pico
    }
  }
}
