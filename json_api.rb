require 'net/https'
require 'uri'
require 'cgi'
require 'json'

require 'rubygems'
require 'hashie'

class JsonAPI
  def connect(url, get={})
    params = get.map{ |pair| pair.map{ |x| CGI.escape(x.to_s) }.join('=') }
    uri = URI.parse(url + '?' + params.join('&'))
    # TODO pass get in Get.new ?
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    request['accept-encoding'] = 'gzip'
    response = http.request(request)
    validate(response.kind_of?(Net::HTTPSuccess),
            "could not connect to #{uri}: #{response}")
    if response['content-encoding'] == 'gzip'
      response.body = Zlib::GzipReader.new(StringIO.new(response.body),
                                          encoding: "ASCII-8BIT").read
      response.delete 'content-encoding'
    end
    return response.body
  end
end
