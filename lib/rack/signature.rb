require "rack/signature/version"
require "rack/signature/validator"
require "rack/signature/signable_extractor"

module Rack
  class Signature
    TIMESTAMP_HEADER = 'HTTP_TIMESTAMP'.freeze
    SIGNATURE_HEADER = 'HTTP_SIGNATURE'.freeze

    attr_accessor :validator, :signable_elms, :signable_extractor

    def initialize(app, opts = {})
      @app = app
      self.validator = opts.fetch :validator, Validator
      self.signable_elms = opts.fetch :signable_elms, [:params, :body]
      self.signable_extractor = opts.fetch :signable_extractor, SignableExtractor
    end

    def call(env)
      env['SIGNATURE'] ||= signature_params(env)
      @app.call env
    end

    private

    def signature(env)
      env[SIGNATURE_HEADER]
    end

    def timestamp(env)
      env[TIMESTAMP_HEADER]
    end

    def signature_params(env)
      {
        value: signature(env),
        present: !signature(env).nil?,
        valid: validator.call(signable(env), signature(env), timestamp(env))
      }
    end

    def signable(env)
      signable_extractor.call Rack::Request.new(env), signable_elms
    end
  end
end
