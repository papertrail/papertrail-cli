require 'delegate'
require 'net/https'
if RUBY_VERSION < '1.9'
  # Ruby 1.8 doesn't have json in the standard lib - so we have to use okjson
  require 'papertrail/okjson'
else
  require 'json'
end

module Papertrail

  # Used because Net::HTTPOK in Ruby 1.8 has no body= method
  class HttpResponse < SimpleDelegator

    def initialize(response)
      super(response)
    end

    def body
      if RUBY_VERSION < '1.9'
        # This is really slow. Avoid it if possible (by upgrading ruby)
        if __getobj__.body.respond_to?(:force_encoding)
          @body ||= Papertrail::OkJson.decode(__getobj__.body.dup.force_encoding('UTF-8'))
        else
          @body ||= Papertrail::OkJson.decode(__getobj__.body.dup)
        end
      else
        @body ||= JSON.parse(__getobj__.body.dup)
      end
    end

  end

  class HttpClient
    ESCAPE_RE = /[^a-zA-Z0-9 .~_-]/

    def initialize(ssl)
      @ssl = ssl
      @headers = {}
    end

    def basic_auth(login, pass)
      @headers['Authorization'] = 'Basic ' + ["#{login}:#{pass}"].pack('m').delete("\r\n")
    end

    def token_auth(token)
      @headers['X-Papertrail-Token'] = token
    end

    def get(path, params = {})
      if params.size > 0
        path = "#{path}?#{build_nested_query(params)}"
      end
      attempts = 0
      begin
        on_complete(https.get(request_uri(path), @headers))
      rescue SystemCallError, Net::HTTPFatalError => e
        sleep 5.0
        attempts += 1
        retry if (attempts < 3)
        raise e
      end
    end

    def put(path, params)
      attempts = 0
      begin
        on_complete(https.put(request_uri(path), build_nested_query(params), @headers))
      rescue SystemCallError, Net::HTTPFatalError => e
        attempts += 1
        retry if (attempts < 3)
        raise e
      end
    end

    def post(path, params)
      attempts = 0
      begin
        on_complete(https.post(request_uri(path), build_nested_query(params), @headers))
      rescue SystemCallError, Net::HTTPFatalError => e
        attempts += 1
        retry if (attempts < 3)
        raise e
      end
    end

    def delete(path)
      attempts = 0
      begin
        on_complete(https.delete(request_uri(path), @headers))
      rescue SystemCallError, Net::HTTPFatalError => e
        attempts += 1
        retry if (attempts < 3)
        raise e
      end
    end

    private

    def request_uri(path)
      path.start_with?('/api/v1/') ? path : "/api/v1/#{path}"
    end

    def https
      http = Net::HTTP.new('papertrailapp.com', 443)
      http.use_ssl      = true
      http.verify_mode  = ssl_verify_mode
      http.cert_store   = ssl_cert_store

      http.cert         = @ssl[:client_cert]  if @ssl[:client_cert]
      http.key          = @ssl[:client_key]   if @ssl[:client_key]
      http.ca_file      = @ssl[:ca_file]      if @ssl[:ca_file]
      http.ca_path      = @ssl[:ca_path]      if @ssl[:ca_path]
      http.verify_depth = @ssl[:verify_depth] if @ssl[:verify_depth]
      http.ssl_version  = @ssl[:version]      if @ssl[:version]

      http
    end

    def ssl_verify_mode
      @ssl[:verify_mode] || begin
        if @ssl.fetch(:verify, true)
          OpenSSL::SSL::VERIFY_PEER
        else
          OpenSSL::SSL::VERIFY_NONE
        end
      end
    end

    def ssl_cert_store
      return @ssl[:cert_store] if @ssl[:cert_store]
      # Use the default cert store by default, i.e. system ca certs
      cert_store = OpenSSL::X509::Store.new
      cert_store.set_default_paths
      cert_store
    end

    def on_complete(response)
      case response
        when Net::HTTPSuccess
          Papertrail::HttpResponse.new(response)
        else
          response.error!
      end
    end

    def build_nested_query(value, prefix = nil)
      case value
        when Array
          value.map { |v| build_nested_query(v, "#{prefix}%5B%5D") }.join("&")
        when Hash
          value.map { |k, v|
            build_nested_query(v, prefix ? "#{prefix}%5B#{escape(k)}%5D" : escape(k))
          }.join("&")
        when NilClass
          prefix
        else
          raise ArgumentError, "value must be a Hash" if prefix.nil?
          "#{prefix}=#{escape(value)}"
      end
    end

    def escape(s)
      s.to_s.gsub(ESCAPE_RE) {
        '%' + $&.unpack('H2' * $&.bytesize).join('%').upcase
      }.tr(' ', '+')
    end
  end

end
