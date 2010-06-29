module HttpAcceptLanguage

  # Returns a sorted array based on user preference in HTTP_ACCEPT_LANGUAGE.
  # Browsers send this HTTP header, so don't think this is holy.
  #
  # Example:
  #
  #   request.user_preferred_languages
  #   # => [ 'nl-NL', 'nl-BE', 'nl', 'en-US', 'en' ]
  #
  def user_preferred_languages
    @user_preferred_languages ||= parse_accept_language_string(env['HTTP_ACCEPT_LANGUAGE'])
  rescue # Just rescue anything if the browser messed up badly.
    []
  end

  # Sets the user languages preference, overiding the HTTP Accept-Language header.
  # An array of strings is expected.
  #
  # Example:
  #
  #   request.user_preferred_languages = [ 'en-US', 'en-GB', 'en', 'fr-FR' ]
  #
  def user_preferred_languages=(languages)
    @user_preferred_languages = languages
  end

  # Finds the locale specifically requested by the browser.
  #
  # Example:
  #
  #   request.preferred_language_from I18n.available_locales
  #   # => 'nl'
  #
  def preferred_language_from(array)
    (user_preferred_languages & array.collect { |i| i.to_s }).first
  end

  # Returns the first of the user_preferred_languages that is compatible
  # with the available locales. Ignores region.
  #
  # Example:
  #
  #   request.compatible_language_from I18n.available_locales
  #
  def compatible_language_from(array)
    user_preferred_languages.map do |x|
      array.find do |y|
        y.to_s =~ /^#{Regexp.escape(x.to_s)}(-|$)/
      end
    end.compact.first
  end

  # Parses the HTTP Accept-Language header as specified in RFC 2616, returning
  # an array of strings representing the prioritized locales with capitalization
  # normalized.
  #
  # Example:
  #
  #   request.parse_accept_language_string 'da, en-gb;q=0.8, en;q=0.7, FR-FR;q=0.9'
  #   # => [ 'da', 'fr-FR', 'en-GB', 'en' ]
  #
  def parse_accept_language_string(string)
    string.split(/\s*,\s*/).collect do |l|
      l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
      l.split(';q=')
    end.sort do |x,y|
      raise "Not correctly formatted" unless x.first =~ /^[a-z\-]+$/i
      y.last.to_f <=> x.last.to_f
    end.collect do |l|
      l.first.downcase.gsub(/-[a-z]+$/i) { |x| x.upcase }
    end
  end
end
if defined?(ActionDispatch::Request)
  ActionDispatch::Request.send :include, HttpAcceptLanguage
elsif defined?(ActionDispatch::AbstractRequest)
  ActionDispatch::AbstractRequest.send :include, HttpAcceptLanguage
elsif defined?(ActionDispatch::CgiRequest)
  ActionDispatch::CgiRequest.send :include, HttpAcceptLanguage
end
