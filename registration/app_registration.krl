ruleset app_registration {
  meta {
    use module io.picolabs.wrangler alias wrangler
    shares sectionCollectionECI
  }
  global {
    sectionCollectionECI = function(){
      wrangler:children()
    }
  }
}
