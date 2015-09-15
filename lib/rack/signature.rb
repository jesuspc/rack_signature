require 'signatures/validators/basic'
require 'rack/signature/signable_extractor'

module Rack
  class Signature
    TIMESTAMP_HEADER = 'HTTP_TIMESTAMP'.freeze
    SIGNATURE_HEADER = 'HTTP_SIGNATURE'.freeze
    SIGNATURE_KEY_HEADER = 'HTTP_SIGNATURE_KEY'.freeze
    SIGNATURE_ENV = 'SIGNATURE'.freeze

    attr_reader :app, :validator, :signable_elms, :signable_extractor, :keystore

    def initialize(app, opts = {})
      self.app = app
      self.keystore = opts.fetch :keystore, {}
      self.validator = opts.fetch :validator, default_validator
      self.signable_elms = opts.fetch :signable_elms, [:params, :body, :timestamp]
      self.signable_extractor = opts.fetch :signable_extractor, SignableExtractor
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
      @default_validator ||= Signatures::Validators::Basic.new(keystore: keystore)
    end

    def signature_params(env)
      {
        value: signature(env),
        present: !signature(env).nil?,
        valid: validator.call(
          to_validate: signable(env),
          signature: signature(env),
          timestamp: timestamp(env),
          key: signature_key(env)
        ),
        key_known: !!keystore[signature_key(env)]
      }
    end

    def signable(env)
      signable_extractor.call Rack::Request.new(env), signable_elms
    end

    private

    attr_writer :app, :validator, :signable_elms, :signable_extractor, :keystore
  end
end
