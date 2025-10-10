# frozen_string_literal: true

class LinkForCurrentLanguage < Liquid::Tag
  #======================================
  # initialize
  #======================================
  def initialize(tag_name, key, tokens)
    super
    @key = key.strip
  end

  #======================================
  # render
  #======================================
  def render(context)
    key = if context[@key].to_s == ""
      @key
    else # Check for page variable
      context[@key].to_s
    end

    key = Liquid::Template.parse(key).render(context) # Parses and renders some Liquid syntax on arguments (allows expansions)

    site = context.registers[:site]
    self.class.link(site, key)
  end

  class << self
    def link(site, key)
      multi_language_pages = site.pages.filter { |page| !page.data["page_id"].nil? }

      multi_language_pages.each do |page|
        next unless page["redirect_from"]

        return page["permalink"] if page["redirect_from"].include? key
      end

      key
    end
  end
end

Liquid::Template.register_tag("link_for_current_language", LinkForCurrentLanguage)
