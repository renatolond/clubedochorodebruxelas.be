# frozen_string_literal: true

##############################################################################
# class LocalizeTag
#
# Localization by getting localized text from YAML files.
# User must use the "t" or "translate" liquid tags.
##############################################################################
class LocalizeTag < Liquid::Tag
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

    site = context.registers[:site] # Jekyll site object

    translation = self.class.translate(site, key)

    translation
  end

  class << self
    def translate(site, key)
      lang = site.config["active_lang"]

      splitted_key = key.split(".")
      translation = site.data.dig(lang, "translations", *splitted_key) if key.is_a?(String)

      if translation.nil? || translation.empty?
        translation = site.data.dig(site.config["default_lang"], "translations", *splitted_key)

        if site.config["verbose"]
          puts "Missing i18n key: #{lang}:#{key}"
            puts format("Using translation '%<translation>s' from default language: %<default_language>s", translation: translation, default_language: site.config["default_lang"])
        end
      end

      translation
    end
  end
end

Liquid::Template.register_tag("t",         LocalizeTag)
Liquid::Template.register_tag("translate", LocalizeTag)
