# frozen_string_literal: true

require "jekyll-polyglot"

module Jekyll
  # Monkey-patch the polyglot implementation to warn about an untranslated page
  class Site
    # assigns natural permalinks to documents and prioritizes documents with
    # active_lang languages over others.  If lang is not set in front matter,
    # then this tries to derive from the path, if the lang_from_path is set.
    # otherwise it will assign the document to the default_lang
    def coordinate_documents(docs)
      regex = document_url_regex
      approved = {}
      docs.each do |doc|
        lang = doc.data["lang"] || derive_lang_from_path(doc) || @default_lang
        lang_exclusive = doc.data["lang-exclusive"] || []
        url = doc.url.gsub(regex, "/")
        page_id = doc.data["page_id"] || url
        doc.data["permalink"] = url if doc.data["permalink"].to_s.empty? && !doc.data["lang"].to_s.empty?

        # skip entirely if nothing to check
        next if @file_langs.nil?
        # skip this document if it has already been processed
        next if @file_langs[page_id] == @active_lang
        # skip this document if it has a fallback and it isn't assigned to the active language
        next if @file_langs[page_id] == @default_lang && lang != @active_lang
        # skip this document if it has lang-exclusive defined and the active_lang is not included
        next if !lang_exclusive.empty? && !lang_exclusive.include?(@active_lang)

        doc.data["different_language_warning"] = true if @active_lang != doc["lang"]
        approved[page_id] = doc
        @file_langs[page_id] = lang
      end
      approved.each_value do |doc|
        assignPageRedirects(doc, docs)
        assignPageLanguagePermalinks(doc, docs)
      end
      approved.values
    end
  end
end
