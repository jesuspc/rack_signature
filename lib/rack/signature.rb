require 'signatures/validators/basic'
require 'rack/signature/signable_extractor'
require 'logger'

module Rack
  class Signature
    TIMESTAMP_HEADER = 'HTTP_TIMESTAMP'.freeze
    SIGNATURE_HEADER = 'HTTP_SIGNATURE'.freeze
    SIGNATURE_KEY_HEADER = 'HTTP_SIGNATURE_KEY'.freeze
    SIGNATURE_ENV = 'SIGNATURE'.freeze
    DEFAULT_LOGGER = ::Logger.new('/dev/null')

    attr_reader :app, :validator, :signable_elms, :signable_extractor, :keystore, :logger, :validator_opts

    def initialize(app, opts = {})
      self.app = app
      self.keystore = opts.fetch :keystore, {}
      self.validator_opts = opts.fetch :validator_opts, {}
      self.validator = opts.fetch :validator, default_validator
      self.signable_elms = opts.fetch :signable_elms, [:params, :body, :path, :timestamp]
      self.signable_extractor = opts.fetch :signable_extractor, SignableExtractor
      self.logger = opts.fetch :logger, DEFAULT_LOGGER
    end

    def call(env)
      env[SIGNATURE_ENV] ||= signature_params(env)
      app.call env
    end

    private

    def signature(env)
      env[SIGNATURE_HEADER]
    end

    def timestamp(env)
      env[TIMESTAMP_HEADER]
    end

    def signature_key(env)
      env[SIGNATURE_KEY_HEADER]
    end

    def default_validator
      @default_validator ||= Signatures::Validators::Basic.new({ keystore: keystore }.merge validator_opts)
    end

    def signature_params(env)
      _signature = signature(env)
      _timestamp = timestamp(env)
      _signature_key = signature_key(env)
      _to_validate = signable(env)
      _key_known = !!keystore[_signature_key]
      _valid = validator.call(
        to_validate: _to_validate,
        signature: _signature,
        timestamp: _timestamp,
        key: _signature_key
      )
      _expired = validator.expired_signature?(_timestamp)

      if _signature
        logger.info do
          "[RackSignature] Validating signature #{_signature} with timestamp "\
          "#{_timestamp || '<Not present>'}, key "\
          "#{_signature_key || '<Not present>'} and payload #{_to_validate}. "\
          "Key was #{_key_known ? 'recognised' : 'unrecognised'}. "\
          "Timestamp was #{_expired ? 'expired' : 'not expired'}. "\
          "Validation was #{_valid ? 'successful' : 'unsuccessful'}."
        end
      else
        logger.info do
          "[RackSignature] No signature found, skipping validation..."
        end
      end

      {
        value: _signature,
        present: !_signature.nil?,
        valid: _valid,
        key_known: _key_known,
        expired: _expired
      }
    end

    def signable(env)
      signable_extractor.call Rack::Request.new(env), signable_elms
    end

    private

    attr_writer :app, :validator, :signable_elms, :signable_extractor, :keystore, :logger, :validator_opts
  end
end
