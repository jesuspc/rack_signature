module Rack
  class Signature
    class SignableExtractor
      def self.call(request, signable_elms)
        signable_elms.map do |elm|
          extractor_for(elm).call request
        end
      end

      def self.extractor_for(elm)
        extractors[elm]
      end

      def self.extractors
        @extractors ||= {
          params: Params,
          body: Body,
          timestamp: Timestamp,
          path: Path
        }
      end

      Path = lambda do |request|
        request.path
      end

      Params = lambda do |request|
        request.query_string
      end
      # TODO: Support multipart requests by not signing them
      Body = lambda do |request|
        request.body.rewind
        body = request.body.read
        request.body.rewind
        body
      end

      Timestamp = lambda do |request|
        request.env["HTTP_TIMESTAMP"]
      end
    end
  end
end