module Rack
  class Signature
    module Validator
      module_function

      def call(to_sign, signature, timestamp, opts = {})
        return nil unless signature
        text_to_sign = to_sign.map(&:to_s).join
        secret = options[:secret] || self.secret

        expected_signature = hmac.hexdigest sha1, secret, text_to_sign

        expected_signature == signature
      end

      def secret(val = nil)
        @secret = val if val
        @secret ||= 'not_secret_at_all'
      end

      def hmac(val = nil)
        @hmac = val if val
        @hmac ||= OpenSSL::HMAC
      end

      def sha1(val = nil)
        @sha1 = val if val
        @sha1 ||= OpenSSL::Digest::SHA1.new
      end
    end
  end
end