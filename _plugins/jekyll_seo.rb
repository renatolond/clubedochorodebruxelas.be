# frozen_string_literal: true

module Jekyll
  class SeoTag
    # Monkey-patch of the SEO plugin to allow for localization of the description
    class Drop < Jekyll::Drops::Drop
      include Jekyll::SeoTag::UrlHelper

      def site_description
        @site_description ||= format_string site["description"][site["active_lang"]]
      end
    end
  end
end
