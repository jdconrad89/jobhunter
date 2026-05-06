begin
  require "webpacker/helper"

  module WebpackerMissingEntryFallback
    def javascript_pack_tag(*names, **options)
      super
    rescue Webpacker::Manifest::MissingEntryError
      ""
    end

    def stylesheet_pack_tag(*names, **options)
      super
    rescue Webpacker::Manifest::MissingEntryError
      ""
    end
  end

  Webpacker::Helper.prepend(WebpackerMissingEntryFallback)
rescue LoadError
  # Webpacker not present in this environment.
end
